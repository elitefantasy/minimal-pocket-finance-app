import 'package:akm_finance_manager/features/statistics/application/statistics_provider.dart';
import 'package:akm_finance_manager/features/statistics/presentation/widgets/category_statistics_tile.dart';
import 'package:akm_finance_manager/features/statistics/presentation/widgets/statistics_summary_card.dart';
import 'package:akm_finance_manager/shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statisticsAsync = ref.watch(statisticsProvider);

    return AppScaffold(
      title: 'Statistics',
      body: statisticsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text(error.toString())),
        data: (summary) {
          if (summary.transactionCount == 0) {
            return const Center(child: Text('No statistics available'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              StatisticsSummaryCard(summary: summary),
              const SizedBox(height: 16),
              Text(
                'Expense Categories',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ...summary.expenseCategories.map(
                (statistics) => CategoryStatisticsTile(statistics: statistics),
              ),
            ],
          );
        },
      ),
    );
  }
}
