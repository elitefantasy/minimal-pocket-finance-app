import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akm_finance_manager/features/dashboard/application/dashboard_summary_provider.dart';
import 'package:akm_finance_manager/features/dashboard/presentation/widgets/summary_card.dart';
import 'package:akm_finance_manager/features/dashboard/presentation/widgets/monthly_expense_card.dart';
import 'package:akm_finance_manager/features/dashboard/presentation/widgets/top_categories_card.dart';
import 'package:akm_finance_manager/features/dashboard/presentation/widgets/recent_transactions_card.dart';
import 'package:akm_finance_manager/shared/widgets/app_scaffold.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return summaryAsync.when(
      loading: () => const AppScaffold(
        title: 'Dashboard',
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => AppScaffold(
        title: 'Dashboard',
        body: Center(child: Text(error.toString())),
      ),
      data: (summary) {
        return AppScaffold(
          title: 'Dashboard',
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment
                  .stretch, // A Column has two axes: X and Y stretch tells widgets to fill the available width.
              children: [
                SummaryCard(
                  title: 'Current Balance',
                  value: '₹${summary.balance.toStringAsFixed(0)}',
                ),
                const SizedBox(
                  height: 16,
                ), // Adds horizontal spacing between the two cards.
                Row(
                  // arange widgets horizontally
                  children: [
                    Expanded(
                      // share available widht equally
                      child: SummaryCard(
                        title: 'Income',
                        value: '₹${summary.income.toStringAsFixed(0)}',
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: SummaryCard(
                        title: 'Expense',
                        value: '₹${summary.expense.toStringAsFixed(0)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TopCategoriesCard(categories: summary.topCategories),
                const SizedBox(height: 16),

                MonthlyExpenseCard(
                  amount: '₹${summary.currentMonthExpense.toStringAsFixed(0)}',
                ),
                const SizedBox(height: 16),

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
