import 'package:minimal_pocket_finance_app/app/providers.dart';
import 'package:minimal_pocket_finance_app/features/transactions/application/transaction_notifier.dart';
import 'package:minimal_pocket_finance_app/models/transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Loads trashed transactions and refreshes after any transaction change.
final trashTransactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  ref.watch(transactionNotifierProvider);
  return ref.read(transactionServiceProvider).getTrashedTransactions();
});
