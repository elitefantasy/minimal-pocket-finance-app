import 'package:akm_finance_manager/models/transaction.dart';
import 'package:flutter/material.dart';

class RecentTransactionsCard extends StatelessWidget {
  const RecentTransactionsCard({super.key, required this.transactions});

  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Transactions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (transactions.isEmpty)
              const Text('No transactions yet')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  final date = transaction.date;
                  final amountPrefix = transaction.type == 'Income' ? '+' : '-';

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(transaction.category),
                    subtitle: Text('${date.day}/${date.month}/${date.year}'),
                    trailing: Text(
                      '$amountPrefix₹${transaction.amount.toStringAsFixed(0)}',
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
