import 'package:akm_finance_manager/models/category.dart';
import 'package:akm_finance_manager/core/theme/app_icons.dart';
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
    return ListTile(
      title: Text(category.name),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            onPressed: onEdit,
            icon: const Icon(AppIcons.edit),
            tooltip: 'Edit',
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
