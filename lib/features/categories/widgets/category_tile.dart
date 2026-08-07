import 'package:minimal_pocket_finance_app/core/theme/app_icons.dart';
import 'package:minimal_pocket_finance_app/core/theme/app_spacing.dart';
import 'package:minimal_pocket_finance_app/core/theme/theme_context_extensions.dart';
import 'package:minimal_pocket_finance_app/models/category.dart';
import 'package:flutter/material.dart';

class CategoryTile extends StatelessWidget {
  const CategoryTile({
    required this.category,
    required this.onEdit,
    required this.onDelete,
    this.onTap,
    super.key,
  });

  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

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
        onTap: onTap,
        mouseCursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
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
