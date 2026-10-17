import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../data/database/app_database.dart';

class DataExporter {
  final AppDatabase database;

  DataExporter(this.database);

  Future<File> exportToJson() async {
    final categories = await database.getAllCategories();
    final records = await database.getAllRecords();

    final exportData = {
      'version': 1,
      'exportDate': DateTime.now().toIso8601String(),
      'categories': categories.map((c) => {
        'id': c.id,
        'name': c.name,
        'icon': c.icon,
        'isDefault': c.isDefault,
      }).toList(),
      'records': records.map((r) => {
        'id': r.id,
        'amount': r.amount,
        'categoryId': r.categoryId,
        'recordDate': r.recordDate.toIso8601String(),
        'note': r.note,
        'createdAt': r.createdAt.toIso8601String(),
        'updatedAt': r.updatedAt.toIso8601String(),
      }).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

    // Save to downloads directory
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/personal_finance_backup_$timestamp.json');
    await file.writeAsString(jsonString);

    return file;
  }
}
