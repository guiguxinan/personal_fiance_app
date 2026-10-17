import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'providers/database_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 zh_CN locale 数据（DateFormat 依赖，否则抛 LocaleDataException）
  await initializeDateFormatting('zh_CN');

  final container = ProviderContainer();
  // Keep database alive by reading it once
  await container.read(databaseProvider.future);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const PersonalFinanceApp(),
    ),
  );
}
