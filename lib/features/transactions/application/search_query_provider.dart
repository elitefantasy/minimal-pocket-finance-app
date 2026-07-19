import 'package:akm_finance_manager/features/transactions/application/transaction_notifier.dart';
import 'package:akm_finance_manager/features/transactions/application/transaction_filter_provider.dart';
import 'package:akm_finance_manager/features/transactions/application/transaction_sort_provider.dart';
import 'package:akm_finance_manager/models/transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredTransactionsProvider = Provider<List<Transaction>>((ref) {
  final transactionsAsync = ref.watch(transactionNotifierProvider);
  final transactions = transactionsAsync.asData?.value ?? const <Transaction>[];
  final historyFilters = ref.watch(historyFiltersProvider);
  final transactionSort = ref.watch(transactionSortProvider);
  final searchText = ref.watch(searchQueryProvider).trim().toLowerCase();
  final transactionsByType = switch (historyFilters.transactionType) {
    TransactionFilter.all => transactions,
    TransactionFilter.income =>
      transactions
          .where((transaction) => transaction.type == 'Income')
          .toList(growable: false),
    TransactionFilter.expense =>
      transactions
          .where((transaction) => transaction.type == 'Expense')
          .toList(growable: false),
  };

  final transactionsByDrillDown = transactionsByType.where((transaction) {
    final matchesCategory =
        historyFilters.category == null ||
        transaction.category == historyFilters.category;
    final matchesMonth =
        historyFilters.month == null ||
        (transaction.date.month == historyFilters.month &&
            transaction.date.year == historyFilters.year);
    final matchesRecurring =
        historyFilters.isRecurring == null ||
        transaction.isRecurring == historyFilters.isRecurring;
    return matchesCategory && matchesMonth && matchesRecurring;
  });
  final matchingTransactions = searchText.isEmpty
      ? transactionsByDrillDown
      : transactionsByDrillDown.where((transaction) {
          return transaction.category.toLowerCase().contains(searchText) ||
              transaction.note.toLowerCase().contains(searchText) ||
              transaction.type.toLowerCase().contains(searchText) ||
              transaction.amount.toString().toLowerCase().contains(searchText);
        });
  final sortedTransactions = List<Transaction>.of(matchingTransactions);

  switch (transactionSort) {
    case TransactionSort.newestFirst:
      sortedTransactions.sort(
        (first, second) => second.date.compareTo(first.date),
      );
    case TransactionSort.oldestFirst:
      sortedTransactions.sort(
        (first, second) => first.date.compareTo(second.date),
      );
    case TransactionSort.highestAmount:
      sortedTransactions.sort(
        (first, second) => second.amount.compareTo(first.amount),
      );
    case TransactionSort.lowestAmount:
      sortedTransactions.sort(
        (first, second) => first.amount.compareTo(second.amount),
      );
    case TransactionSort.categoryAZ:
      sortedTransactions.sort(
        (first, second) => first.category.toLowerCase().compareTo(
          second.category.toLowerCase(),
        ),
      );
  }

  return sortedTransactions;
});
