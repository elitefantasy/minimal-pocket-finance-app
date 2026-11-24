import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_pocket_finance_app/core/utils/period_calculator.dart';
import 'package:minimal_pocket_finance_app/models/transaction.dart';

void main() {
  group('PeriodCalculator tests', () {
    final now = DateTime.now();

    test('Past year returns 12 months', () {
      final period = PeriodCalculator.calculatePeriodMonths(now.year - 1, []);
      expect(period, 12);
    });

    test('Current year returns elapsed months', () {
      final period = PeriodCalculator.calculatePeriodMonths(now.year, []);
      expect(period, now.month);
    });

    test('All years returns 1 for empty transactions', () {
      final period = PeriodCalculator.calculatePeriodMonths(null, []);
      expect(period, 1);
    });

    test('All years calculates month range correctly from transactions', () {
      final txs = <Transaction>[
        Transaction(
          id: '1',
          note: 'Past Tx',
          amount: 100,
          category: 'Food',
          date: DateTime(2025, 1, 15),
          type: 'Expense',
        ),
        Transaction(
          id: '2',
          note: 'Recent Tx',
          amount: 200,
          category: 'Rent',
          date: DateTime(2025, 12, 10),
          type: 'Expense',
        ),
      ];

      // From Jan 2025 to now (e.g. Aug 2026 => (2026-2025)*12 + (8-1) + 1 = 20 months)
      final expectedMonths =
          (now.year - 2025) * 12 + (now.month - 1) + 1;
      final period = PeriodCalculator.calculatePeriodMonths(null, txs);
      expect(period, expectedMonths);
    });

    test('calculateCategoryActiveMonths returns distinct active months count', () {
      final txs = <Transaction>[
        Transaction(
          id: '1',
          note: 'Tx 1',
          amount: 100,
          category: 'Streaming',
          date: DateTime(2026, 6, 24),
          type: 'Expense',
        ),
        Transaction(
          id: '2',
          note: 'Tx 2',
          amount: 200,
          category: 'Streaming',
          date: DateTime(2026, 7, 15),
          type: 'Expense',
        ),
        Transaction(
          id: '3',
          note: 'Tx 3',
          amount: 300,
          category: 'Streaming',
          date: DateTime(2026, 8, 10),
          type: 'Expense',
        ),
      ];

      final activeMonths = PeriodCalculator.calculateCategoryActiveMonths(txs);
      expect(activeMonths, 3);
    });

    test('calculateCategoryActiveMonths returns 1 for empty category transactions', () {
      final activeMonths = PeriodCalculator.calculateCategoryActiveMonths([]);
      expect(activeMonths, 1);
    });

    test('Category monthly average uses elapsed period months for past year', () {
      // Scenario: User spent ₹3,600 on "Entertainment" across only 3 months in 2025.
      // In industry standard budgeting, the monthly average for 2025 must divide by 12,
      // not 3, giving ₹300/month instead of ₹1,200/month.
      final periodMonths = PeriodCalculator.calculatePeriodMonths(2025, []);
      expect(periodMonths, 12);

      const totalCategoryExpense = 3600.0;
      final monthlyAverage = totalCategoryExpense / periodMonths;
      expect(monthlyAverage, 300.0);
    });

    test('Category monthly average uses elapsed months up to current month for current year', () {
      final now = DateTime.now();
      final periodMonths = PeriodCalculator.calculatePeriodMonths(now.year, []);
      expect(periodMonths, now.month);

      final totalCategoryExpense = 1000.0 * now.month;
      final monthlyAverage = totalCategoryExpense / periodMonths;
      expect(monthlyAverage, 1000.0);
    });
  });
}

