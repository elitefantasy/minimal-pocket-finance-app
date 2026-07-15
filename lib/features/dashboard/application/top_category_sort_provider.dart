import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TopCategorySort { monthlyAverage, totalExpense }

final topCategorySortProvider = StateProvider<TopCategorySort>(
  (ref) => TopCategorySort.monthlyAverage,
);
