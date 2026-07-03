import 'package:akm_finance_manager/models/statistics_summary.dart';
import 'package:flutter/material.dart';

class StatisticsSummaryCard extends StatelessWidget {
  const StatisticsSummaryCard({required this.summary, super.key});

  final StatisticsSummary summary;

  @override
  Widget build(BuildContext context) {
    final values = <(String, String)>[
      ('Current Balance', _currency(summary.balance)),
      ('Total Income', _currency(summary.totalIncome)),
      ('Total Expense', _currency(summary.totalExpense)),
      ('Transaction Count', summary.transactionCount.toString()),
      ('Highest Income', _currency(summary.highestIncome)),
      ('Highest Expense', _currency(summary.highestExpense)),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Overall Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ...values.map(
              (value) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: <Widget>[
                    Expanded(child: Text(value.$1)),
                    Text(
                      value.$2,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _currency(double value) => '₹${value.toStringAsFixed(0)}';
}
