import 'dart:math' as math;

import 'package:minimal_pocket_finance_app/models/recurring_transaction.dart';
import 'package:minimal_pocket_finance_app/models/transaction.dart';
import 'package:minimal_pocket_finance_app/repositories/recurring_repository.dart';

class RecurringProcessingService {
  RecurringProcessingService(
    this._recurringRepository, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final RecurringProcessingRepository _recurringRepository;
  final DateTime Function() _now;

  Future<int> processDueTransactions() async {
    final now = _now();
    final today = DateTime(now.year, now.month, now.day);
    final recurringTransactions = await _recurringRepository.getAll();
    var generatedCount = 0;

    for (final recurring in recurringTransactions) {
      if (!recurring.isEnabled || recurring.id == null) {
        continue;
      }
      generatedCount += await _processRecurring(recurring, today, now);
    }

    return generatedCount;
  }

  Future<int> _processRecurring(
    RecurringTransaction recurring,
    DateTime today,
    DateTime generatedAt,
  ) async {
    final lastProcessedDate = recurring.lastProcessedDate;
    var month = lastProcessedDate == null
        ? DateTime(recurring.startDate.year, recurring.startDate.month)
        : _nextMonth(lastProcessedDate);
    var generatedCount = 0;

    while (_monthIndex(month) <= _monthIndex(today)) {
      final scheduledDate = _scheduledDate(
        month.year,
        month.month,
        recurring.dayOfMonth,
      );
      if (scheduledDate.isAfter(today)) {
        break;
      }

      final generated = Transaction(
        type: recurring.type,
        amount: recurring.amount,
        category: recurring.category,
        note: recurring.note,
        date: scheduledDate,
        recurringTransactionId: recurring.id,
        generatedAt: generatedAt,
      );
      final inserted = await _recurringRepository.insertOccurrence(
        recurringId: recurring.id!,
        transaction: generated,
        processedDate: scheduledDate,
        updatedAt: generatedAt,
      );
      if (inserted) {
        generatedCount++;
      }
      month = _nextMonth(month);
    }

    return generatedCount;
  }

  DateTime _scheduledDate(int year, int month, int requestedDay) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, math.min(requestedDay, lastDay));
  }

  DateTime _nextMonth(DateTime date) {
    return DateTime(date.year, date.month + 1);
  }

  int _monthIndex(DateTime date) => date.year * 12 + date.month;
}
