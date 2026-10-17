import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:personal_finance_app/data/database/app_database.dart';

class DataImporter {
  final AppDatabase database;

  DataImporter(this.database);

  Future<ImportResult> importFromJson(File file) async {
    try {
      final jsonString = await file.readAsString();
      final data = json.decode(jsonString) as Map<String, dynamic>;

      final version = data['version'] as int?;
      if (version != 1) {
        return ImportResult(success: false, message: '不支持的数据版本: $version');
      }

      int categoriesImported = 0;
      int recordsImported = 0;

      // Import categories (skip defaults - they already exist)
      final categoriesList = data['categories'] as List<dynamic>?;
      if (categoriesList != null) {
        for (final c in categoriesList) {
          final isDefault = c['isDefault'] as bool? ?? true;
          if (!isDefault) {
            // Check if category already exists
            final existing = await database.getCategoryById(c['id'] as int);
            if (existing == null) {
              await database.insertCategory(
                c['name'] as String,
                c['icon'] as String,
              );
              categoriesImported++;
            }
          }
        }
      }

      // Import records
      final recordsList = data['records'] as List<dynamic>?;
      if (recordsList != null) {
        for (final r in recordsList) {
          try {
            await database.insertRecord(RecordsCompanion.insert(
              amount: (r['amount'] as num).toDouble(),
              categoryId: r['categoryId'] as int,
              recordDate: DateTime.parse(r['recordDate'] as String),
              note: drift.Value(r['note'] as String?),
            ));
            recordsImported++;
          } catch (_) {
            // Skip invalid records
          }
        }
      }

      return ImportResult(
        success: true,
        message: '导入成功：$categoriesImported 个分类，$recordsImported 条记录',
      );
    } catch (e) {
      return ImportResult(success: false, message: '导入失败: $e');
    }
  }
}

class ImportResult {
  final bool success;
  final String message;

  ImportResult({required this.success, required this.message});
}
