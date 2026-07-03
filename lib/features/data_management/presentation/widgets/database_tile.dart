import 'package:flutter/material.dart';

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
      leading: Icon(isActive ? Icons.check_circle : Icons.storage_outlined),
      title: Text(databaseName),
      subtitle: isActive ? const Text('Active') : null,
      onTap: isActive ? null : onSelect,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            onPressed: onRename,
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Rename',
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}
