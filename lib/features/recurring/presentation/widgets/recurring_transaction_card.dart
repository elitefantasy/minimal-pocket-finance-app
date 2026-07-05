import 'package:akm_finance_manager/models/recurring_transaction.dart';
import 'package:flutter/material.dart';

class RecurringTransactionCard extends StatelessWidget {
  const RecurringTransactionCard({
    required this.recurring,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final RecurringTransaction recurring;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isIncome = recurring.type == 'Income';
    final lastProcessedDate = recurring.lastProcessedDate;
    final lastProcessed = lastProcessedDate == null
        ? 'Never'
        : '${lastProcessedDate.day}/${lastProcessedDate.month}/${lastProcessedDate.year}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    recurring.category,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${isIncome ? '+' : '-'}₹${recurring.amount.toStringAsFixed(0)}',
                  ),
                  if (recurring.note.isNotEmpty) Text(recurring.note),
                  const SizedBox(height: 8),
                  Text('Repeats every month on Day ${recurring.dayOfMonth}'),
                  Text(recurring.isEnabled ? 'Enabled' : 'Disabled'),
                  Text('Last processed: $lastProcessed'),
                ],
              ),
            ),
            Column(
              children: <Widget>[
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit',
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
