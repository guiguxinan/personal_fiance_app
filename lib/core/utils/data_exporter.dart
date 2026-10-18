import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../data/database/app_database.dart';

/// V3.1 (M1)：导出 CSV / JSON 备份
class DataExporter {
  final AppDatabase database;

  DataExporter(this.database);

  /// M1a：导出全部记录为 CSV（UTF-8 BOM，Excel/WPS 中文不乱码）
  /// 列：类型,金额,分类名称,日期,备注,创建时间,更新时间
  /// 无记录时抛 [EmptyExportException]（UI 捕获后展示"暂无记录可导出"）。
  Future<File> exportToCsv() async {
    final records = await database.getAllRecords();
    if (records.isEmpty) {
      throw const EmptyExportException();
    }
    final categories = await database.getAllCategories();
    final byId = {for (final c in categories) c.id: c};

    final buf = StringBuffer();
    // UTF-8 BOM 头（Excel 识别中文用）
    buf.write('﻿');
    buf.write('类型,金额,分类名称,日期,备注,创建时间,更新时间\r\n');
    for (final r in records) {
      final cat = byId[r.categoryId];
      buf
        ..write(_csvField(r.type == 'expense' ? '支出' : '收入'))
        ..write(',')
        ..write(r.amount.toStringAsFixed(2))
        ..write(',')
        ..write(_csvField(cat?.name ?? '未知'))
        ..write(',')
        ..write(_csvField(_formatDate(r.recordDate)))
        ..write(',')
        ..write(_csvField(r.note ?? ''))
        ..write(',')
        ..write(_csvField(r.createdAt.toIso8601String()))
        ..write(',')
        ..write(_csvField(r.updatedAt.toIso8601String()))
        ..write('\r\n');
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/轻记_收支记录_${_dateStamp()}.csv');
    await file.writeAsString(buf.toString());
    return file;
  }

  /// M1b：导出 JSON 完整备份（记录 + 分类）。
  /// V3.1：version=2，含 type/color/isHidden；suffix 用于文件名后缀。
  Future<File> exportToJson({String suffix = '备份'}) async {
    final categories = await database.getAllCategories();
    final records = await database.getAllRecords();

    final exportData = {
      'version': 2,
      'exportDate': DateTime.now().toIso8601String(),
      'categories': categories.map((c) => {
            'id': c.id,
            'name': c.name,
            'icon': c.icon,
            'isDefault': c.isDefault,
            'type': c.type,
            'color': c.color,
            'isHidden': c.isHidden,
          }).toList(),
      'records': records.map((r) => {
            'id': r.id,
            'amount': r.amount,
            'categoryId': r.categoryId,
            'recordDate': r.recordDate.toIso8601String(),
            'note': r.note,
            'createdAt': r.createdAt.toIso8601String(),
            'updatedAt': r.updatedAt.toIso8601String(),
            'type': r.type,
          }).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/轻记_${suffix}_${_dateStamp()}.json');
    await file.writeAsString(jsonString);
    return file;
  }

  // RFC 4180 转义：含 `,` `"` `\n` 的字段用 `"..."` 包裹且 `"` → `""`
  String _csvField(String v) {
    final needsQuote = v.contains(',') ||
        v.contains('"') ||
        v.contains('\n') ||
        v.contains('\r');
    if (!needsQuote) return v;
    return '"${v.replaceAll('"', '""')}"';
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _dateStamp() {
    final d = DateTime.now();
    return '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
  }
}

class EmptyExportException implements Exception {
  const EmptyExportException();
}
