import 'package:akm_finance_manager/core/notifications/app_snackbar_service.dart';
import 'package:akm_finance_manager/features/transactions/application/transaction_notifier.dart';
import 'package:akm_finance_manager/models/transaction.dart';
import 'package:akm_finance_manager/shared/widgets/delete_confirmation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TransactionTile extends ConsumerWidget {
  const TransactionTile({required this.transaction, super.key});

  final Transaction transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = transaction.date;
    final formattedDate = '${date.day}/${date.month}/${date.year}';
    final amountPrefix = transaction.type == 'Income' ? '+' : '-';
    final formattedAmount =
        '$amountPrefix₹${transaction.amount.toStringAsFixed(0)}';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    transaction.category,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (transaction.note.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(transaction.note),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (transaction.isRecurring) ...<Widget>[
                    const SizedBox(height: 6),
                    Chip(
                      avatar: const Icon(Icons.repeat, size: 14),
                      label: const Text('Monthly'),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      labelStyle: Theme.of(context).textTheme.labelSmall,
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(formattedAmount),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                      onPressed: () =>
                          context.push('/edit', extra: transaction),
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      onPressed: transaction.id == null
                          ? null
                          : () => _deleteTransaction(context, ref),
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete',
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
      message: 'Transaction deleted',
      onUndo: () async {
        await transactionNotifier.restoreDeletedTransaction(transaction);
      },
    );
  }
}
