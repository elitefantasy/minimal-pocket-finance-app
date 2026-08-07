import 'package:minimal_pocket_finance_app/features/transactions/application/transaction_notifier.dart';
import 'package:minimal_pocket_finance_app/models/statistics_summary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final statisticsProvider = Provider<AsyncValue<StatisticsSummary>>((ref) {
  final transactionsAsync = ref.watch(transactionNotifierProvider);

  return transactionsAsync.whenData((transactions) {
    var totalIncome = 0.0;
    var totalExpense = 0.0;
    var highestIncome = 0.0;
    var highestExpense = 0.0;
    final categoryTotals = <String, _CategoryAccumulator>{};

    for (final transaction in transactions) {
      if (transaction.type == 'Income') {
        totalIncome += transaction.amount;
        if (transaction.amount > highestIncome) {
          highestIncome = transaction.amount;
        }
        continue;
      }

      if (transaction.type == 'Expense') {
        totalExpense += transaction.amount;
        if (transaction.amount > highestExpense) {
          highestExpense = transaction.amount;
        }

        final category = categoryTotals.putIfAbsent(
          transaction.category,
          _CategoryAccumulator.new,
        );
        category.totalExpense += transaction.amount;
        category.months.add((transaction.date.year, transaction.date.month));
      }
    }

    final expenseCategories =
        categoryTotals.entries
            .map(
              (entry) => CategoryStatistics(
                name: entry.key,
                totalExpense: entry.value.totalExpense,
                monthsAppeared: entry.value.months.length,
                averagePerMonth:
                    entry.value.totalExpense / entry.value.months.length,
              ),
            )
            .toList()
          ..sort(
            (first, second) =>
                second.totalExpense.compareTo(first.totalExpense),
          );

    return StatisticsSummary(
      balance: totalIncome - totalExpense,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      transactionCount: transactions.length,
      highestIncome: highestIncome,
      highestExpense: highestExpense,
      expenseCategories: expenseCategories,
    );
  });
});

class _CategoryAccumulator {
  double totalExpense = 0;
  final Set<(int, int)> months = <(int, int)>{};
}
