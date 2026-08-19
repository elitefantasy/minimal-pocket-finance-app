import 'package:minimal_pocket_finance_app/models/transaction.dart';

/// Utility class for calculating the total period in months for financial analytics.
abstract final class PeriodCalculator {
  /// Calculates the total number of elapsed months in the scope defined by [selectedYear]
  /// and the provided [transactions].
  ///
  /// - If [selectedYear] is a past year, returns 12 months.
  /// - If [selectedYear] is the current year, returns elapsed months up to the current month
  ///   (or latest transaction month in the year).
  /// - If [selectedYear] is a future year, returns max transaction month in that year or 1.
  /// - If [selectedYear] is null ("All Years"), returns total months from the earliest transaction date
  ///   to the current date (or latest transaction date).
  static int calculatePeriodMonths(
    int? selectedYear,
    List<Transaction> transactions,
  ) {
    final now = DateTime.now();

    if (selectedYear != null) {
      if (selectedYear < now.year) {
        // A full past year spans 12 calendar months.
        return 12;
      } else if (selectedYear == now.year) {
        // Current year: elapsed months so far, or latest transaction month if future months exist.
        var maxMonth = now.month;
        for (final tx in transactions) {
          if (tx.date.year == selectedYear && tx.date.month > maxMonth) {
            maxMonth = tx.date.month;
          }
        }
        return maxMonth;
      } else {
        // Future year: max transaction month recorded or 1.
        var maxMonth = 1;
        for (final tx in transactions) {
          if (tx.date.year == selectedYear && tx.date.month > maxMonth) {
            maxMonth = tx.date.month;
          }
        }
        return maxMonth;
      }
    }

    // All Years selected (selectedYear == null)
    if (transactions.isEmpty) {
      return 1;
    }

    // Determine time range from earliest transaction date to current/latest date
    var startYear = now.year;
    var startMonth = now.month;
    var endYear = now.year;
    var endMonth = now.month;

    for (final tx in transactions) {
      if (tx.date.year < startYear ||
          (tx.date.year == startYear && tx.date.month < startMonth)) {
        startYear = tx.date.year;
        startMonth = tx.date.month;
      }
      if (tx.date.year > endYear ||
          (tx.date.year == endYear && tx.date.month > endMonth)) {
        endYear = tx.date.year;
        endMonth = tx.date.month;
      }
    }

    final totalMonths =
        (endYear - startYear) * 12 + (endMonth - startMonth) + 1;
    return totalMonths < 1 ? 1 : totalMonths;
  }

  /// Calculates the number of category-active calendar months within the provided list
  /// of transactions for a specific category.
  ///
  /// Returns the count of distinct calendar months (year, month pairs) in which
  /// [categoryTransactions] occurred.
  /// If no transactions exist for the category, returns 1 to avoid division by zero.
  static int calculateCategoryActiveMonths(
    List<Transaction> categoryTransactions,
  ) {
    if (categoryTransactions.isEmpty) {
      return 1;
    }
    final activeMonths = <(int, int)>{};
    for (final tx in categoryTransactions) {
      activeMonths.add((tx.date.year, tx.date.month));
    }
    return activeMonths.isEmpty ? 1 : activeMonths.length;
  }
}

