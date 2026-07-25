import 'package:akm_finance_manager/app/providers.dart';
import 'package:akm_finance_manager/features/transactions/application/selected_year_provider.dart';
import 'package:akm_finance_manager/models/transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TransactionNotifier extends AsyncNotifier<List<Transaction>> {
  @override
  Future<List<Transaction>> build() {
    final selectedYear = ref.watch(selectedYearProvider);
    return ref.read(transactionServiceProvider).getAllTransactions(
      year: selectedYear,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading<List<Transaction>>();
    state = await AsyncValue.guard(
      () => ref.read(transactionServiceProvider).getAllTransactions(
        year: ref.read(selectedYearProvider),
      ),
    );
  }

  Future<void> add(Transaction transaction) async {
    await ref.read(transactionServiceProvider).addTransaction(transaction);
    await refresh();
  }

  Future<void> restoreDeletedTransaction(String id) async {
    await ref
        .read(transactionServiceProvider)
        .restoreDeletedTransaction(id);
    await refresh();
  }

  Future<void> deleteTransaction(String id) async {
    await ref.read(transactionServiceProvider).deleteTransaction(id);
    await refresh();
  }

  Future<void> permanentlyDeleteTransaction(String id) async {
    await ref
        .read(transactionServiceProvider)
        .permanentlyDeleteTransaction(id);
    await refresh();
  }

  Future<void> emptyTrash() async {
    await ref.read(transactionServiceProvider).emptyTrash();
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
