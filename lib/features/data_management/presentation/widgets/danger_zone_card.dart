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
      color: context.colors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('Danger Zone', style: context.text.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Delete all transactions while keeping categories, recurring '
              'transactions, and the database file.',
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onClearTransactions,
              icon: const Icon(AppIcons.clear),
              label: const Text('Clear All Transactions'),
            ),
          ],
        ),
      ),
    );
  }
}
