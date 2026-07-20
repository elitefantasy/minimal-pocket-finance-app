import 'package:akm_finance_manager/features/categories/application/category_notifier.dart';
import 'package:akm_finance_manager/features/transactions/application/transaction_notifier.dart';
import 'package:akm_finance_manager/features/transactions/application/selected_year_provider.dart';
import 'package:akm_finance_manager/models/dashboard_summary.dart';
import 'package:akm_finance_manager/models/transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A Riverpod provider that listens to transaction changes and computes
/// raw aggregated analytics required by the dashboard.
/// Note: Sorting logic has been decoupled to allow targeted UI rebuilds.
final dashboardSummaryProvider = Provider<AsyncValue<DashboardSummary>>((ref) {
  // Watch the asynchronous transaction data source
  final transactionsAsync = ref.watch(transactionNotifierProvider);
  final selectedYear = ref.watch(selectedYearProvider);

  // Safely map asynchronous data once it resolves successfully
  return transactionsAsync.whenData((transactions) {
    
    // 1. Calculate the total lifetime income
    final income = transactions
        .where((transaction) => transaction.type == 'Income')
        .fold<double>(0, (total, transaction) => total + transaction.amount);

    // 2. Filter out expense transactions to a separate list for easier processing
    final expenseTransactions = transactions
        .where((transaction) => transaction.type == 'Expense')
        .toList(growable: false);

    // 3. Calculate the total lifetime expenses
    final expense = expenseTransactions.fold<double>(
      0,
      (total, transaction) => total + transaction.amount,
    );

    // 4. Calculate the expenses incurred only in the current calendar month
    final now = DateTime.now();
    final currentMonthYear = selectedYear ?? now.year;
    final currentMonthExpense = expenseTransactions
        .where(
          (transaction) =>
              transaction.date.year == currentMonthYear &&
              transaction.date.month == now.month,
        )
        .fold<double>(0, (total, transaction) => total + transaction.amount);

    // 5. Group expenses by calendar month using a Map with a (Year, Month) record key
    final monthlyExpenses = <(int, int), double>{};
    for (final transaction in expenseTransactions) {
      final key = (transaction.date.year, transaction.date.month);
      monthlyExpenses.update(
        key,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }

    // 6. Calculate the average expense per month across all recorded months
    final averageMonthlyExpense = monthlyExpenses.isEmpty
        ? 0.0
        : monthlyExpenses.values.fold<double>(
              0,
              (total, amount) => total + amount,
            ) /
            monthlyExpenses.length;

    // 7. Accumulate total expenses and track unique months per category
    final categoryTotals = <String, _CategoryExpense>{};
    for (final transaction in expenseTransactions) {
      final category = categoryTotals.putIfAbsent(
        transaction.category,
        _CategoryExpense.new,
      );
      category.totalExpense += transaction.amount;
      category.months.add((transaction.date.year, transaction.date.month));
    }

    // 8. Transform raw category analytics into a list of TopCategorySummary items
    final topCategories = categoryTotals.entries
        .map(
          (entry) => TopCategorySummary(
            name: entry.key,
            monthlyAverage: entry.value.months.isEmpty
                ? 0
                : entry.value.totalExpense / entry.value.months.length,
            totalExpense: entry.value.totalExpense,
          ),
        )
        .toList();

    // 9. Sort all transactions globally by date descending to extract the newest entries
    final recentTransactions = List<Transaction>.of(transactions)
      ..sort((first, second) => second.date.compareTo(first.date));

    // Construct and return the final read-only summary payload for the UI
    return DashboardSummary(
      balance: income - expense, 
      income: income,
      expense: expense,
      currentMonthExpense: currentMonthExpense,
      averageMonthlyExpense: averageMonthlyExpense,
      recentTransactions: recentTransactions.take(5).toList(growable: false),
      topCategories: topCategories, // Passes down raw unsorted list for downstream sorted providers
    );
  });
});

/// Internal helper class used to temporarily group and calculate statistics 
/// for specific expense categories during compilation.
class _CategoryExpense {
  double totalExpense = 0;
  final Set<(int, int)> months = <(int, int)>{};
}
