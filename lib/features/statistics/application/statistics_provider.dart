import 'package:minimal_pocket_finance_app/core/utils/period_calculator.dart';
import 'package:minimal_pocket_finance_app/features/transactions/application/selected_year_provider.dart';
import 'package:minimal_pocket_finance_app/features/transactions/application/transaction_notifier.dart';
import 'package:minimal_pocket_finance_app/models/statistics_summary.dart';
import 'package:minimal_pocket_finance_app/models/transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final statisticsProvider = Provider<AsyncValue<StatisticsSummary>>((ref) {
  final transactionsAsync = ref.watch(transactionNotifierProvider);
  final selectedYear = ref.watch(selectedYearProvider);

  return transactionsAsync.whenData((transactions) {
    var totalIncome = 0.0;
    var totalExpense = 0.0;
    var highestIncome = 0.0;
    var highestExpense = 0.0;
    final categoryTotals = <String, _CategoryAccumulator>{};
    final expenseTransactions = <Transaction>[];

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

        expenseTransactions.add(transaction);

        final category = categoryTotals.putIfAbsent(
          transaction.category,
          _CategoryAccumulator.new,
        );
        category.totalExpense += transaction.amount;
        category.months.add((transaction.date.year, transaction.date.month));
      }
    }

    // Calculate total elapsed period months in scope for consistent category monthly averages
    final periodMonths = PeriodCalculator.calculatePeriodMonths(
      selectedYear,
      expenseTransactions,
    );

    final expenseCategories =
        categoryTotals.entries
            .map(
              (entry) => CategoryStatistics(
                name: entry.key,
                totalExpense: entry.value.totalExpense,
                monthsAppeared: entry.value.months.length,
                averagePerMonth: periodMonths > 0
                    ? entry.value.totalExpense / periodMonths
                    : 0.0,
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
