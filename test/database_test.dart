import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_app/data/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('建库时自动创建 8 个默认分类', () async {
    final categories = await db.getAllCategories();
    expect(categories.length, 8);
    expect(categories.first.name, '餐饮');
    expect(categories.first.icon, '🍜');
    final names = categories.map((c) => c.name).toList();
    expect(names, containsAll(['餐饮', '交通', '购物', '娱乐', '居住', '医疗', '教育', '其他']));
  });

  test('插入记录并读取，字段完整', () async {
    final id = await db.insertRecord(
      RecordsCompanion.insert(
        amount: 45.5,
        categoryId: 1,
        recordDate: DateTime(2026, 10, 17),
        note: const drift.Value('午餐'),
      ),
    );
    expect(id, greaterThan(0));

    final records = await db.getAllRecords();
    expect(records.length, 1);
    final r = records.first;
    expect(r.amount, 45.5);
    expect(r.categoryId, 1);
    expect(r.note, '午餐');
    expect(r.recordDate, DateTime(2026, 10, 17));
  });

  test('按月份过滤记录（含月末边界）', () async {
    await db.insertRecord(RecordsCompanion.insert(
      amount: 10, categoryId: 1, recordDate: DateTime(2026, 10, 1)));
    await db.insertRecord(RecordsCompanion.insert(
      amount: 20, categoryId: 1, recordDate: DateTime(2026, 10, 31, 23, 59)));
    await db.insertRecord(RecordsCompanion.insert(
      amount: 30, categoryId: 1, recordDate: DateTime(2026, 9, 30)));

    final october = await db.watchRecordsByMonth(DateTime(2026, 10)).first;
    expect(october.length, 2);

    final september = await db.watchRecordsByMonth(DateTime(2026, 9)).first;
    expect(september.length, 1);
  });

  test('月度总支出汇总', () async {
    await db.insertRecord(RecordsCompanion.insert(
      amount: 10, categoryId: 1, recordDate: DateTime(2026, 10, 5)));
    await db.insertRecord(RecordsCompanion.insert(
      amount: 20.5, categoryId: 2, recordDate: DateTime(2026, 10, 6)));
    await db.insertRecord(RecordsCompanion.insert(
      amount: 999, categoryId: 1, recordDate: DateTime(2026, 9, 6)));

    final total = await db.watchTotalSpendingByMonth(DateTime(2026, 10)).first;
    expect(total, closeTo(30.5, 0.001));
  });

  test('分类金额汇总（分组聚合）', () async {
    await db.insertRecord(RecordsCompanion.insert(
      amount: 10, categoryId: 1, recordDate: DateTime(2026, 10, 5)));
    await db.insertRecord(RecordsCompanion.insert(
      amount: 20, categoryId: 1, recordDate: DateTime(2026, 10, 6)));
    await db.insertRecord(RecordsCompanion.insert(
      amount: 7, categoryId: 2, recordDate: DateTime(2026, 10, 7)));

    final map = await db.watchCategorySummariesByMonth(DateTime(2026, 10)).first;
    expect(map[1], closeTo(30, 0.001));
    expect(map[2], closeTo(7, 0.001));
    expect(map.length, 2);
  });

  test('更新记录', () async {
    final recId = await db.insertRecord(RecordsCompanion.insert(
      amount: 10, categoryId: 1, recordDate: DateTime(2026, 10, 5)));
    final rec = (await db.getAllRecords()).first;

    await db.updateRecord(RecordsCompanion(
      id: drift.Value(recId),
      amount: const drift.Value(99),
      categoryId: drift.Value(rec.categoryId),
      recordDate: drift.Value(rec.recordDate),
      note: const drift.Value('修改后'),
      createdAt: drift.Value(rec.createdAt),
      updatedAt: drift.Value(DateTime.now()),
    ));

    final updated = (await db.getAllRecords()).first;
    expect(updated.amount, 99);
    expect(updated.note, '修改后');
  });

  test('删除记录', () async {
    await db.insertRecord(RecordsCompanion.insert(
      amount: 10, categoryId: 1, recordDate: DateTime(2026, 10, 5)));
    final rec = (await db.getAllRecords()).first;

    await db.deleteRecord(rec.id);
    expect(await db.getAllRecords(), isEmpty);
  });
}
