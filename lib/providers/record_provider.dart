import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import '../data/models/category_model.dart';
import 'database_provider.dart';

// Selected month provider
final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

// Records by month
final recordsByMonthProvider = StreamProvider<List<Record>>((ref) async* {
  final databaseAsync = ref.watch(databaseProvider);
  final month = ref.watch(selectedMonthProvider);

  final database = await databaseAsync.when(
    data: (db) => db,
    loading: () => throw Exception('Database loading'),
    error: (e, _) => throw e,
  );

  yield* database.watchRecordsByMonth(month);
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

  final database = await databaseAsync.when(
    data: (db) => db,
    loading: () => throw Exception('Database loading'),
    error: (e, _) => throw e,
  );

  yield* database.watchCategorySummariesByMonth(month);
});

// Total spending by month
final totalSpendingProvider = StreamProvider<double>((ref) async* {
  final databaseAsync = ref.watch(databaseProvider);
  final month = ref.watch(selectedMonthProvider);

  final database = await databaseAsync.when(
    data: (db) => db,
    loading: () => throw Exception('Database loading'),
    error: (e, _) => throw e,
  );

  yield* database.watchTotalSpendingByMonth(month);
});

// Category list (static from default categories)
final categoryListProvider = Provider<List<CategoryModel>>((ref) {
  return defaultCategories;
});
