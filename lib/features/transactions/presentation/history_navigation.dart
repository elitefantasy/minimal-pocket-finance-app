import 'package:akm_finance_manager/features/transactions/application/transaction_filter_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

abstract final class HistoryNavigation {
  static void open(
    BuildContext context, {
    String? category,
    TransactionFilter transactionType = TransactionFilter.all,
    DateTime? month,
    bool? isRecurring,
  }) {
    final queryParameters = <String, String>{
      'category': ?category,
      if (transactionType != TransactionFilter.all)
        'type': transactionType.name,
      'month': ?month?.month.toString(),
      'year': ?month?.year.toString(),
      'recurring': ?isRecurring?.toString(),
    };
    context.go(Uri(path: '/history', queryParameters: queryParameters).toString());
  }
}
