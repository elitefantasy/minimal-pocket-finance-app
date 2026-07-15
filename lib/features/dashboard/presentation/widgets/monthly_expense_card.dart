import 'package:akm_finance_manager/core/theme/app_spacing.dart';
import 'package:akm_finance_manager/core/theme/theme_context_extensions.dart';
import 'package:flutter/material.dart';

class MonthlyExpenseCard extends StatelessWidget {
  const MonthlyExpenseCard({
    super.key,
    required this.title,
    required this.amount,
  });

  final String amount;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: context.text.titleMedium),

            const SizedBox(height: AppSpacing.md),

            Text(amount, style: context.text.headlineMedium),
          ],
        ),
      ),
    );
  }
}
