/// Immutable aggregate statistics for all transactions.
class StatisticsSummary {
  StatisticsSummary({
    required this.balance,
    required this.totalIncome,
    required this.totalExpense,
    required this.transactionCount,
    required this.highestIncome,
    required this.highestExpense,
    required List<CategoryStatistics> expenseCategories,
  }) : expenseCategories = List<CategoryStatistics>.unmodifiable(
         expenseCategories,
       );

  final double balance;
  final double totalIncome;
  final double totalExpense;
  final int transactionCount;
  final double highestIncome;
  final double highestExpense;
  final List<CategoryStatistics> expenseCategories;
}

/// Immutable expense statistics for one category.
class CategoryStatistics {
  const CategoryStatistics({
    required this.name,
    required this.totalExpense,
    required this.monthsAppeared,
    required this.averagePerMonth,
  });

  final String name;
  final double totalExpense;
  final int monthsAppeared;
  final double averagePerMonth;
}
