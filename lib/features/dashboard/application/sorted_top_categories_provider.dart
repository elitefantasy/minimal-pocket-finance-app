import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashboard_summary_provider.dart';
import 'top_category_sort_provider.dart';
import 'package:akm_finance_manager/models/dashboard_summary.dart';

final sortedTopCategoriesProvider =
    Provider<AsyncValue<List<TopCategorySummary>>>((ref) {
  final summaryAsync = ref.watch(dashboardSummaryProvider);
  final sortMode = ref.watch(topCategorySortProvider);

  return summaryAsync.whenData((summary) {
    final categories = List<TopCategorySummary>.of(summary.topCategories);

    switch (sortMode) {
      case TopCategorySort.monthlyAverage:
        categories.sort(
          (a, b) =>
              b.monthlyAverage.compareTo(a.monthlyAverage),
        );
        break;

      case TopCategorySort.totalExpense:
        categories.sort(
          (a, b) =>
              b.totalExpense.compareTo(a.totalExpense),
        );
        break;
    }

    return categories;
  });
});