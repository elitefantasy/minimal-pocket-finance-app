import 'package:akm_finance_manager/app/providers.dart';
import 'package:akm_finance_manager/models/transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TransactionNotifier extends AsyncNotifier<List<Transaction>> {
  @override
  Future<List<Transaction>> build() {
    return ref.read(transactionServiceProvider).getAllTransactions();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<List<Transaction>>();
    state = await AsyncValue.guard(
      () => ref.read(transactionServiceProvider).getAllTransactions(),
    );
  }

  Future<void> add(Transaction transaction) async {
    await ref.read(transactionServiceProvider).addTransaction(transaction);
    await refresh();
  }

  Future<void> restoreDeletedTransaction(Transaction transaction) async {
    await ref
        .read(transactionServiceProvider)
        .restoreDeletedTransaction(transaction);
    await refresh();
  }

  Future<void> deleteTransaction(int id) async {
    await ref.read(transactionServiceProvider).deleteTransaction(id);
    await refresh();
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await ref.read(transactionServiceProvider).updateTransaction(transaction);
    await refresh();
  }
}

final transactionNotifierProvider =
    AsyncNotifierProvider<TransactionNotifier, List<Transaction>>(
      TransactionNotifier.new,
    );
