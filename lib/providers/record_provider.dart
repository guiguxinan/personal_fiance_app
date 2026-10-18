import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import '../data/models/category_model.dart';
import 'database_provider.dart';

// Selected month provider
final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

// Selected record type provider ('expense' or 'income')
final selectedTypeProvider = StateProvider<String>((ref) => 'expense');

// Records by month
final recordsByMonthProvider = StreamProvider<List<Record>>((ref) async* {
  final databaseAsync = ref.watch(databaseProvider);
  final month = ref.watch(selectedMonthProvider);
  final selectedType = ref.watch(selectedTypeProvider);

  final database = await databaseAsync.when(
    data: (db) => db,
    loading: () => throw Exception('Database loading'),
    error: (e, _) => throw e,
  );

  yield* database.watchRecordsByMonthAndType(month, selectedType);
});

// Categories provider
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final databaseAsync = ref.watch(databaseProvider);
  final database = await databaseAsync.when(
    data: (db) => db,
    loading: () => throw Exception('Database loading'),
    error: (e, _) => throw e,
  );
  return database.getAllCategories();
});

// Category summaries by month
final categorySummariesProvider = StreamProvider<Map<int, double>>((ref) async* {
  final databaseAsync = ref.watch(databaseProvider);
  final month = ref.watch(selectedMonthProvider);
  final selectedType = ref.watch(selectedTypeProvider);

  final database = await databaseAsync.when(
    data: (db) => db,
    loading: () => throw Exception('Database loading'),
    error: (e, _) => throw e,
  );

  yield* database.watchCategorySummariesByMonthAndType(month, selectedType);
});

// Total spending by month
final totalSpendingProvider = StreamProvider<double>((ref) async* {
  final databaseAsync = ref.watch(databaseProvider);
  final month = ref.watch(selectedMonthProvider);
  final selectedType = ref.watch(selectedTypeProvider);

  final database = await databaseAsync.when(
    data: (db) => db,
    loading: () => throw Exception('Database loading'),
    error: (e, _) => throw e,
  );

  yield* database.watchTotalByMonthAndType(month, selectedType);
});

// 上月同类型总额（首页总览卡片环比用）
final prevMonthTotalProvider = StreamProvider<double>((ref) async* {
  final databaseAsync = ref.watch(databaseProvider);
  final month = ref.watch(selectedMonthProvider);
  final selectedType = ref.watch(selectedTypeProvider);

  final database = await databaseAsync.when(
    data: (db) => db,
    loading: () => throw Exception('Database loading'),
    error: (e, _) => throw e,
  );

  final prevMonth = DateTime(month.year, month.month - 1, 1);
  yield* database.watchTotalByMonthAndType(prevMonth, selectedType);
});

// Category list (static from default categories)
final categoryListProvider = Provider<List<CategoryModel>>((ref) {
  return defaultCategories;
});

// ─── V3.1 新增 providers ─────────────────────────────

// M2 删除撤销：被删记录缓存（M2 物理删除+内存缓存方案）
final lastDeletedRecordProvider = StateProvider<Record?>((ref) => null);

// M3a 最近使用分类：按当前类型近 30 天使用频次 Top 3
final recentCategoriesProvider =
    StreamProvider.family<List<Category>, String>((ref, type) async* {
  final databaseAsync = ref.watch(databaseProvider);
  final database = await databaseAsync.when(
    data: (db) => db,
    loading: () => throw Exception('Database loading'),
    error: (e, _) => throw e,
  );
  yield* database.watchRecentCategoriesByType(type);
});

// M4a 月度结余：income / expense 双聚合
typedef MonthlyStats = ({double income, double expense});

final monthlySurplusProvider =
    StreamProvider.family<MonthlyStats, DateTime>((ref, month) async* {
  final databaseAsync = ref.watch(databaseProvider);
  final database = await databaseAsync.when(
    data: (db) => db,
    loading: () => throw Exception('Database loading'),
    error: (e, _) => throw e,
  );
  yield* database.watchMonthlySurplus(month);
});

// M4b 月度预算
final monthlyBudgetProvider =
    StreamProvider.family<Budget?, DateTime>((ref, month) async* {
  final databaseAsync = ref.watch(databaseProvider);
  final database = await databaseAsync.when(
    data: (db) => db,
    loading: () => throw Exception('Database loading'),
    error: (e, _) => throw e,
  );
  yield* database.watchMonthlyBudget(month);
});
