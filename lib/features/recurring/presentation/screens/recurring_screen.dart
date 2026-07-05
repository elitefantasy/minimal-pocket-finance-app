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
        icon: const Icon(Icons.add),
        label: const Text('Add Recurring'),
      ),
      body: recurringAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text(error.toString())),
        data: (recurringTransactions) {
          if (recurringTransactions.isEmpty) {
            return const Center(child: Text('No recurring transactions yet'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: recurringTransactions.length,
            itemBuilder: (context, index) {
              final recurring = recurringTransactions[index];
              return RecurringTransactionCard(
                recurring: recurring,
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
      } else {
        await notifier.updateRecurring(result);
      }
    } on Object catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to save recurring transaction: $error'),
          ),
        );
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
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete Recurring Transaction?'),
            content: const Text(
              'Are you sure you want to delete this recurring transaction?',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Delete'),
              ),
            ],
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
    } on Object catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to delete recurring transaction: $error'),
          ),
        );
      }
    }
  }
}
