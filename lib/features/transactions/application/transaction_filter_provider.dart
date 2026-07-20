import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TransactionFilter { all, income, expense }

@immutable
class HistoryFilters {
  const HistoryFilters({
    this.transactionType = TransactionFilter.all,
    this.category,
    this.month,
    this.year,
    this.isRecurring,
  });

  final TransactionFilter transactionType;
  final String? category;
  final int? month;
  final int? year;
  final bool? isRecurring;

  bool get hasDrillDownFilter =>
      category != null || month != null || year != null || isRecurring != null;

  bool get hasActiveFilter =>
      transactionType != TransactionFilter.all || hasDrillDownFilter;

  HistoryFilters copyWith({
    TransactionFilter? transactionType,
    String? category,
    int? month,
    int? year,
    bool? isRecurring,
  }) {
    return HistoryFilters(
      transactionType: transactionType ?? this.transactionType,
      category: category ?? this.category,
      month: month ?? this.month,
      year: year ?? this.year,
      isRecurring: isRecurring ?? this.isRecurring,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is HistoryFilters &&
        other.transactionType == transactionType &&
        other.category == category &&
        other.month == month &&
        other.year == year &&
        other.isRecurring == isRecurring;
  }

  @override
  int get hashCode => Object.hash(transactionType, category, month, year, isRecurring);
}

final historyFiltersProvider = StateProvider<HistoryFilters>(
  (ref) => const HistoryFilters(),
);
