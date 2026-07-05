import 'package:akm_finance_manager/app/providers.dart';
import 'package:akm_finance_manager/models/recurring_transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecurringNotifier extends AsyncNotifier<List<RecurringTransaction>> {
  @override
  Future<List<RecurringTransaction>> build() {
    return ref.read(recurringRepositoryProvider).getAll();
  }

  Future<void> addRecurring(RecurringTransaction recurring) async {
    await ref.read(recurringRepositoryProvider).insert(recurring);
    await _refresh();
  }

  Future<void> updateRecurring(RecurringTransaction recurring) async {
    await ref.read(recurringRepositoryProvider).update(recurring);
    await _refresh();
  }

  Future<void> deleteRecurring(int id) async {
    await ref.read(recurringRepositoryProvider).delete(id);
    await _refresh();
  }

  Future<void> _refresh() async {
    state = AsyncData(await ref.read(recurringRepositoryProvider).getAll());
  }
}

final recurringNotifierProvider =
    AsyncNotifierProvider<RecurringNotifier, List<RecurringTransaction>>(
      RecurringNotifier.new,
    );
