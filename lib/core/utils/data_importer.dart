import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' as drift;
import '../../data/database/app_database.dart';

/// V3.1 (M1c)：从 JSON 备份文件恢复数据。
class DataImporter {
  final AppDatabase database;

  DataImporter(this.database);

  /// 读取 JSON 备份并以事务方式恢复。
  /// - 兼容旧版 version=1（不写入 type/color/isHidden 字段，保留本地默认）。
  /// - 拒绝 version != 1/2（"备份文件格式不正确"）。
  /// - 跳过引用本地不存在 categoryId 的记录（避免外键失败抛掉整个事务）。
  Future<ImportResult> importFromJson(File file) async {
    try {
      final raw = await file.readAsString();
      final data = json.decode(raw) as Map<String, dynamic>;

      final version = data['version'] as int?;
      if (version != null && version != 1 && version != 2) {
        return ImportResult(success: false, message: '备份文件格式不正确，无法恢复');
      }
      if (data['records'] is! List && data['categories'] is! List) {
        return ImportResult(success: false, message: '备份文件格式不正确，无法恢复');
      }

      final categoriesList = (data['categories'] as List<dynamic>?) ?? [];
      final recordsList = (data['records'] as List<dynamic>?) ?? [];

      int categoriesImported = 0;
      int recordsImported = 0;

      await database.transaction(() async {
        // 1) 分类：默认按 name+type 去重；自定义按 name 去重
        final existing = await database.getAllCategories();
        for (final c in categoriesList) {
          final name = c['name'] as String;
          final type = (c['type'] as String?) ?? 'expense';
          final icon = c['icon'] as String;
          final color = (c['color'] as String?) ?? '#A89AA0';
          final isDefault = c['isDefault'] as bool? ?? true;

          // 默认分类按 (name, type) 匹配；自定义按 name 匹配
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
      });

      return ImportResult(
        success: true,
        message: '导入成功：$categoriesImported 个分类，$recordsImported 条记录',
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
