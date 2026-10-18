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

  test('建库时自动创建 13 个默认分类', () async {
    final categories = await db.getAllCategories();
    expect(categories.length, 13);
    expect(categories.first.name, '餐饮');
    expect(categories.first.icon, '🍜');
    final names = categories.map((c) => c.name).toList();
    expect(names, containsAll(['餐饮', '交通', '购物', '娱乐', '居住', '医疗', '教育', '其他']));
    expect(names, containsAll(['工资', '奖金', '理财', '兼职']));
    final expenseCount = categories.where((c) => c.type == 'expense').length;
    final incomeCount = categories.where((c) => c.type == 'income').length;
    expect(expenseCount, 8);
    expect(incomeCount, 5);
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

  // S1 修复：年粒度范围聚合——新 API watchTotalByRange 应能查到该年所有记录
  test('S1 修复：年粒度范围聚合正确', () async {
    // 跨年数据：2025 1 笔、2026 2 笔
    await db.insertRecord(RecordsCompanion.insert(
      amount: 100, categoryId: 1, recordDate: DateTime(2025, 6, 15), type: const drift.Value('expense')));
    await db.insertRecord(RecordsCompanion.insert(
      amount: 200, categoryId: 1, recordDate: DateTime(2026, 1, 15), type: const drift.Value('expense')));
    await db.insertRecord(RecordsCompanion.insert(
      amount: 300, categoryId: 1, recordDate: DateTime(2026, 12, 31), type: const drift.Value('expense')));

    // 2025 年总额 = 100
    final total2025 = await db.watchTotalByRange(
      DateTime(2025, 1, 1),
      DateTime(2025, 12, 31, 23, 59, 59),
      'expense',
    ).first;
    expect(total2025, closeTo(100, 0.001));

    // 2026 年总额 = 500
    final total2026 = await db.watchTotalByRange(
      DateTime(2026, 1, 1),
      DateTime(2026, 12, 31, 23, 59, 59),
      'expense',
    ).first;
    expect(total2026, closeTo(500, 0.001));

    // 日粒度：2026-01-15 当天 = 200
    final totalDay = await db.watchTotalByRange(
      DateTime(2026, 1, 15),
      DateTime(2026, 1, 15, 23, 59, 59),
      'expense',
    ).first;
    expect(totalDay, closeTo(200, 0.001));
  });

  // S1 修复：年粒度分类明细范围聚合
  test('S1 修复：年粒度分类明细范围聚合正确', () async {
    await db.insertRecord(RecordsCompanion.insert(
      amount: 100, categoryId: 1, recordDate: DateTime(2026, 3, 15), type: const drift.Value('expense')));
    await db.insertRecord(RecordsCompanion.insert(
      amount: 200, categoryId: 2, recordDate: DateTime(2026, 8, 20), type: const drift.Value('expense')));

    final map = await db.watchCategorySummariesByRange(
      DateTime(2026, 1, 1),
      DateTime(2026, 12, 31, 23, 59, 59),
      'expense',
    ).first;
    expect(map[1], closeTo(100, 0.001));
    expect(map[2], closeTo(200, 0.001));
    expect(map.length, 2);
  });

  // M1 修复：编辑模式改日期后 updateRecord 应写入新日期
  test('M1 修复：编辑记录改日期生效', () async {
    final id = await db.insertRecord(RecordsCompanion.insert(
      amount: 10, categoryId: 1, recordDate: DateTime(2026, 10, 5)));
    final rec = (await db.getAllRecords()).first;

    // 编辑改日期为 10/15
    await db.updateRecord(RecordsCompanion(
      id: drift.Value(id),
      amount: drift.Value(rec.amount),
      categoryId: drift.Value(rec.categoryId),
      recordDate: drift.Value(DateTime(2026, 10, 15)),
      note: drift.Value(null),
      type: drift.Value(rec.type),
      createdAt: drift.Value(rec.createdAt),
      updatedAt: drift.Value(DateTime.now()),
    ));

    // 重新读：日期应为 10/15
    final updated = (await db.getAllRecords()).first;
    expect(updated.recordDate, DateTime(2026, 10, 15));
  });

  // ─── V3.1 P0 新增测试 ─────────────────────────────

  test('V3.1 schema v3：默认 Category.isHidden=false', () async {
    final categories = await db.getAllCategories();
    expect(categories, isNotEmpty);
    for (final c in categories) {
      expect(c.isHidden, isFalse);
    }
  });

  test('V3.1 M4b：upsertMonthlyBudget 插入', () async {
    final month = DateTime(2026, 10, 1);
    await db.upsertMonthlyBudget(month: month, amount: 5000, enabled: true);
    final b = await db.getMonthlyBudget(month);
    expect(b, isNotNull);
    expect(b!.amount, closeTo(5000, 0.001));
    expect(b.enabled, isTrue);
    expect(b.month, '2026-10');
  });

  test('V3.1 M4b：upsertMonthlyBudget 更新已存在记录', () async {
    final month = DateTime(2026, 10, 1);
    await db.upsertMonthlyBudget(month: month, amount: 5000, enabled: true);
    await db.upsertMonthlyBudget(month: month, amount: 8000, enabled: false);
    final b = await db.getMonthlyBudget(month);
    expect(b, isNotNull);
    expect(b!.amount, closeTo(8000, 0.001));
    expect(b.enabled, isFalse);
  });

  test('V3.1 M4a：watchMonthlySurplus 收入/支出分项聚合', () async {
    final cats = await db.getAllCategories();
    final exp = cats.firstWhere((c) => c.type == 'expense');
    final inc = cats.firstWhere((c) => c.type == 'income');
    final month = DateTime(2026, 10, 1);
    await db.insertRecord(RecordsCompanion.insert(
      amount: 100, categoryId: exp.id, recordDate: DateTime(2026, 10, 5),
      type: const drift.Value('expense')));
    await db.insertRecord(RecordsCompanion.insert(
      amount: 200, categoryId: exp.id, recordDate: DateTime(2026, 10, 6),
      type: const drift.Value('expense')));
    await db.insertRecord(RecordsCompanion.insert(
      amount: 5000, categoryId: inc.id, recordDate: DateTime(2026, 10, 7),
      type: const drift.Value('income')));
    // 跨月噪声
    await db.insertRecord(RecordsCompanion.insert(
      amount: 999, categoryId: exp.id, recordDate: DateTime(2026, 9, 30),
      type: const drift.Value('expense')));

    final stats = await db.watchMonthlySurplus(month).first;
    expect(stats.income, closeTo(5000, 0.001));
    expect(stats.expense, closeTo(300, 0.001));
  });

  test('V3.1 M3a：watchRecentCategoriesByType 按 30 天频次 Top 排序', () async {
    final cats = await db.getAllCategories();
    final cat1 = cats.firstWhere((c) => c.name == '餐饮');
    final cat2 = cats.firstWhere((c) => c.name == '交通');
    final now = DateTime.now();

    // cat1 (餐饮) 3 次，cat2 (交通) 5 次 → cat2 排第一
    for (int i = 0; i < 3; i++) {
      await db.insertRecord(RecordsCompanion.insert(
        amount: 10, categoryId: cat1.id,
        recordDate: now.subtract(Duration(days: i)),
        type: const drift.Value('expense')));
    }
    for (int i = 0; i < 5; i++) {
      await db.insertRecord(RecordsCompanion.insert(
        amount: 5, categoryId: cat2.id,
        recordDate: now.subtract(Duration(days: i)),
        type: const drift.Value('expense')));
    }

    final recents = await db.watchRecentCategoriesByType('expense', days: 30, limit: 3).first;
    expect(recents.length, 2);
    expect(recents.first.id, cat2.id); // 5 次 > 3 次
    expect(recents.last.id, cat1.id);
  });
}
