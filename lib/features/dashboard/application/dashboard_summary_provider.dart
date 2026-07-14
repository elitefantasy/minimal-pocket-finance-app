import 'package:akm_finance_manager/features/categories/application/category_notifier.dart';
import 'package:akm_finance_manager/features/transactions/application/transaction_notifier.dart';
import 'package:akm_finance_manager/models/dashboard_summary.dart';
import 'package:akm_finance_manager/models/transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardSummaryProvider = Provider<AsyncValue<DashboardSummary>>((ref) {
  final transactionsAsync = ref.watch(transactionNotifierProvider);

  return transactionsAsync.whenData((transactions) {
    final income = transactions
        .where((transaction) => transaction.type == 'Income')
        .fold<double>(0, (total, transaction) => total + transaction.amount);
    final expenseTransactions = transactions
        .where((transaction) => transaction.type == 'Expense')
        .toList(growable: false);
    final expense = expenseTransactions.fold<double>(
      0,
      (total, transaction) => total + transaction.amount,
    );
    final now = DateTime.now();
    final currentMonthExpense = expenseTransactions
        .where(
          (transaction) =>
              transaction.date.year == now.year &&
              transaction.date.month == now.month,
        )
        .fold<double>(0, (total, transaction) => total + transaction.amount);

    // Group expenses by calendar month.
    final monthlyExpenses = <(int, int), double>{};

    for (final transaction in expenseTransactions) {
      final key = (transaction.date.year, transaction.date.month);

      monthlyExpenses.update(
        key,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }

    final averageMonthlyExpense = monthlyExpenses.isEmpty
        ? 0.0
        : monthlyExpenses.values.fold<double>(
                0,
                (total, amount) => total + amount,
              ) /
              monthlyExpenses.length;

    final categoryTotals = <String, _CategoryExpense>{};
    for (final transaction in expenseTransactions) {
      final category = categoryTotals.putIfAbsent(
        transaction.category,
        _CategoryExpense.new,
      );
      category.totalExpense += transaction.amount;
      category.months.add((transaction.date.year, transaction.date.month));
    }

    final topCategories =
        categoryTotals.entries
            .map(
              (entry) => TopCategorySummary(
                name: entry.key,
                monthlyAverage:
                    entry.value.totalExpense / entry.value.months.length,
                totalExpense: entry.value.totalExpense,
              ),
            )
            .toList()
          ..sort(
            (first, second) =>
                second.totalExpense.compareTo(first.totalExpense),
          );
    final recentTransactions = List<Transaction>.of(transactions)
      ..sort((first, second) => second.date.compareTo(first.date));

    return DashboardSummary(
      balance: income - expense,
      income: income,
      expense: expense,
      currentMonthExpense: currentMonthExpense,
      averageMonthlyExpense: averageMonthlyExpense,
      recentTransactions: recentTransactions.take(5).toList(growable: false),
      topCategories: topCategories.take(5).toList(growable: false),
    );
  });
});

class _CategoryExpense {
  double totalExpense = 0;
  final Set<(int, int)> months = <(int, int)>{};
}
