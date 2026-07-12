import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stores the currently selected transaction date.
///
/// This is session-only UI state.
/// It survives navigation between screens but resets when the app restarts.
class SelectedTransactionDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void setDate(DateTime date) {
    state = date;
  }

  void resetToToday() {
    state = DateTime.now();
  }
}

final selectedTransactionDateProvider =
    NotifierProvider<SelectedTransactionDateNotifier, DateTime>(
      SelectedTransactionDateNotifier.new,
    );