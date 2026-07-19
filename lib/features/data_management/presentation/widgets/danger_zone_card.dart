import 'package:flutter/material.dart';
import 'package:akm_finance_manager/core/theme/app_icons.dart';
import 'package:akm_finance_manager/core/theme/app_spacing.dart';
import 'package:akm_finance_manager/core/theme/theme_context_extensions.dart';

class DangerZoneCard extends StatelessWidget {
  const DangerZoneCard({required this.onClearTransactions, super.key});

  final VoidCallback onClearTransactions;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(AppIcons.delete, color: context.colors.error),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Danger Zone',
                  style: context.text.titleMedium?.copyWith(
                    color: context.colors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Delete all transactions while keeping categories, recurring '
              'transactions, and the database file.',
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const Divider(height: AppSpacing.xxl),
            FilledButton.icon(
              onPressed: onClearTransactions,
              icon: const Icon(AppIcons.clear),
              label: const Text('Clear All Transactions'),
              style: FilledButton.styleFrom(
                backgroundColor: context.colors.error,
                foregroundColor: context.colors.onError,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
