import 'package:akm_finance_manager/core/theme/app_icons.dart';
import 'package:akm_finance_manager/core/theme/app_spacing.dart';
import 'package:akm_finance_manager/core/theme/theme_context_extensions.dart';
import 'package:akm_finance_manager/features/statistics/application/statistics_provider.dart';
import 'package:akm_finance_manager/features/statistics/presentation/widgets/category_statistics_tile.dart';
import 'package:akm_finance_manager/features/statistics/presentation/widgets/statistics_summary_card.dart';
import 'package:akm_finance_manager/features/transactions/application/transaction_filter_provider.dart';
import 'package:akm_finance_manager/features/transactions/application/transaction_notifier.dart';
import 'package:akm_finance_manager/features/transactions/presentation/history_navigation.dart';
import 'package:akm_finance_manager/models/transaction.dart';
import 'package:akm_finance_manager/shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statisticsAsync = ref.watch(statisticsProvider);
    final transactions = ref.watch(transactionNotifierProvider).asData?.value;

    return AppScaffold(
      title: 'Statistics',
      body: statisticsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text(error.toString())),
        data: (summary) {
          if (summary.transactionCount == 0) {
            return const _StatisticsEmptyState();
          }
          final highestIncomeTransaction = _highestTransaction(
            transactions,
            'Income',
            summary.highestIncome,
          );
          final highestExpenseTransaction = _highestTransaction(
            transactions,
            'Expense',
            summary.highestExpense,
          );

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.page),
            children: <Widget>[
              StatisticsSummaryCard(
                summary: summary,
                onHighestIncome: highestIncomeTransaction == null
                    ? null
                    : () => context.push('/edit', extra: highestIncomeTransaction),
                onHighestExpense: highestExpenseTransaction == null
                    ? null
                    : () => context.push('/edit', extra: highestExpenseTransaction),
              ),
              const SizedBox(height: AppSpacing.section),
              Text('Expense Categories', style: context.text.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'A closer look at where your money goes.',
                style: context.text.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ...summary.expenseCategories.map(
                (statistics) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: CategoryStatisticsTile(
                    statistics: statistics,
                    onTap: () => HistoryNavigation.open(
                      context,
                      category: statistics.name,
                      transactionType: TransactionFilter.expense,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Transaction? _highestTransaction(
    List<Transaction>? transactions,
    String type,
    double amount,
  ) {
    if (transactions == null || amount == 0) {
      return null;
    }
    for (final transaction in transactions) {
      if (transaction.type == type && transaction.amount == amount) {
        return transaction;
      }
    }
    return null;
  }
}

class _StatisticsEmptyState extends StatelessWidget {
  const _StatisticsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              AppIcons.statistics,
              size: AppIcons.largeSize,
              color: context.colors.secondary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('No statistics yet', style: context.text.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Add transactions to see your spending summary and categories here.',
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
