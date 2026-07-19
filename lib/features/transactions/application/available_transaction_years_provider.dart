import 'package:akm_finance_manager/app/providers.dart';
import 'package:akm_finance_manager/features/transactions/application/transaction_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final availableTransactionYearsProvider = FutureProvider<List<int>>((ref) async {
  ref.watch(transactionNotifierProvider);
  return ref.read(transactionRepositoryProvider).getAvailableYears();
});
