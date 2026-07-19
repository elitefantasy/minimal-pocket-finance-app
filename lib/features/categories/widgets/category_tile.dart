import 'package:akm_finance_manager/core/theme/app_icons.dart';
import 'package:akm_finance_manager/core/theme/app_spacing.dart';
import 'package:akm_finance_manager/core/theme/theme_context_extensions.dart';
import 'package:akm_finance_manager/models/category.dart';
import 'package:flutter/material.dart';

class CategoryTile extends StatelessWidget {
  const CategoryTile({
    required this.category,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.card,
          vertical: AppSpacing.xs,
        ),
        leading: Icon(AppIcons.category, color: context.colors.secondary),
        title: Text(category.name, style: context.text.titleMedium),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              onPressed: onEdit,
              icon: const Icon(AppIcons.edit),
              tooltip: 'Rename ${category.name}',
            ),
            IconButton(
              onPressed: onDelete,
              icon: Icon(AppIcons.delete, color: context.colors.error),
              tooltip: 'Delete ${category.name}',
            ),
          ],
        ),
      ),
    );
  }
}
