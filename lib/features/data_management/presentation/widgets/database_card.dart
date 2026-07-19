import 'package:flutter/material.dart';
import 'package:akm_finance_manager/core/theme/app_icons.dart';
import 'package:akm_finance_manager/core/theme/app_spacing.dart';
import 'package:akm_finance_manager/core/theme/theme_context_extensions.dart';

class DatabaseCard extends StatelessWidget {
  const DatabaseCard({required this.databaseName, super.key});

  final String databaseName;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.card,
          vertical: AppSpacing.xs,
        ),
        leading: const Icon(AppIcons.database),
        title: Text('Current Database', style: context.text.titleMedium),
        subtitle: Text(
          databaseName,
          style: context.text.bodyMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
