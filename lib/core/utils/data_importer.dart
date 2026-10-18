import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' as drift;
import '../../data/database/app_database.dart';

/// V3.1 (M1c)：从 JSON 备份文件恢复数据。
/// V3.3 优化 (O1)：同时恢复 Budgets 预算设置（对齐 PRD §10.1.3）。
class DataImporter {
  final AppDatabase database;

  DataImporter(this.database);

  /// 读取 JSON 备份并以事务方式恢复。
  /// - 兼容 v1/v2（无 Budgets 字段，跳过预算恢复）
  /// - 兼容 v3（含 Budgets 字段）
  /// - 拒绝 version != 1/2/3（"备份文件格式不正确"）
  /// - 跳过引用本地不存在 categoryId 的记录（避免外键失败抛掉整个事务）
  Future<ImportResult> importFromJson(File file) async {
    try {
      final raw = await file.readAsString();
      final data = json.decode(raw) as Map<String, dynamic>;

      final version = data['version'] as int?;
      if (version != null && version != 1 && version != 2 && version != 3) {
        return ImportResult(success: false, message: '备份文件格式不正确，无法恢复');
      }
      if (data['records'] is! List && data['categories'] is! List) {
        return ImportResult(success: false, message: '备份文件格式不正确，无法恢复');
      }

      final categoriesList = (data['categories'] as List<dynamic>?) ?? [];
      final recordsList = (data['records'] as List<dynamic>?) ?? [];
      // V3.3 (O1)：v3+ 才有 budgets 字段
      final budgetsList = (data['budgets'] as List<dynamic>?) ?? [];

      int categoriesImported = 0;
      int recordsImported = 0;
      int budgetsImported = 0;

      await database.transaction(() async {
        // 1) 分类：默认按 name+type 去重；自定义按 name 去重
        final existing = await database.getAllCategories();
        for (final c in categoriesList) {
          final name = c['name'] as String;
          final type = (c['type'] as String?) ?? 'expense';
          final icon = c['icon'] as String;
          final color = (c['color'] as String?) ?? '#A89AA0';
          final isDefault = c['isDefault'] as bool? ?? true;

          final exists = isDefault
              ? existing.any((x) => x.name == name && x.type == type)
              : existing.any((x) => x.name == name);
          if (!exists) {
            await database.insertCategory(
              name,
              icon,
              type: type,
              color: color,
            );
            categoriesImported++;
          }
        }

        // 2) 记录：跳过引用本地不存在 categoryId 的记录
        for (final r in recordsList) {
          final catId = r['categoryId'] as int;
          final cat = await database.getCategoryById(catId);
          if (cat == null) continue;
          await database.insertRecord(RecordsCompanion.insert(
            amount: (r['amount'] as num).toDouble(),
            categoryId: catId,
            recordDate: DateTime.parse(r['recordDate'] as String),
            note: drift.Value(r['note'] as String?),
            type: drift.Value((r['type'] as String?) ?? 'expense'),
          ));
          recordsImported++;
        }

        // 3) V3.3 (O1)：预算按月 upsert
        for (final b in budgetsList) {
          final monthKey = b['month'] as String; // "YYYY-MM"
          final amount = (b['amount'] as num).toDouble();
          final enabled = b['enabled'] as bool? ?? false;
          // monthKey → DateTime
          final parts = monthKey.split('-');
          if (parts.length != 2) continue;
          final year = int.tryParse(parts[0]);
          final month = int.tryParse(parts[1]);
          if (year == null || month == null) continue;
          await database.upsertMonthlyBudget(
            month: DateTime(year, month, 1),
            amount: amount,
            enabled: enabled,
          );
          budgetsImported++;
        }
      });

      return ImportResult(
        success: true,
        message: '导入成功：$categoriesImported 个分类，$recordsImported 条记录，$budgetsImported 条预算',
      );
    } catch (e) {
      return ImportResult(success: false, message: '导入失败：$e');
    }
  }
}

class ImportResult {
  final bool success;
  final String message;

  ImportResult({required this.success, required this.message});
}
