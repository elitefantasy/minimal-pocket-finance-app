import 'package:akm_finance_manager/core/theme/app_icons.dart';
import 'package:akm_finance_manager/core/theme/app_spacing.dart';
import 'package:akm_finance_manager/core/theme/theme_context_extensions.dart';
import 'package:flutter/material.dart';

class MonthlyExpenseCard extends StatelessWidget {
  const MonthlyExpenseCard({
    super.key,
    required this.title,
    required this.amount,
    this.icon = AppIcons.calendarMonth,
    this.onTap,
  });

  final String amount;
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        mouseCursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
        child: Padding(
        padding: const EdgeInsets.all(AppSpacing.card),
        child: Row(
          children: [
            Icon(icon, color: context.colors.tertiary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.text.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    amount,
                    style: context.text.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
