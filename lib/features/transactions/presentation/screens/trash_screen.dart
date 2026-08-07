import 'package:minimal_pocket_finance_app/core/notifications/app_snackbar_service.dart';
import 'package:minimal_pocket_finance_app/core/theme/app_icons.dart';
import 'package:minimal_pocket_finance_app/core/theme/app_spacing.dart';
import 'package:minimal_pocket_finance_app/core/theme/theme_context_extensions.dart';
import 'package:minimal_pocket_finance_app/features/transactions/application/trash_transactions_provider.dart';
import 'package:minimal_pocket_finance_app/features/transactions/application/transaction_notifier.dart';
import 'package:minimal_pocket_finance_app/models/transaction.dart';
import 'package:minimal_pocket_finance_app/shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trashedAsync = ref.watch(trashTransactionsProvider);
    final transactions = trashedAsync.asData?.value ?? const <Transaction>[];

    return AppScaffold(
      title: 'Trash Bin',
      actions: transactions.isEmpty
          ? null
          : <Widget>[
              IconButton(
                onPressed: () => _emptyTrash(context, ref),
                icon: const Icon(AppIcons.clear),
                tooltip: 'Empty Trash',
              ),
            ],
      body: trashedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text(error.toString())),
        data: (transactions) {
          if (transactions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.page),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      AppIcons.trash,
                      size: AppIcons.largeSize * 2,
                      color: context.colors.onSurfaceVariant,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text('Trash Bin is empty', style: context.text.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Deleted transactions are kept here for 30 days.',
                      textAlign: TextAlign.center,
                      style: context.text.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.page),
            itemCount: transactions.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) => _TrashTransactionTile(
              transaction: transactions[index],
              onRestore: () => _restore(context, ref, transactions[index]),
              onDeletePermanently: () =>
                  _permanentlyDelete(context, ref, transactions[index]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    Transaction transaction,
  ) async {
    final id = transaction.id;
    if (id == null) {
      return;
    }
    await ref
        .read(transactionNotifierProvider.notifier)
        .restoreDeletedTransaction(id);
    ref.read(appSnackbarProvider).showSuccess('Transaction restored.');
  }

  Future<void> _permanentlyDelete(
    BuildContext context,
    WidgetRef ref,
    Transaction transaction,
  ) async {
    final confirmed = await _confirm(
      context,
      title: 'Delete permanently?',
      message: 'This transaction cannot be recovered.',
      actionLabel: 'Delete permanently',
    );
    final id = transaction.id;
    if (!confirmed || id == null) {
      return;
    }
    await ref
        .read(transactionNotifierProvider.notifier)
        .permanentlyDeleteTransaction(id);
    ref.read(appSnackbarProvider).showSuccess('Transaction permanently deleted.');
  }

  Future<void> _emptyTrash(BuildContext context, WidgetRef ref) async {
    final confirmed = await _confirm(
      context,
      title: 'Empty Trash?',
      message: 'All trashed transactions will be permanently deleted.',
      actionLabel: 'Empty Trash',
    );
    if (!confirmed) {
      return;
    }
    await ref.read(transactionNotifierProvider.notifier).emptyTrash();
    ref.read(appSnackbarProvider).showSuccess('Trash Bin emptied.');
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String actionLabel,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: context.colors.error,
                  foregroundColor: context.colors.onError,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(actionLabel),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _TrashTransactionTile extends StatelessWidget {
  const _TrashTransactionTile({
    required this.transaction,
    required this.onRestore,
    required this.onDeletePermanently,
  });

  final Transaction transaction;
  final VoidCallback onRestore;
  final VoidCallback onDeletePermanently;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'Income';
    final amountPrefix = isIncome ? '+' : '-';
    final transactionDate = transaction.date;
    final deletedAt = transaction.deletedAt;
    final deletedLabel = deletedAt == null
        ? ''
        : 'Deleted ${deletedAt.day}/${deletedAt.month}/${deletedAt.year}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Icon(
              isIncome ? AppIcons.income : AppIcons.expense,
              color: isIncome ? context.semantic.success : context.colors.error,
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
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${transactionDate.day}/${transactionDate.month}/${transactionDate.year}'
                    '${transaction.note.isEmpty ? '' : ' • ${transaction.note}'}'
                    '${deletedLabel.isEmpty ? '' : '\n$deletedLabel'}',
                    style: context.text.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  '$amountPrefix₹${transaction.amount.toStringAsFixed(0)}',
                  style: context.text.titleMedium?.copyWith(
                    color: isIncome ? context.semantic.success : context.colors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                      onPressed: onRestore,
                      icon: const Icon(AppIcons.restore),
                      tooltip: 'Restore',
                    ),
                    IconButton(
                      onPressed: onDeletePermanently,
                      icon: const Icon(AppIcons.delete),
                      tooltip: 'Delete permanently',
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
}
