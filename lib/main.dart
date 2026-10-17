import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'providers/database_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
