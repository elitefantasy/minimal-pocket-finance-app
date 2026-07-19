import 'package:akm_finance_manager/core/notifications/app_snackbar_service.dart';
import 'package:akm_finance_manager/core/theme/app_icons.dart';
import 'package:akm_finance_manager/core/theme/app_spacing.dart';
import 'package:akm_finance_manager/core/theme/theme_context_extensions.dart';
import 'package:akm_finance_manager/features/categories/application/category_notifier.dart';
import 'package:akm_finance_manager/features/recurring/application/recurring_notifier.dart';
import 'package:akm_finance_manager/features/recurring/presentation/widgets/recurring_transaction_card.dart';
import 'package:akm_finance_manager/features/recurring/presentation/widgets/recurring_transaction_dialog.dart';
import 'package:akm_finance_manager/models/category.dart';
import 'package:akm_finance_manager/models/recurring_transaction.dart';
import 'package:akm_finance_manager/shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringAsync = ref.watch(recurringNotifierProvider);
    final categoriesAsync = ref.watch(categoryNotifierProvider);
    final categories = categoriesAsync.asData?.value;

    return AppScaffold(
      title: 'Recurring Transactions',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: categories == null
            ? null
            : () => _showEditor(context, ref, categories),
        icon: const Icon(AppIcons.add),
        label: const Text('Add Recurring'),
      ),
      body: recurringAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text(error.toString())),
        data: (recurringTransactions) {
          if (recurringTransactions.isEmpty) {
            return const _RecurringEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.page),
            itemCount: recurringTransactions.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final recurring = recurringTransactions[index];
              return RecurringTransactionCard(
                recurring: recurring,
                onTap: categories == null
                    ? null
                    : () => _showEditor(context, ref, categories, recurring),
                onEdit: categories == null
                    ? () {}
                    : () => _showEditor(context, ref, categories, recurring),
                onDelete: () => _delete(context, ref, recurring),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showEditor(
    BuildContext context,
    WidgetRef ref,
    List<Category> categories, [
    RecurringTransaction? recurring,
  ]) async {
    final result = await showDialog<RecurringTransaction>(
      context: context,
      builder: (context) => RecurringTransactionDialog(
        categories: categories,
        recurring: recurring,
      ),
    );
    if (result == null || !context.mounted) {
      return;
    }

    try {
      final notifier = ref.read(recurringNotifierProvider.notifier);
      if (recurring == null) {
        await notifier.addRecurring(result);
        ref
            .read(appSnackbarProvider)
            .showSuccess('Recurring transaction created.');
      } else {
        await notifier.updateRecurring(result);
        ref
            .read(appSnackbarProvider)
            .showSuccess('Recurring transaction updated.');
      }
    } on Object catch (error) {
      if (context.mounted) {
        ref
            .read(appSnackbarProvider)
            .showError('Unable to save recurring transaction: $error');
      }
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    RecurringTransaction recurring,
  ) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => _DeleteRecurringDialog(
            category: recurring.category,
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) {
      return;
    }

    try {
      await ref
          .read(recurringNotifierProvider.notifier)
          .deleteRecurring(recurring.id!);
      ref
          .read(appSnackbarProvider)
          .showSuccess('Recurring transaction deleted.');
    } on Object catch (error) {
      if (context.mounted) {
        ref
            .read(appSnackbarProvider)
            .showError('Unable to delete recurring transaction: $error');
      }
    }
  }
}

class _RecurringEmptyState extends StatelessWidget {
  const _RecurringEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              AppIcons.repeat,
              size: AppIcons.largeSize,
              color: context.colors.secondary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('No recurring transactions', style: context.text.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Create one to keep regular income and expenses on schedule.',
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteRecurringDialog extends StatelessWidget {
  const _DeleteRecurringDialog({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: <Widget>[
          Icon(AppIcons.delete, color: context.colors.error),
          const SizedBox(width: AppSpacing.sm),
          Text('Delete recurring transaction?', style: context.text.titleLarge),
        ],
      ),
      content: Text(
        'Delete the recurring transaction for "$category"? This cannot be undone.',
        style: context.text.bodyMedium,
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: context.colors.error,
            foregroundColor: context.colors.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
