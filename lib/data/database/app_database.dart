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
  int get schemaVersion => 3;

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
      },
    );
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
      // Expense categories
      CategoriesCompanion.insert(name: '餐饮', icon: '🍜', type: const Value('expense'), color: const Value('#E88BA3')),
      CategoriesCompanion.insert(name: '交通', icon: '🚗', type: const Value('expense'), color: const Value('#E8C4A0')),
      CategoriesCompanion.insert(name: '购物', icon: '🛒', type: const Value('expense'), color: const Value('#F2B8C8')),
      CategoriesCompanion.insert(name: '娱乐', icon: '🎮', type: const Value('expense'), color: const Value('#D47B95')),
      CategoriesCompanion.insert(name: '居住', icon: '🏠', type: const Value('expense'), color: const Value('#F7D4DE')),
      CategoriesCompanion.insert(name: '医疗', icon: '💊', type: const Value('expense'), color: const Value('#C96B85')),
      CategoriesCompanion.insert(name: '教育', icon: '📚', type: const Value('expense'), color: const Value('#B85A75')),
      CategoriesCompanion.insert(name: '其他', icon: '📌', type: const Value('expense'), color: const Value('#A89AA0')),
      // Income categories
      CategoriesCompanion.insert(name: '工资', icon: '💼', type: const Value('income'), color: const Value('#5BB892')),
      CategoriesCompanion.insert(name: '奖金', icon: '🎁', type: const Value('income'), color: const Value('#7FD0AE')),
      CategoriesCompanion.insert(name: '理财', icon: '📈', type: const Value('income'), color: const Value('#3D9472')),
      CategoriesCompanion.insert(name: '兼职', icon: '💪', type: const Value('income'), color: const Value('#A8DCC2')),
      CategoriesCompanion.insert(name: '其他', icon: '📌', type: const Value('income'), color: const Value('#E8C4A0')),
    ];

    for (final category in defaultCategories) {
      await into(categories).insert(category);
    }
  }

  // Category queries
  Future<List<Category>> getAllCategories() => select(categories).get();

  Stream<List<Category>> watchAllCategories() => select(categories).watch();

  Future<Category?> getCategoryById(int id) =>
      (select(categories)..where((c) => c.id.equals(id))).getSingleOrNull();

  // Get categories filtered by type ('expense' or 'income')
  Future<List<Category>> getCategoriesByType(String type) =>
      (select(categories)..where((c) => c.type.equals(type))).get();

  // Watch categories filtered by type
  Stream<List<Category>> watchCategoriesByType(String type) =>
      (select(categories)..where((c) => c.type.equals(type))).watch();

  Future<int> insertCategory(String name, String icon, {String type = 'expense', String color = '#A89AA0'}) =>
      into(categories).insert(CategoriesCompanion.insert(
        name: name,
        icon: icon,
        type: Value(type),
        color: Value(color),
        isDefault: const Value(false),
      ));

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
    ));
  }

  Future<int> deleteCategory(int id) =>
      (delete(categories)..where((c) => c.id.equals(id))).go();

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
             c.color AS color, c.is_default AS is_default, c.is_hidden AS is_hidden
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
