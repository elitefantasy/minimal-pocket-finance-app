import 'package:akm_finance_manager/core/theme/app_icons.dart';
import 'package:akm_finance_manager/core/theme/app_radius.dart';
import 'package:akm_finance_manager/core/theme/app_shadows.dart';
import 'package:akm_finance_manager/core/theme/app_spacing.dart';
import 'package:akm_finance_manager/core/theme/theme_context_extensions.dart';
import 'package:flutter/material.dart';

enum SummaryCardTone { balance, income, expense }

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    this.tone = SummaryCardTone.balance,
    this.onTap,
  });

  final String title;
  final String value;
  final SummaryCardTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isBalance = tone == SummaryCardTone.balance;
    final accentColor = switch (tone) {
      SummaryCardTone.income => context.semantic.success,
      SummaryCardTone.expense => context.colors.error,
      SummaryCardTone.balance => context.colors.onPrimary,
    };
    final content = Padding(
      padding: EdgeInsets.all(isBalance ? AppSpacing.xxl : AppSpacing.card),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isBalance)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Icon(
                tone == SummaryCardTone.income
                    ? AppIcons.income
                    : AppIcons.expense,
                color: accentColor,
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      (isBalance
                              ? context.text.titleSmall
                              : context.text.titleMedium)
                          ?.copyWith(color: isBalance ? accentColor : null),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  value,
                  style:
                      (isBalance
                              ? context.text.displaySmall
                              : context.text.headlineMedium)
                          ?.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                ),
              ],
            ),
          ),
          if (isBalance)
            Icon(AppIcons.wallet, color: accentColor, size: AppIcons.largeSize),
        ],
      ),
    );

    if (isBalance) {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: context.gradients.primary,
          borderRadius: AppRadius.extraLarge,
          boxShadow: AppShadows.soft,
        ),
        child: content,
      );
    }

    return Card(
      child: InkWell(
        onTap: onTap,
        mouseCursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
        borderRadius: AppRadius.large,
        child: content,
      ),
    );
  }
}
