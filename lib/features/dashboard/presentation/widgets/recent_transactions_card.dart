import 'package:akm_finance_manager/models/transaction.dart';
import 'package:akm_finance_manager/core/theme/app_icons.dart';
import 'package:akm_finance_manager/core/theme/app_spacing.dart';
import 'package:akm_finance_manager/core/theme/theme_context_extensions.dart';
import 'package:flutter/material.dart';

class RecentTransactionsCard extends StatelessWidget {
  const RecentTransactionsCard({super.key, required this.transactions});

  final List<Transaction> transactions;

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
                    subtitle: Row(
                      children: [
                        Text('${date.day}/${date.month}/${date.year}'),
                        if (transaction.isRecurring) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Chip(
                            label: const Text('Monthly'),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
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
