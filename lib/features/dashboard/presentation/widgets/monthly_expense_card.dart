import 'package:flutter/material.dart';

class MonthlyExpenseCard extends StatelessWidget {
  const MonthlyExpenseCard({
    super.key,
    required this.amount,
  });

  final String amount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Month Expense',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: 12),

            Text(
              amount,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
    );
  }
}
