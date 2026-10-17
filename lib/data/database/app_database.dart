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
  BoolColumn get isDefault => boolean().withDefault(const Constant(true))();
}

// Records table
class Records extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  DateTimeColumn get recordDate => dateTime()();
  TextColumn get note => text().nullable().withLength(max: 100)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Categories, Records])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // Insert default categories
        await _insertDefaultCategories();
      },
    );
  }

  Future<void> _insertDefaultCategories() async {
    final defaultCategories = [
      CategoriesCompanion.insert(name: '餐饮', icon: '🍜'),
      CategoriesCompanion.insert(name: '交通', icon: '🚗'),
      CategoriesCompanion.insert(name: '购物', icon: '🛒'),
      CategoriesCompanion.insert(name: '娱乐', icon: '🎮'),
      CategoriesCompanion.insert(name: '居住', icon: '🏠'),
      CategoriesCompanion.insert(name: '医疗', icon: '💊'),
      CategoriesCompanion.insert(name: '教育', icon: '📚'),
      CategoriesCompanion.insert(name: '其他', icon: '📌'),
    ];

    for (final category in defaultCategories) {
      await into(categories).insert(category);
    }
  }

  // Category queries
  Future<List<Category>> getAllCategories() => select(categories).get();

  Stream<List<Category>> watchAllCategories() => select(categories).watch();

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

  Future<int> insertRecord(RecordsCompanion record) =>
      into(records).insert(record);

  Future<bool> updateRecord(RecordsCompanion record) =>
      update(records).replace(Record(
        id: record.id.value,
        amount: record.amount.value,
        categoryId: record.categoryId.value,
        recordDate: record.recordDate.value,
        note: record.note.value,
        createdAt: record.createdAt.value,
        updatedAt: DateTime.now(),
      ));

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
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'personal_finance.db'));
    return NativeDatabase.createInBackground(file);
  });
}
