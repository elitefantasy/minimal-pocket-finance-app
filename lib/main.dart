import 'package:akm_finance_manager/features/recurring/application/recurring_processing_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akm_finance_manager/app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  container.read(recurringLifecycleProvider);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MinimalPocketFinanceApp(),
    ),
  );
}
