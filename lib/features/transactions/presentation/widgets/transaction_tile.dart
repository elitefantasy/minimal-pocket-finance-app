import 'package:minimal_pocket_finance_app/core/notifications/app_snackbar_service.dart';
import 'package:minimal_pocket_finance_app/core/theme/app_icons.dart';
import 'package:minimal_pocket_finance_app/core/theme/app_radius.dart';
import 'package:minimal_pocket_finance_app/core/theme/app_spacing.dart';
import 'package:minimal_pocket_finance_app/core/theme/theme_context_extensions.dart';
import 'package:minimal_pocket_finance_app/features/attachments/presentation/widgets/attachment_viewer_dialog.dart';
import 'package:minimal_pocket_finance_app/features/transactions/application/transaction_notifier.dart';
import 'package:minimal_pocket_finance_app/models/transaction.dart';
import 'package:minimal_pocket_finance_app/shared/widgets/delete_confirmation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TransactionTile extends ConsumerWidget {
  const TransactionTile({required this.transaction, super.key});

  final Transaction transaction;

  void _openAttachments(BuildContext context) {
    if (transaction.attachments.isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (context) => AttachmentViewerDialog(
        attachments: transaction.attachments,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = transaction.date;
    final formattedDate = '${date.day}/${date.month}/${date.year}';
    final amountPrefix = transaction.type == 'Income' ? '+' : '-';
    final formattedAmount =
        '$amountPrefix₹${transaction.amount.toStringAsFixed(0)}';

    final isIncome = transaction.type == 'Income';
    final amountColor = isIncome
        ? context.semantic.success
        : context.colors.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              isIncome ? AppIcons.income : AppIcons.expense,
              color: amountColor,
              size: AppIcons.mediumSize,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    transaction.category,
                    style: context.text.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (transaction.note.isNotEmpty) ...<Widget>[
                    const SizedBox(height: AppSpacing.compact),
                    Text(
                      transaction.note,
                      style: context.text.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    formattedDate,
                    style: context.text.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  if (transaction.isRecurring || transaction.hasAttachments) ...<Widget>[
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: <Widget>[
                        if (transaction.isRecurring)
                          Chip(
                            avatar: Icon(
                              AppIcons.repeat,
                              size: AppIcons.smallSize,
                              color: context.colors.secondary,
                            ),
                            label: const Text('Recurring'),
                            shape: const RoundedRectangleBorder(
                              borderRadius: AppRadius.pill,
                            ),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            labelStyle: context.text.labelSmall,
                            padding: EdgeInsets.zero,
                          ),
                        if (transaction.hasAttachments)
                          ActionChip(
                            avatar: const Icon(
                              Icons.attach_file,
                              size: AppIcons.smallSize,
                            ),
                            label: Text(
                              '${transaction.attachments.length} file${transaction.attachments.length > 1 ? 's' : ''}',
                            ),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            labelStyle: context.text.labelSmall,
                            padding: EdgeInsets.zero,
                            onPressed: () => _openAttachments(context),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  formattedAmount,
                  style: context.text.titleLarge?.copyWith(
                    color: amountColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                      onPressed: () =>
                          context.push('/edit', extra: transaction),
                      icon: const Icon(AppIcons.edit),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      onPressed: transaction.id == null
                          ? null
                          : () => _deleteTransaction(context, ref),
                      icon: const Icon(AppIcons.delete),
                      tooltip: 'Move to Trash',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteTransaction(BuildContext context, WidgetRef ref) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => const DeleteConfirmationDialog(),
        ) ??
        false;
    if (!confirmed || !context.mounted) {
      return;
    }

    // Read dependencies before this widget gets disposed.
    final transactionNotifier = ref.read(transactionNotifierProvider.notifier);
    final snackbarService = ref.read(appSnackbarProvider);

    await transactionNotifier.deleteTransaction(transaction.id!);

    snackbarService.showUndo(
      message: 'Transaction moved to Trash',
      onUndo: () async {
        await transactionNotifier.restoreDeletedTransaction(transaction.id!);
      },
    );
  }
}
