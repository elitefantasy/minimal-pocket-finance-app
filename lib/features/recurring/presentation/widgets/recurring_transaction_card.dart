import 'package:akm_finance_manager/models/recurring_transaction.dart';
import 'package:akm_finance_manager/core/theme/app_icons.dart';
import 'package:akm_finance_manager/core/theme/app_spacing.dart';
import 'package:akm_finance_manager/core/theme/theme_context_extensions.dart';
import 'package:flutter/material.dart';

class RecurringTransactionCard extends StatelessWidget {
  const RecurringTransactionCard({
    required this.recurring,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final RecurringTransaction recurring;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isIncome = recurring.type == 'Income';
    final lastProcessedDate = recurring.lastProcessedDate;
    final lastProcessed = lastProcessedDate == null
        ? 'Never'
        : '${lastProcessedDate.day}/${lastProcessedDate.month}/${lastProcessedDate.year}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(isIncome ? AppIcons.income : AppIcons.expense),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(recurring.category, style: context.text.titleMedium),
                  Text(
                    '${isIncome ? '+' : '-'}₹${recurring.amount.toStringAsFixed(0)}',
                  ),
                  if (recurring.note.isNotEmpty) Text(recurring.note),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Repeats every month on Day ${recurring.dayOfMonth}'),
                  Text(recurring.isEnabled ? 'Enabled' : 'Disabled'),
                  Text('Last processed: $lastProcessed'),
                ],
              ),
            ),
            Column(
              children: <Widget>[
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(AppIcons.edit),
                  tooltip: 'Edit',
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(AppIcons.delete),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
