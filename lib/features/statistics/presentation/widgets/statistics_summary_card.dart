import 'package:akm_finance_manager/core/theme/app_icons.dart';
import 'package:akm_finance_manager/core/theme/app_spacing.dart';
import 'package:akm_finance_manager/core/theme/theme_context_extensions.dart';
import 'package:akm_finance_manager/models/statistics_summary.dart';
import 'package:flutter/material.dart';

class StatisticsSummaryCard extends StatelessWidget {
  const StatisticsSummaryCard({required this.summary, super.key});

  final StatisticsSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text('Overall Summary', style: context.text.titleLarge),
                ),
                Icon(AppIcons.wallet, color: context.colors.secondary),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Current Balance',
              style: context.text.titleSmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _currency(summary.balance),
              style: context.text.headlineMedium?.copyWith(
                color: context.colors.primary,
              ),
            ),
            const Divider(height: AppSpacing.xxl),
            Row(
              children: <Widget>[
                Expanded(
                  child: _SummaryMetric(
                    label: 'Total Income',
                    value: _currency(summary.totalIncome),
                    valueColor: context.semantic.success,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: _SummaryMetric(
                    label: 'Total Expense',
                    value: _currency(summary.totalExpense),
                    valueColor: context.colors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: <Widget>[
                Expanded(
                  child: _SummaryMetric(
                    label: 'Transactions',
                    value: summary.transactionCount.toString(),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: _SummaryMetric(
                    label: 'Highest Income',
                    value: _currency(summary.highestIncome),
                    valueColor: context.semantic.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            _SummaryMetric(
              label: 'Highest Expense',
              value: _currency(summary.highestExpense),
              valueColor: context.colors.error,
            ),
          ],
        ),
      ),
    );
  }

  String _currency(double value) => '₹${value.toStringAsFixed(0)}';
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: context.text.labelLarge?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: context.text.titleMedium?.copyWith(color: valueColor),
        ),
      ],
    );
  }
}
