import 'package:akm_finance_manager/core/theme/app_icons.dart';
import 'package:akm_finance_manager/core/theme/app_spacing.dart';
import 'package:akm_finance_manager/core/theme/theme_context_extensions.dart';
import 'package:akm_finance_manager/models/statistics_summary.dart';
import 'package:flutter/material.dart';

class CategoryStatisticsTile extends StatelessWidget {
  const CategoryStatisticsTile({
    required this.statistics,
    this.onTap,
    super.key,
  });

  final CategoryStatistics statistics;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        mouseCursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
        child: Padding(
        padding: const EdgeInsets.all(AppSpacing.card),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(AppIcons.category, color: context.colors.secondary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(statistics.name, style: context.text.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Appeared in ${statistics.monthsAppeared} months',
                    style: context.text.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Average per month: '
                    '₹${statistics.averagePerMonth.toStringAsFixed(0)}',
                    style: context.text.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  'Total spent',
                  style: context.text.labelLarge?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '₹${statistics.totalExpense.toStringAsFixed(0)}',
                  style: context.text.titleMedium?.copyWith(
                    color: context.colors.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}
