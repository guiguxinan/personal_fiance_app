import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import 'database_provider.dart';

/// 所有分类的实时流（含 8 支出 + 5 收入 + 自定义）。
/// UI 端通过 [categoryByIdProvider] / [categoriesByTypeProvider] 派生。
final categoriesStreamProvider = StreamProvider<List<Category>>((ref) async* {
  final databaseAsync = ref.watch(databaseProvider);
  final database = await databaseAsync.when(
    data: (db) => db,
    loading: () => throw Exception('Database loading'),
    error: (e, _) => throw e,
  );
  yield* database.watchAllCategories();
});

/// 按 type 过滤的分类列表（'expense' / 'income'）。
/// 用于首页 Top4、记账页分类网格、统计页环形图。
final categoriesByTypeProvider =
    Provider.family<AsyncValue<List<Category>>, String>((ref, type) {
  final allAsync = ref.watch(categoriesStreamProvider);
  return allAsync.whenData(
    (cats) => cats.where((c) => c.type == type).toList(growable: false),
  );
});

/// 按 id 查单个 Category；查不到返回 null。
/// 用于记录列表项、统计明细、饼图 badge。
final categoryByIdProvider = Provider.family<Category?, int>((ref, id) {
  final all = ref.watch(categoriesStreamProvider).valueOrNull;
  if (all == null) return null;
  for (final c in all) {
    if (c.id == id) return c;
  }
  return null;
});
