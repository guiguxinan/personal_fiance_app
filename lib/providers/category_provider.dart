import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import 'database_provider.dart';

// All categories stream (from DB, includes custom categories)
final categoriesStreamProvider = StreamProvider<List<Category>>((ref) async* {
  final databaseAsync = ref.watch(databaseProvider);
  final database = await databaseAsync.when(
    data: (db) => db,
    loading: () => throw Exception('Database loading'),
    error: (e, _) => throw e,
  );
  yield* database.watchAllCategories();
});
