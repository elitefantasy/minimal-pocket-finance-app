import 'package:akm_finance_manager/models/statistics_summary.dart';
import 'package:akm_finance_manager/core/theme/theme_context_extensions.dart';
import 'package:flutter/material.dart';

class CategoryStatisticsTile extends StatelessWidget {
  const CategoryStatisticsTile({required this.statistics, super.key});

  final CategoryStatistics statistics;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(statistics.name),
        subtitle: Text(
          'Months Appeared: ${statistics.monthsAppeared}\n'
          'Average Per Month: '
          '₹${statistics.averagePerMonth.toStringAsFixed(0)}',
        ),
        trailing: Text(
          '₹${statistics.totalExpense.toStringAsFixed(0)}',
          style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
