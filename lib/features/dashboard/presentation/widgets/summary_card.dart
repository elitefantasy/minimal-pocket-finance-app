import 'package:akm_finance_manager/core/theme/app_spacing.dart';
import 'package:akm_finance_manager/core/theme/theme_context_extensions.dart';
import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.card),
        child: Column(
          children: [
            Text(title, style: context.text.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(value, style: context.text.displaySmall),
          ],
        ),
      ),
    );
  }
}
