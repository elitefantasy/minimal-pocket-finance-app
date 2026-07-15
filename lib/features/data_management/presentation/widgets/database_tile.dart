import 'package:flutter/material.dart';
import 'package:akm_finance_manager/core/theme/app_icons.dart';

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
      leading: Icon(isActive ? AppIcons.check : AppIcons.database),
      title: Text(databaseName),
      subtitle: isActive ? const Text('Active') : null,
      onTap: isActive ? null : onSelect,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            onPressed: onRename,
            icon: const Icon(AppIcons.edit),
            tooltip: 'Rename',
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(AppIcons.delete),
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}
