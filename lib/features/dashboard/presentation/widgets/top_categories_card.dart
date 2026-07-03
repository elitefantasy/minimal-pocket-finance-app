import 'package:akm_finance_manager/models/dashboard_summary.dart';
import 'package:flutter/material.dart';

class TopCategoriesCard extends StatelessWidget {
  const TopCategoriesCard({super.key, required this.categories});

  final List<TopCategorySummary> categories;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Categories',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: 12),

            if (categories.isEmpty)
              const Text('No expense data')
            else
              ...categories.map(
                (category) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(category.name),
                  subtitle: Text(
                    'Monthly Average: '
                    '₹${category.monthlyAverage.toStringAsFixed(0)}',
                  ),
                  trailing: Text(
                    'Total: ₹${category.totalExpense.toStringAsFixed(0)}',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
