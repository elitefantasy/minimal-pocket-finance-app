import 'package:flutter/material.dart';

class DatabaseCard extends StatelessWidget {
  const DatabaseCard({required this.databaseName, super.key});

  final String databaseName;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.storage),
        title: const Text('Current Database'),
        subtitle: Text(databaseName),
      ),
    );
  }
}
