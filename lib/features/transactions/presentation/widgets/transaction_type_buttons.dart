import 'package:flutter/material.dart';
import 'package:minimal_pocket_finance_app/core/theme/app_icons.dart';
import 'package:minimal_pocket_finance_app/core/theme/app_spacing.dart';
import 'package:minimal_pocket_finance_app/core/theme/theme_context_extensions.dart';

class TransactionTypeButtons extends StatelessWidget {
  const TransactionTypeButtons({
    required this.onIncome,
    required this.onExpense,
    this.isSaving = false,
    super.key,
  });

  final VoidCallback onIncome;
  final VoidCallback onExpense;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: FilledButton(
            onPressed: isSaving ? null : onIncome,
            style: FilledButton.styleFrom(
              backgroundColor: context.semantic.success,
              foregroundColor: context.colors.surface,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(AppIcons.income),
                SizedBox(width: AppSpacing.sm),
                Text('Income'),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: FilledButton(
            onPressed: isSaving ? null : onExpense,
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.error,
              foregroundColor: context.colors.onError,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(AppIcons.expense),
                SizedBox(width: AppSpacing.sm),
                Text('Expense'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
