import 'package:minimal_pocket_finance_app/models/transaction.dart';
import 'package:minimal_pocket_finance_app/core/theme/app_icons.dart';
import 'package:minimal_pocket_finance_app/core/theme/app_radius.dart';
import 'package:minimal_pocket_finance_app/core/theme/app_spacing.dart';
import 'package:minimal_pocket_finance_app/core/theme/theme_context_extensions.dart';
import 'package:flutter/material.dart';

class RecentTransactionsCard extends StatelessWidget {
  const RecentTransactionsCard({
    super.key,
    required this.transactions,
    this.onTransactionTap,
  });

  final List<Transaction> transactions;
  final ValueChanged<Transaction>? onTransactionTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Transactions', style: context.text.titleMedium),
            const SizedBox(height: AppSpacing.md),
            if (transactions.isEmpty)
              const Text('No transactions yet')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  final date = transaction.date;
                  final amountPrefix = transaction.type == 'Income' ? '+' : '-';
                  final isIncome = transaction.type == 'Income';
                  final semanticColor = isIncome
                      ? context.semantic.success
                      : context.colors.error;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      isIncome ? AppIcons.income : AppIcons.expense,
                      color: semanticColor,
                    ),
                    title: Text(transaction.category),
                    onTap: onTransactionTap == null
                        ? null
                        : () => onTransactionTap!(transaction),
                    mouseCursor: onTransactionTap == null
                        ? MouseCursor.defer
                        : SystemMouseCursors.click,
                    subtitle: Row(
                      children: [
                        Text('${date.day}/${date.month}/${date.year}'),
                        if (transaction.isRecurring) ...[
                          const SizedBox(width: AppSpacing.sm),
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
                        ],
                      ],
                    ),
                    trailing: Text(
                      '$amountPrefix₹${transaction.amount.toStringAsFixed(0)}',
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
