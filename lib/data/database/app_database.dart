import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// Categories table
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 20)();
  TextColumn get icon => text().withLength(min: 1, max: 10)();
  TextColumn get type => text().withDefault(const Constant('expense'))(); // 'expense' or 'income'
  TextColumn get color => text().withDefault(const Constant('#A89AA0'))(); // HEX color string
  BoolColumn get isDefault => boolean().withDefault(const Constant(true))();
  // V3.1 (M1/M6 配合)：隐藏分类不出现在常规分类区与统计图例，但可被「最近使用」快捷记账选中
  BoolColumn get isHidden => boolean().withDefault(const Constant(false))();
  // V3.3 (B4)：分类排序（同类型内升序展示；新增时取同类型 max+1）
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

// Records table
class Records extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  DateTimeColumn get recordDate => dateTime()();
  TextColumn get note => text().nullable().withLength(max: 100)();
  TextColumn get type => text().withDefault(const Constant('expense'))(); // 'expense' or 'income'
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// V3.1 (M4b)：月度预算表（按月独立预算金额 + 启用开关）
class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get month => text().withLength(min: 7, max: 7)(); // "YYYY-MM"
  RealColumn get amount => real().withDefault(const Constant(0))();
  BoolColumn get enabled => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Categories, Records, Budgets])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // Insert default categories
        await _insertDefaultCategories();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Add type and color columns to Categories table
          await m.addColumn(categories, categories.type);
          await m.addColumn(categories, categories.color);
          // Add type column to Records table
          await m.addColumn(records, records.type);
          // Update existing records to have type='expense'
          await (update(records)..where((_) => const Constant(true))).write(
            const RecordsCompanion(type: Value('expense')),
          );
          // Update existing categories with type='expense' and assign colors
          await _migrateExistingCategories();
        }
        // V3.1：新增 Category.isHidden 列 + 新建 Budgets 表
        if (from < 3) {
          await m.addColumn(categories, categories.isHidden);
          await m.createTable(budgets);
        }
        // V3.3 (B4)：新增 Category.sortOrder 列，并按当前 id 顺序赋值
        if (from < 4) {
          await m.addColumn(categories, categories.sortOrder);
          await _assignDefaultSortOrder();
        }
      },
    );
  }

  /// V3.3 (B4)：迁移时按 id 顺序给现有分类赋 sortOrder（0,1,2,...）
  Future<void> _assignDefaultSortOrder() async {
    final all = await getAllCategories();
    for (var i = 0; i < all.length; i++) {
      await (update(categories)..where((c) => c.id.equals(all[i].id))).write(
        CategoriesCompanion(sortOrder: Value(i)),
      );
    }
  }

  Future<void> _migrateExistingCategories() async {
    // Map of category name to color
    final categoryColors = {
      '餐饮': '#E88BA3',
      '交通': '#E8C4A0',
      '购物': '#F2B8C8',
      '娱乐': '#D47B95',
      '居住': '#F7D4DE',
      '医疗': '#C96B85',
      '教育': '#B85A75',
      '其他': '#A89AA0',
    };

    final allCategories = await getAllCategories();
    for (final category in allCategories) {
      final color = categoryColors[category.name] ?? '#A89AA0';
      await (update(categories)..where((c) => c.id.equals(category.id))).write(
        CategoriesCompanion(
          type: const Value('expense'),
          color: Value(color),
        ),
      );
    }
  }

  Future<void> _insertDefaultCategories() async {
    final defaultCategories = [
      // Expense categories（sortOrder 0..7）
      CategoriesCompanion.insert(name: '餐饮', icon: '🍜', type: const Value('expense'), color: const Value('#E88BA3'), sortOrder: const Value(0)),
      CategoriesCompanion.insert(name: '交通', icon: '🚗', type: const Value('expense'), color: const Value('#E8C4A0'), sortOrder: const Value(1)),
      CategoriesCompanion.insert(name: '购物', icon: '🛒', type: const Value('expense'), color: const Value('#F2B8C8'), sortOrder: const Value(2)),
      CategoriesCompanion.insert(name: '娱乐', icon: '🎮', type: const Value('expense'), color: const Value('#D47B95'), sortOrder: const Value(3)),
      CategoriesCompanion.insert(name: '居住', icon: '🏠', type: const Value('expense'), color: const Value('#F7D4DE'), sortOrder: const Value(4)),
      CategoriesCompanion.insert(name: '医疗', icon: '💊', type: const Value('expense'), color: const Value('#C96B85'), sortOrder: const Value(5)),
      CategoriesCompanion.insert(name: '教育', icon: '📚', type: const Value('expense'), color: const Value('#B85A75'), sortOrder: const Value(6)),
      CategoriesCompanion.insert(name: '其他', icon: '📌', type: const Value('expense'), color: const Value('#A89AA0'), sortOrder: const Value(7)),
      // Income categories（sortOrder 0..4）
      CategoriesCompanion.insert(name: '工资', icon: '💼', type: const Value('income'), color: const Value('#5BB892'), sortOrder: const Value(0)),
      CategoriesCompanion.insert(name: '奖金', icon: '🎁', type: const Value('income'), color: const Value('#7FD0AE'), sortOrder: const Value(1)),
      CategoriesCompanion.insert(name: '理财', icon: '📈', type: const Value('income'), color: const Value('#3D9472'), sortOrder: const Value(2)),
      CategoriesCompanion.insert(name: '兼职', icon: '💪', type: const Value('income'), color: const Value('#A8DCC2'), sortOrder: const Value(3)),
      CategoriesCompanion.insert(name: '其他', icon: '📌', type: const Value('income'), color: const Value('#E8C4A0'), sortOrder: const Value(4)),
    ];

    for (final category in defaultCategories) {
      await into(categories).insert(category);
    }
  }

  // Category queries（V3.3 B4：统一按 sortOrder 升序、id 升序展示）
  Future<List<Category>> getAllCategories() => (select(categories)
        ..orderBy([
          (c) => OrderingTerm.asc(c.sortOrder),
          (c) => OrderingTerm.asc(c.id),
        ]))
      .get();

  Stream<List<Category>> watchAllCategories() => (select(categories)
        ..orderBy([
          (c) => OrderingTerm.asc(c.sortOrder),
          (c) => OrderingTerm.asc(c.id),
        ]))
      .watch();

  Future<Category?> getCategoryById(int id) =>
      (select(categories)..where((c) => c.id.equals(id))).getSingleOrNull();

  // Get categories filtered by type ('expense' or 'income')
  Future<List<Category>> getCategoriesByType(String type) => (select(categories)
        ..where((c) => c.type.equals(type))
        ..orderBy([
          (c) => OrderingTerm.asc(c.sortOrder),
          (c) => OrderingTerm.asc(c.id),
        ]))
      .get();

  // Watch categories filtered by type
  Stream<List<Category>> watchCategoriesByType(String type) =>
      (select(categories)
            ..where((c) => c.type.equals(type))
            ..orderBy([
              (c) => OrderingTerm.asc(c.sortOrder),
              (c) => OrderingTerm.asc(c.id),
            ]))
          .watch();

  // V3.3 (B4)：新增分类 sortOrder 取同类型当前最大值 + 1
  Future<int> insertCategory(String name, String icon, {String type = 'expense', String color = '#A89AA0'}) async {
    final existing = await getCategoriesByType(type);
    final maxOrder = existing.fold<int>(0, (max, c) => c.sortOrder > max ? c.sortOrder : max);
    return into(categories).insert(CategoriesCompanion.insert(
      name: name,
      icon: icon,
      type: Value(type),
      color: Value(color),
      isDefault: const Value(false),
      sortOrder: Value(maxOrder + 1),
    ));
  }

  Future<bool> updateCategory(int id, String name, String icon, {String? type, String? color}) async {
    final category = await getCategoryById(id);
    if (category == null) return false;
    return update(categories).replace(Category(
      id: category.id,
      name: name,
      icon: icon,
      type: type ?? category.type,
      color: color ?? category.color,
      isDefault: category.isDefault,
      isHidden: category.isHidden,
      sortOrder: category.sortOrder, // V3.3 B4：保留排序
    ));
  }

  Future<int> deleteCategory(int id) =>
      (delete(categories)..where((c) => c.id.equals(id))).go();

  /// V3.3 优化 (O3)：设置分类隐藏状态（PRD §10.6.4）
  Future<void> setCategoryHidden(int id, bool hidden) async {
    await (update(categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(isHidden: Value(hidden)),
    );
  }

  // ── V3.3 (B4) 分类排序：与同类型相邻分类交换 sortOrder ──────

  /// 上移：与该分类同类型的上一个（sortOrder 更小）交换
  Future<void> moveCategoryUp(int id) async {
    final category = await getCategoryById(id);
    if (category == null) return;
    final siblings = await getCategoriesByType(category.type);
    siblings.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final index = siblings.indexWhere((c) => c.id == id);
    if (index <= 0) return; // 已是第一个
    final prev = siblings[index - 1];
    await _swapSortOrder(category.id, prev.id);
  }

  /// 下移：与该分类同类型的下一个（sortOrder 更大）交换
  Future<void> moveCategoryDown(int id) async {
    final category = await getCategoryById(id);
    if (category == null) return;
    final siblings = await getCategoriesByType(category.type);
    siblings.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final index = siblings.indexWhere((c) => c.id == id);
    if (index < 0 || index >= siblings.length - 1) return; // 已是最后一个
    final next = siblings[index + 1];
    await _swapSortOrder(category.id, next.id);
  }

  Future<void> _swapSortOrder(int aId, int bId) async {
    final a = await getCategoryById(aId);
    final b = await getCategoryById(bId);
    if (a == null || b == null) return;
    await (update(categories)..where((c) => c.id.equals(aId))).write(
      CategoriesCompanion(sortOrder: Value(b.sortOrder)),
    );
    await (update(categories)..where((c) => c.id.equals(bId))).write(
      CategoriesCompanion(sortOrder: Value(a.sortOrder)),
    );
  }

  // Record queries
  Future<List<Record>> getAllRecords() => select(records).get();

  Stream<List<Record>> watchAllRecords() => select(records).watch();

  Stream<List<Record>> watchRecordsByMonth(DateTime month) {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    return (select(records)
          ..where((r) => r.recordDate.isBetweenValues(startOfMonth, endOfMonth))
          ..orderBy([(r) => OrderingTerm.desc(r.recordDate)]))
        .watch();
  }

  // Get records for month filtered by type
  Future<List<Record>> getRecordsByMonthAndType(DateTime month, String type) {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    return (select(records)
          ..where((r) => r.recordDate.isBetweenValues(startOfMonth, endOfMonth) & r.type.equals(type))
          ..orderBy([(r) => OrderingTerm.desc(r.recordDate)]))
        .get();
  }

  // Watch records for month filtered by type
  Stream<List<Record>> watchRecordsByMonthAndType(DateTime month, String type) {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    return (select(records)
          ..where((r) => r.recordDate.isBetweenValues(startOfMonth, endOfMonth) & r.type.equals(type))
          ..orderBy([(r) => OrderingTerm.desc(r.recordDate)]))
        .watch();
  }

  // V3.3 (B3)：统计页分类明细展开——按范围+类型+分类查近期记录（日期倒序，限 N 条）
  Future<List<Record>> getRecordsByRangeAndCategory(
    DateTime start,
    DateTime end,
    String type,
    int categoryId, {
    int limit = 5,
  }) {
    return (select(records)
          ..where((r) =>
              r.recordDate.isBetweenValues(start, end) &
              r.type.equals(type) &
              r.categoryId.equals(categoryId))
          ..orderBy([(r) => OrderingTerm.desc(r.recordDate)])
          ..limit(limit))
        .get();
  }

  Future<int> insertRecord(RecordsCompanion record) =>
      into(records).insert(record);

  Future<bool> updateRecord(RecordsCompanion record) async {
    // 只更新传入的非 absent 字段；主键不参与 SET（drift 2.35 下
    // replace(Record(...)) 对未提供的列（Value.absent）会抛 Null cast）
    final count = await (update(records)..where((r) => r.id.equals(record.id.value)))
        .write(record.copyWith(id: const Value.absent()));
    return count > 0;
  }

  Future<int> deleteRecord(int id) =>
      (delete(records)..where((r) => r.id.equals(id))).go();

  // Aggregation queries
  Stream<double> watchTotalSpendingByMonth(DateTime month) {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final query = selectOnly(records)
      ..addColumns([records.amount.sum()])
      ..where(records.recordDate.isBetweenValues(startOfMonth, endOfMonth));

    return query.watchSingle().map((row) => row.read(records.amount.sum()) ?? 0.0);
  }

  // Sum amount for month and type
  Future<double> getTotalByMonthAndType(DateTime month, String type) {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final query = selectOnly(records)
      ..addColumns([records.amount.sum()])
      ..where(records.recordDate.isBetweenValues(startOfMonth, endOfMonth) & records.type.equals(type));

    return query.getSingle().then((row) => row.read(records.amount.sum()) ?? 0.0);
  }

  // Stream sum amount for month and type
  Stream<double> watchTotalByMonthAndType(DateTime month, String type) {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final query = selectOnly(records)
      ..addColumns([records.amount.sum()])
      ..where(records.recordDate.isBetweenValues(startOfMonth, endOfMonth) & records.type.equals(type));

    return query.watchSingle().map((row) => row.read(records.amount.sum()) ?? 0.0);
  }

  /// S1 修复：按任意起止日期范围聚合（年/月/日粒度共用）
  Stream<double> watchTotalByRange(DateTime start, DateTime end, String type) {
    final query = selectOnly(records)
      ..addColumns([records.amount.sum()])
      ..where(records.recordDate.isBetweenValues(start, end) & records.type.equals(type));

    return query.watchSingle().map((row) => row.read(records.amount.sum()) ?? 0.0);
  }

  Stream<Map<int, double>> watchCategorySummariesByMonth(DateTime month) {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final query = selectOnly(records)
      ..addColumns([records.categoryId, records.amount.sum()])
      ..where(records.recordDate.isBetweenValues(startOfMonth, endOfMonth))
      ..groupBy([records.categoryId]);

    return query.watch().map((rows) {
      final map = <int, double>{};
      for (final row in rows) {
        final categoryId = row.read(records.categoryId);
        final sum = row.read(records.amount.sum()) ?? 0.0;
        if (categoryId != null) {
          map[categoryId] = sum;
        }
      }
      return map;
    });
  }

  // Category breakdown for specific type
  Future<Map<int, double>> getCategorySummariesByMonthAndType(DateTime month, String type) {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final query = selectOnly(records)
      ..addColumns([records.categoryId, records.amount.sum()])
      ..where(records.recordDate.isBetweenValues(startOfMonth, endOfMonth) & records.type.equals(type))
      ..groupBy([records.categoryId]);

    return query.get().then((rows) {
      final map = <int, double>{};
      for (final row in rows) {
        final categoryId = row.read(records.categoryId);
        final sum = row.read(records.amount.sum()) ?? 0.0;
        if (categoryId != null) {
          map[categoryId] = sum;
        }
      }
      return map;
    });
  }

  // Stream category breakdown for specific type
  Stream<Map<int, double>> watchCategorySummariesByMonthAndType(DateTime month, String type) {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final query = selectOnly(records)
      ..addColumns([records.categoryId, records.amount.sum()])
      ..where(records.recordDate.isBetweenValues(startOfMonth, endOfMonth) & records.type.equals(type))
      ..groupBy([records.categoryId]);

    return query.watch().map((rows) {
      final map = <int, double>{};
      for (final row in rows) {
        final categoryId = row.read(records.categoryId);
        final sum = row.read(records.amount.sum()) ?? 0.0;
        if (categoryId != null) {
          map[categoryId] = sum;
        }
      }
      return map;
    });
  }

  /// S1 修复：按任意起止日期范围聚合分类明细（年/月/日粒度共用）
  Stream<Map<int, double>> watchCategorySummariesByRange(DateTime start, DateTime end, String type) {
    final query = selectOnly(records)
      ..addColumns([records.categoryId, records.amount.sum()])
      ..where(records.recordDate.isBetweenValues(start, end) & records.type.equals(type))
      ..groupBy([records.categoryId]);

    return query.watch().map((rows) {
      final map = <int, double>{};
      for (final row in rows) {
        final categoryId = row.read(records.categoryId);
        final sum = row.read(records.amount.sum()) ?? 0.0;
        if (categoryId != null) {
          map[categoryId] = sum;
        }
      }
      return map;
    });
  }

  // ── V3.1 (M4b) Budgets CRUD ─────────────────────────────

  /// 按月查询预算（YYYY-MM）
  String _monthKey(DateTime month) =>
      '${month.year}-${month.month.toString().padLeft(2, '0')}';

  Stream<Budget?> watchMonthlyBudget(DateTime month) {
    final monthKey = _monthKey(month);
    return (select(budgets)..where((b) => b.month.equals(monthKey)))
        .watchSingleOrNull();
  }

  /// V3.3 (O1)：一次性查询全量预算（导出 JSON 备份用）
  Future<List<Budget>> getAllBudgets() => select(budgets).get();

  Future<Budget?> getMonthlyBudget(DateTime month) async {
    final monthKey = _monthKey(month);
    return (select(budgets)..where((b) => b.month.equals(monthKey)))
        .getSingleOrNull();
  }

  /// 插入或更新某月预算（按 month 主键）
  Future<void> upsertMonthlyBudget({
    required DateTime month,
    required double amount,
    required bool enabled,
  }) async {
    final monthKey = _monthKey(month);
    final existing = await getMonthlyBudget(month);
    if (existing == null) {
      await into(budgets).insert(BudgetsCompanion.insert(
        month: monthKey,
        amount: Value(amount),
        enabled: Value(enabled),
      ));
    } else {
      await (update(budgets)..where((b) => b.id.equals(existing.id))).write(
        BudgetsCompanion(
          amount: Value(amount),
          enabled: Value(enabled),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  // ── V3.1 (M4a) 月度结余（收入 − 支出） ─────────────────────

  Stream<({double income, double expense})> watchMonthlySurplus(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    final q = selectOnly(records)
      ..addColumns([records.type, records.amount.sum()])
      ..where(records.recordDate.isBetweenValues(start, end))
      ..groupBy([records.type]);
    return q.watch().map((rows) {
      double inc = 0, exp = 0;
      for (final row in rows) {
        final t = row.read(records.type);
        final s = row.read(records.amount.sum()) ?? 0.0;
        if (t == 'income') inc = s;
        if (t == 'expense') exp = s;
      }
      return (income: inc, expense: exp);
    });
  }

  // ── V3.1 (M3a) 最近使用分类（30 天内 Top-N） ──────────────

  /// 按当前收支类型返回近 [days] 天内使用频次 Top [limit] 个分类。
  /// SQL: GROUP BY categoryId ORDER BY COUNT DESC, MAX(recordDate) DESC
  Stream<List<Category>> watchRecentCategoriesByType(
    String type, {
    int days = 30,
    int limit = 3,
  }) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    // record_date 存为 INTEGER（unix 秒），传整型而非字符串
    final cutoffSec = cutoff.millisecondsSinceEpoch ~/ 1000;
    final raw = customSelect(
      '''
      SELECT c.id AS id, c.name AS name, c.icon AS icon, c.type AS type,
             c.color AS color, c.is_default AS is_default, c.is_hidden AS is_hidden,
             c.sort_order AS sort_order
      FROM categories c
      JOIN records r ON r.category_id = c.id
      WHERE r.record_date >= ? AND c.type = ?
      GROUP BY c.id
      ORDER BY COUNT(r.id) DESC, MAX(r.record_date) DESC
      LIMIT ?
      ''',
      variables: [
        Variable.withInt(cutoffSec),
        Variable.withString(type),
        Variable.withInt(limit),
      ],
      readsFrom: {categories, records},
    );
    return raw.watch().map((rows) {
      return rows.map((row) => Category(
            id: row.read<int>('id'),
            name: row.read<String>('name'),
            icon: row.read<String>('icon'),
            type: row.read<String>('type'),
            color: row.read<String>('color'),
            isDefault: row.read<bool>('is_default'),
            isHidden: row.read<bool>('is_hidden'),
            sortOrder: row.read<int>('sort_order'),
          )).toList();
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'personal_finance.db'));
    return NativeDatabase.createInBackground(file);
  });
}
