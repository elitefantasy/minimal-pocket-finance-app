import 'package:akm_finance_manager/core/theme/app_icons.dart';
import 'package:akm_finance_manager/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akm_finance_manager/features/dashboard/application/dashboard_summary_provider.dart';
import 'package:akm_finance_manager/features/dashboard/application/sorted_top_categories_provider.dart';
import 'package:akm_finance_manager/features/dashboard/presentation/widgets/summary_card.dart';
import 'package:akm_finance_manager/features/dashboard/presentation/widgets/monthly_expense_card.dart';
import 'package:akm_finance_manager/features/dashboard/presentation/widgets/top_categories_card.dart';
import 'package:akm_finance_manager/features/dashboard/presentation/widgets/recent_transactions_card.dart';
import 'package:akm_finance_manager/features/transactions/application/transaction_filter_provider.dart';
import 'package:akm_finance_manager/features/transactions/presentation/history_navigation.dart';
import 'package:akm_finance_manager/shared/widgets/app_scaffold.dart';
import 'package:go_router/go_router.dart';

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
        final sortedCategories =
            sortedCategoriesAsync.value ?? summary.topCategories;

        return AppScaffold(
          title: 'Dashboard',
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              // Forces inner elements to expand dynamically horizontally
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Highlighted Metric: Running Net Worth/Balance
                SummaryCard(
                  tone: SummaryCardTone.balance,
                  title: 'Current Balance',
                  value: '₹${summary.balance.toStringAsFixed(0)}',
                ),
                const SizedBox(
                  height: AppSpacing.lg,
                ), // Vertical element spacing
                // Split metrics display container block
                Row(
                  children: [
                    Expanded(
                      // Left Pillar: Income Aggregates
                      child: SummaryCard(
                        tone: SummaryCardTone.income,
                        onTap: () => HistoryNavigation.open(
                          context,
                          transactionType: TransactionFilter.income,
                        ),
                        title: 'Income',
                        value: '₹${summary.income.toStringAsFixed(0)}',
                      ),
                    ),
                    const SizedBox(
                      width: AppSpacing.lg,
                    ), // Horizontal gap spacing split
                    Expanded(
                      // Right Pillar: Outbound Expenses
                      child: SummaryCard(
                        tone: SummaryCardTone.expense,
                        onTap: () => HistoryNavigation.open(
                          context,
                          transactionType: TransactionFilter.expense,
                        ),
                        title: 'Expense',
                        value: '₹${summary.expense.toStringAsFixed(0)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Dynamic Top Expenditure Visual Categories Card
                TopCategoriesCard(
                  categories: sortedCategories,
                  onCategoryTap: (category) => HistoryNavigation.open(
                    context,
                    category: category.name,
                    transactionType: TransactionFilter.expense,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Isolated structural comparison blocks (Monthly Contexts)
                MonthlyExpenseCard(
                  icon: AppIcons.calendarMonth,
                  title: 'Current Month Expense',
                  onTap: () => HistoryNavigation.open(
                    context,
                    transactionType: TransactionFilter.expense,
                    month: DateTime.now(),
                  ),
                  amount: '₹${summary.currentMonthExpense.toStringAsFixed(0)}',
                ),
                const SizedBox(height: AppSpacing.lg),
                MonthlyExpenseCard(
                  icon: AppIcons.statistics,
                  title: 'Monthly Average',
                  amount:
                      '₹${summary.averageMonthlyExpense.toStringAsFixed(0)}',
                ),
                const SizedBox(height: AppSpacing.lg),

                // Recent ledger history overview item card
                RecentTransactionsCard(
                  transactions: summary.recentTransactions,
                  onTransactionTap: (transaction) =>
                      context.push('/edit', extra: transaction),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
