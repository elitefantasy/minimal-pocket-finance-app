import 'package:akm_finance_manager/models/statistics_summary.dart';
import 'package:akm_finance_manager/core/theme/app_spacing.dart';
import 'package:akm_finance_manager/core/theme/theme_context_extensions.dart';
import 'package:flutter/material.dart';

class StatisticsSummaryCard extends StatelessWidget {
  const StatisticsSummaryCard({required this.summary, super.key});

  final StatisticsSummary summary;

  @override
  Widget build(BuildContext context) {
    final values = <(String, String)>[
      ('Current Balance', _currency(summary.balance)),
      ('Total Income', _currency(summary.totalIncome)),
      ('Total Expense', _currency(summary.totalExpense)),
      ('Transaction Count', summary.transactionCount.toString()),
      ('Highest Income', _currency(summary.highestIncome)),
      ('Highest Expense', _currency(summary.highestExpense)),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Overall Summary', style: context.text.titleLarge),
            const SizedBox(height: AppSpacing.md),
            ...values.map(
              (value) => Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.compact,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(child: Text(value.$1)),
                    Text(
                      value.$2,
                      style: context.text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _currency(double value) => '₹${value.toStringAsFixed(0)}';
}
