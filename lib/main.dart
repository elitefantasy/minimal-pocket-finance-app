import 'package:akm_finance_manager/features/recurring/application/recurring_processing_provider.dart';
import 'package:akm_finance_manager/core/database/database_initializer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akm_finance_manager/app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop SQLite uses the FFI database factory. This must complete before
  // creating providers because startup processing can access the database.
  await initializeDatabase();

  final container = ProviderContainer();
  container.read(recurringLifecycleProvider);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MinimalPocketFinanceApp(),
    ),
  );
}
