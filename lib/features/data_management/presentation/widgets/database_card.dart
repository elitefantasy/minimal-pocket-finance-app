import 'package:flutter/material.dart';
import 'package:akm_finance_manager/core/theme/app_icons.dart';

class DatabaseCard extends StatelessWidget {
  const DatabaseCard({required this.databaseName, super.key});

  final String databaseName;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(AppIcons.database),
        title: const Text('Current Database'),
        subtitle: Text(databaseName),
      ),
    );
  }
}
