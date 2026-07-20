import 'package:akm_finance_manager/app/providers.dart';
import 'package:akm_finance_manager/features/transactions/application/transaction_notifier.dart';
import 'package:akm_finance_manager/models/transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Loads trashed transactions and refreshes after any transaction change.
final trashTransactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  ref.watch(transactionNotifierProvider);
  return ref.read(transactionServiceProvider).getTrashedTransactions();
});
