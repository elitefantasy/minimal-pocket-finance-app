import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akm_finance_manager/features/dashboard/application/dashboard_summary_provider.dart';
import 'package:akm_finance_manager/features/dashboard/application/sorted_top_categories_provider.dart';
import 'package:akm_finance_manager/features/dashboard/presentation/widgets/summary_card.dart';
import 'package:akm_finance_manager/features/dashboard/presentation/widgets/monthly_expense_card.dart';
import 'package:akm_finance_manager/features/dashboard/presentation/widgets/top_categories_card.dart';
import 'package:akm_finance_manager/features/dashboard/presentation/widgets/recent_transactions_card.dart';
import 'package:akm_finance_manager/shared/widgets/app_scaffold.dart';

/// The main entry dashboard screen representing metrics, graphs, recent transactions,
/// and category spend breakdown.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the master asynchronous dashboard summary provider
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    // Watch the dedicated provider handling sorted category metrics asynchronously
    final sortedCategoriesAsync = ref.watch(sortedTopCategoriesProvider);

    return summaryAsync.when(
      // Render fallback loading indicator while summary details compile
      loading: () => const AppScaffold(
        title: 'Dashboard',
        body: Center(child: CircularProgressIndicator()),
      ),
      // Render clean error text message if provider initialization fails
      error: (error, stackTrace) => AppScaffold(
        title: 'Dashboard',
        body: Center(child: Text(error.toString())),
      ),
      data: (summary) {
        // Safe extraction: resolve values from the specialized sorting provider.
        // Fall back to the default unsorted model array if asynchronous data isn't ready.
        final sortedCategories = sortedCategoriesAsync.value ?? summary.topCategories;

        return AppScaffold(
          title: 'Dashboard',
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              // Forces inner elements to expand dynamically horizontally
              crossAxisAlignment: CrossAxisAlignment.stretch, 
              children: [
                // Top Highlighted Metric: Running Net Worth/Balance
                SummaryCard(
                  title: 'Current Balance',
                  value: '₹${summary.balance.toStringAsFixed(0)}',
                ),
                const SizedBox(height: 16), // Vertical element spacing

                // Split metrics display container block
                Row(
                  children: [
                    Expanded(
                      // Left Pillar: Income Aggregates
                      child: SummaryCard(
                        title: 'Income',
                        value: '₹${summary.income.toStringAsFixed(0)}',
                      ),
                    ),
                    const SizedBox(width: 16), // Horizontal gap spacing split
                    Expanded(
                      // Right Pillar: Outbound Expenses
                      child: SummaryCard(
                        title: 'Expense',
                        value: '₹${summary.expense.toStringAsFixed(0)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Dynamic Top Expenditure Visual Categories Card 
                TopCategoriesCard(
                  categories: sortedCategories,
                ),
                const SizedBox(height: 16),

                // Isolated structural comparison blocks (Monthly Contexts)
                MonthlyExpenseCard(
                  title: 'Current Month Expense',
                  amount: '₹${summary.currentMonthExpense.toStringAsFixed(0)}',
                ),
                const SizedBox(height: 16),
                MonthlyExpenseCard(
                  title: 'Monthly Average',
                  amount: '₹${summary.averageMonthlyExpense.toStringAsFixed(0)}',
                ),
                const SizedBox(height: 16),

                // Recent ledger history overview item card
                RecentTransactionsCard(
                  transactions: summary.recentTransactions,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}