import 'package:minimal_pocket_finance_app/models/transaction.dart';

/// Immutable aggregate data displayed by the dashboard.
class DashboardSummary {
  DashboardSummary({
    required this.balance,
    required this.income,
    required this.expense,
    required this.currentMonthExpense,
    required this.averageMonthlyExpense,
    required List<Transaction> recentTransactions,
    required List<TopCategorySummary> topCategories,
  }) : recentTransactions = List<Transaction>.unmodifiable(recentTransactions),
       topCategories = List<TopCategorySummary>.unmodifiable(topCategories);

  final double balance;
  final double income;
  final double expense;
  final double currentMonthExpense;

  /// Average monthly expense across all elapsed period months in the selected scope.
  final double averageMonthlyExpense;
  final List<Transaction> recentTransactions;
  final List<TopCategorySummary> topCategories;
}

/// Immutable expense totals for one category.
class TopCategorySummary {
  const TopCategorySummary({
    required this.name,
    required this.monthlyAverage,
    required this.totalExpense,
  });

  final String name;
  final double monthlyAverage;
  final double totalExpense;
}
