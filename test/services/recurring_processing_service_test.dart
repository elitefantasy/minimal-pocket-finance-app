import 'package:akm_finance_manager/models/recurring_transaction.dart';
import 'package:akm_finance_manager/models/transaction.dart';
import 'package:akm_finance_manager/repositories/recurring_repository.dart';
import 'package:akm_finance_manager/services/recurring_processing_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creates every missed month and clamps invalid days', () async {
    final repository = _FakeRecurringRepository(<RecurringTransaction>[
      _recurring(lastProcessedDate: DateTime(2024, 1, 31), type: 'Income'),
    ]);
    final service = RecurringProcessingService(
      repository,
      now: () => DateTime(2024, 4, 30),
    );

    final count = await service.processDueTransactions();

    expect(count, 3);
    expect(
      repository.generated.map((transaction) => transaction.date),
      <DateTime>[
        DateTime(2024, 2, 29),
        DateTime(2024, 3, 31),
        DateTime(2024, 4, 30),
      ],
    );
    expect(
      repository.generated.every((transaction) => transaction.type == 'Income'),
      isTrue,
    );
  });

  test('does not process the current month before its scheduled day', () async {
    final repository = _FakeRecurringRepository(<RecurringTransaction>[
      _recurring(lastProcessedDate: DateTime(2024, 3, 20), dayOfMonth: 20),
    ]);
    final service = RecurringProcessingService(
      repository,
      now: () => DateTime(2024, 4, 15),
    );

    expect(await service.processDueTransactions(), 0);
    expect(repository.generated, isEmpty);
  });
}

RecurringTransaction _recurring({
  DateTime? lastProcessedDate,
  String type = 'Expense',
  int dayOfMonth = 31,
}) {
  return RecurringTransaction(
    id: 1,
    type: type,
    amount: 100,
    category: 'Other',
    note: 'Recurring',
    dayOfMonth: dayOfMonth,
    isEnabled: true,
    lastProcessedDate: lastProcessedDate,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );
}

class _FakeRecurringRepository implements RecurringProcessingRepository {
  _FakeRecurringRepository(this.recurringTransactions);

  final List<RecurringTransaction> recurringTransactions;
  final List<Transaction> generated = <Transaction>[];
  final Map<int, DateTime> _processedDates = <int, DateTime>{};

  @override
  Future<List<RecurringTransaction>> getAll() async => recurringTransactions;

  @override
  Future<bool> insertOccurrence({
    required int recurringId,
    required Transaction transaction,
    required DateTime processedDate,
    required DateTime updatedAt,
  }) async {
    final previous = _processedDates[recurringId];
    if (previous != null &&
        previous.year == processedDate.year &&
        previous.month >= processedDate.month) {
      return false;
    }
    _processedDates[recurringId] = processedDate;
    generated.add(transaction);
    return true;
  }
}
