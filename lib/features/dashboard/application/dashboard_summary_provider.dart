import 'package:minimal_pocket_finance_app/core/utils/period_calculator.dart';
import 'package:minimal_pocket_finance_app/features/transactions/application/transaction_notifier.dart';
import 'package:minimal_pocket_finance_app/features/transactions/application/selected_year_provider.dart';
import 'package:minimal_pocket_finance_app/models/dashboard_summary.dart';
import 'package:minimal_pocket_finance_app/models/transaction.dart';
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

    // 5. Calculate total period months in current scope for accurate monthly average calculations
    final periodMonths = PeriodCalculator.calculatePeriodMonths(
      selectedYear,
      expenseTransactions,
    );

    // 6. Calculate the average expense per month across total period months
    final averageMonthlyExpense = expenseTransactions.isEmpty
        ? 0.0
        : expense / periodMonths;

    // 7. Accumulate total expenses and transactions per category
    final categoryTotals = <String, double>{};
    final categoryTransactionsMap = <String, List<Transaction>>{};
    for (final transaction in expenseTransactions) {
      categoryTotals.update(
        transaction.category,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
      categoryTransactionsMap
          .putIfAbsent(transaction.category, () => <Transaction>[])
          .add(transaction);
    }

    // 8. Transform raw category analytics into a list of TopCategorySummary items
    // Category monthly average is calculated over category-active calendar months.
    final topCategories = categoryTotals.entries
        .map(
          (entry) {
            final catTxs =
                categoryTransactionsMap[entry.key] ?? const <Transaction>[];
            final catActiveMonths =
                PeriodCalculator.calculateCategoryActiveMonths(catTxs);
            return TopCategorySummary(
              name: entry.key,
              monthlyAverage: entry.value / catActiveMonths,
              totalExpense: entry.value,
            );
          },
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
