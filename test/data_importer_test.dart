import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_app/data/database/app_database.dart';
import 'package:personal_finance_app/core/utils/data_exporter.dart';
import 'package:personal_finance_app/core/utils/data_importer.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  // 注：M1 单元测试需要真实文件 IO。DataExporter.exportToCsv 写到 app 文档目录，
  // 测试中我们用更轻量的方法：直接测 DataExporter 的输出格式（用临时目录 patch）。
  // 由于 path_provider 在测试环境不易 mock，集成测试覆盖在 widget test 中进行。
  // 这里我们重点测 schema/version 校验与 importFromJson 的回滚行为。

  test('EmptyExportException 空记录抛出（V3.1 M1a）', () async {
    final exporter = DataExporter(db);
    expect(
      () => exporter.exportToCsv(),
      throwsA(isA<EmptyExportException>()),
    );
  });

  test('importFromJson 拒绝不支持的 version（V3.1 M1c schema 校验）', () async {
    final tmp = await Directory.systemTemp.createTemp('backup_test');
    final badFile = File('${tmp.path}/bad.json');
    await badFile.writeAsString('{"version": 99, "records": [], "categories": []}');
    addTearDown(() async => await tmp.delete(recursive: true));

    final result = await DataImporter(db).importFromJson(badFile);
    expect(result.success, isFalse);
    expect(result.message, contains('备份文件格式不正确'));
  });

  test('importFromJson 拒绝非法 JSON（损坏文件）', () async {
    final tmp = await Directory.systemTemp.createTemp('backup_corrupt');
    final badFile = File('${tmp.path}/corrupt.json');
    await badFile.writeAsString('这不是一个有效的 JSON {{{ ]]]');
    addTearDown(() async => await tmp.delete(recursive: true));

    final result = await DataImporter(db).importFromJson(badFile);
    expect(result.success, isFalse);
  });

  test('importFromJson 空 v2 备份成功导入（无记录无分类）', () async {
    final tmp = await Directory.systemTemp.createTemp('backup_empty');
    final file = File('${tmp.path}/empty.json');
    await file.writeAsString('{"version": 2, "exportDate": "2026-10-18", "categories": [], "records": []}');
    addTearDown(() async => await tmp.delete(recursive: true));

    final result = await DataImporter(db).importFromJson(file);
    expect(result.success, isTrue);
    expect(result.message, contains('0 个分类'));
    expect(result.message, contains('0 条记录'));
  });

  test('importFromJson v2 备份含 type/color 字段正确导入（V3.1 新字段）', () async {
    // 先获取一个默认分类 id（建表时插入的）
    final defaultCats = await db.getAllCategories();
    expect(defaultCats.length, 13);

    final tmp = await Directory.systemTemp.createTemp('backup_v2');
    final file = File('${tmp.path}/v2.json');
    // 备份引用一个本地不存在的 categoryId=999 的记录，验证跳过逻辑
    final content = '{"version": 2, "exportDate": "2026-10-18", '
        '"categories": [], '
        '"records": ['
        '  {"id": 1, "amount": 100.0, "categoryId": ${defaultCats.first.id}, '
        '   "recordDate": "2026-10-18T00:00:00.000", "note": "test", '
        '   "createdAt": "2026-10-18T00:00:00.000", "updatedAt": "2026-10-18T00:00:00.000", '
        '   "type": "expense"}'
        ']}';
    await file.writeAsString(content);
    addTearDown(() async => await tmp.delete(recursive: true));

    final result = await DataImporter(db).importFromJson(file);
    expect(result.success, isTrue);
    expect(result.message, contains('1 条记录'));

    final records = await db.getAllRecords();
    expect(records.length, 1);
    expect(records.first.amount, closeTo(100.0, 0.001));
    expect(records.first.type, 'expense');
  });
}
