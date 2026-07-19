import 'package:akm_finance_manager/core/theme/app_icons.dart';
import 'package:akm_finance_manager/core/theme/app_radius.dart';
import 'package:akm_finance_manager/core/theme/app_spacing.dart';
import 'package:akm_finance_manager/core/theme/theme_context_extensions.dart';
import 'package:akm_finance_manager/models/recurring_transaction.dart';
import 'package:flutter/material.dart';

class RecurringTransactionCard extends StatelessWidget {
  const RecurringTransactionCard({
    required this.recurring,
    required this.onEdit,
    required this.onDelete,
    this.onTap,
    super.key,
  });

  final RecurringTransaction recurring;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isIncome = recurring.type == 'Income';
    final amountColor = isIncome
        ? context.semantic.success
        : context.colors.error;
    final lastProcessedDate = recurring.lastProcessedDate;
    final lastProcessed = lastProcessedDate == null
        ? 'Not processed yet'
        : '${lastProcessedDate.day}/${lastProcessedDate.month}/${lastProcessedDate.year}';
    final statusColor = recurring.isEnabled
        ? context.semantic.success
        : context.colors.onSurfaceVariant;

    return Card(
      child: InkWell(
        onTap: onTap,
        mouseCursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
        child: Padding(
        padding: const EdgeInsets.all(AppSpacing.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  isIncome ? AppIcons.income : AppIcons.expense,
                  color: amountColor,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    recurring.category,
                    style: context.text.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(AppIcons.edit),
                  tooltip: 'Edit ${recurring.category}',
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(AppIcons.delete, color: context.colors.error),
                  tooltip: 'Delete ${recurring.category}',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${isIncome ? '+' : '-'}₹${recurring.amount.toStringAsFixed(0)}',
              style: context.text.headlineSmall?.copyWith(color: amountColor),
            ),
            if (recurring.note.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.xs),
              Text(
                recurring.note,
                style: context.text.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                Chip(
                  avatar: Icon(
                    AppIcons.repeat,
                    size: AppIcons.smallSize,
                    color: context.colors.secondary,
                  ),
                  label: Text('Day ${recurring.dayOfMonth} each month'),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.pill,
                  ),
                ),
                Chip(
                  label: Text(recurring.isEnabled ? 'Enabled' : 'Disabled'),
                  backgroundColor: statusColor.withValues(alpha: 0.12),
                  labelStyle: context.text.labelLarge?.copyWith(
                    color: statusColor,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.pill,
                  ),
                ),
              ],
            ),
            const Divider(height: AppSpacing.xxl),
            Row(
              children: <Widget>[
                Icon(
                  AppIcons.calendar,
                  size: AppIcons.smallSize,
                  color: context.colors.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Last processed: $lastProcessed',
                    style: context.text.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
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
