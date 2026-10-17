import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';

final databaseProvider = FutureProvider<AppDatabase>((ref) async {
  return AppDatabase();
});
