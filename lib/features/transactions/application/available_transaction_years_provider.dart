import 'package:minimal_pocket_finance_app/app/providers.dart';
import 'package:minimal_pocket_finance_app/features/transactions/application/transaction_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final availableTransactionYearsProvider = FutureProvider<List<int>>((ref) async {
  ref.watch(transactionNotifierProvider);
  return ref.read(transactionRepositoryProvider).getAvailableYears();
});
