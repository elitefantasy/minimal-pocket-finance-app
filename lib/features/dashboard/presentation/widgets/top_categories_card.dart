import 'package:minimal_pocket_finance_app/models/dashboard_summary.dart';
import 'package:minimal_pocket_finance_app/core/theme/app_icons.dart';
import 'package:minimal_pocket_finance_app/core/theme/app_spacing.dart';
import 'package:minimal_pocket_finance_app/core/theme/theme_context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minimal_pocket_finance_app/features/dashboard/application/top_category_sort_provider.dart';

/// A card that displays a list of top spending categories.
/// Includes a dropdown option to sort categories by monthly average or total expense.
class TopCategoriesCard extends ConsumerWidget {
  const TopCategoriesCard({
    super.key,
    required this.categories,
    this.onCategoryTap,
  });

  final List<TopCategorySummary> categories;
  final ValueChanged<TopCategorySummary>? onCategoryTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the current sort state from Riverpod to update the UI dynamically
    final sortMode = ref.watch(topCategorySortProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row containing the title and the sort menu button
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Top Categories',
                    style: context.text.titleMedium,
                  ),
                ),
                PopupMenuButton<TopCategorySort>(
                  initialValue: sortMode,
                  tooltip: 'Sort categories',
                  // Dynamically change the trailing icon based on current sort mode
                  icon: Icon(switch (sortMode) {
                    TopCategorySort.monthlyAverage => AppIcons.calendarMonth,
                    TopCategorySort.totalExpense => AppIcons.currency,
                  }),
                  // Update the Riverpod provider state when a new sort method is selected
                  onSelected: (value) {
                    ref.read(topCategorySortProvider.notifier).state = value;
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: TopCategorySort.monthlyAverage,
                      child: Row(
                        children: [
                          Icon(AppIcons.calendarMonth),
                          SizedBox(width: AppSpacing.md),
                          Text('Monthly Average'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: TopCategorySort.totalExpense,
                      child: Row(
                        children: [
                          Icon(AppIcons.currency),
                          SizedBox(width: AppSpacing.md),
                          Text('Total Expense'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Conditional rendering: Show a fallback message if no data exists,
            // otherwise list out the categories.
            if (categories.isEmpty)
              const Text('No expense data')
            else
              ...categories.map(
                (category) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    AppIcons.category,
                    color: context.colors.secondary,
                  ),
                  title: Text(category.name),
                  onTap: onCategoryTap == null
                      ? null
                      : () => onCategoryTap!(category),
                  mouseCursor: onCategoryTap == null
                      ? MouseCursor.defer
                      : SystemMouseCursors.click,
                  subtitle: Text(
                    'Monthly Average: ₹${category.monthlyAverage.toStringAsFixed(0)}',
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
