import 'package:flutter/material.dart';

class DangerZoneCard extends StatelessWidget {
  const DangerZoneCard({required this.onClearTransactions, super.key});

  final VoidCallback onClearTransactions;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('Danger Zone', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'Delete all transactions while keeping categories, recurring '
              'transactions, and the database file.',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onClearTransactions,
              icon: const Icon(Icons.delete_sweep_outlined),
              label: const Text('Clear All Transactions'),
            ),
          ],
        ),
      ),
    );
  }
}
