import 'package:flutter/material.dart';
import 'package:akm_finance_manager/core/theme/app_icons.dart';
import 'package:akm_finance_manager/core/theme/app_spacing.dart';
import 'package:akm_finance_manager/core/theme/theme_context_extensions.dart';

class DatabaseTile extends StatelessWidget {
  const DatabaseTile({
    required this.databaseName,
    required this.isActive,
    required this.onSelect,
    required this.onRename,
    required this.onDelete,
    super.key,
  });

  final String databaseName;
  final bool isActive;
  final VoidCallback onSelect;
  final VoidCallback onRename;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.card,
        vertical: AppSpacing.xs,
      ),
      leading: Icon(
        isActive ? AppIcons.check : AppIcons.database,
        color: isActive ? context.semantic.success : context.colors.secondary,
      ),
      title: Text(databaseName, style: context.text.titleMedium),
      subtitle: isActive
          ? Text(
              'Active',
              style: context.text.bodyMedium?.copyWith(
                color: context.semantic.success,
              ),
            )
          : null,
      onTap: isActive ? null : onSelect,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            onPressed: onRename,
            icon: const Icon(AppIcons.edit),
            tooltip: 'Rename $databaseName',
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(AppIcons.delete, color: context.colors.error),
            tooltip: 'Delete $databaseName',
          ),
        ],
      ),
    );
  }
}
