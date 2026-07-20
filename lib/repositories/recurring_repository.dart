import 'package:akm_finance_manager/core/database/database_helper.dart';
import 'package:akm_finance_manager/models/recurring_transaction.dart';
import 'package:akm_finance_manager/models/transaction.dart';
import 'package:sqflite/sqflite.dart' show Database;

/// Provides persistence operations for recurring transactions.
abstract interface class RecurringProcessingRepository {
  Future<List<RecurringTransaction>> getAll();

  Future<bool> insertOccurrence({
    required int recurringId,
    required Transaction transaction,
    required DateTime processedDate,
    required DateTime updatedAt,
  });
}

class RecurringRepository implements RecurringProcessingRepository {
  RecurringRepository(this._databaseHelper);

  static const String _tableName = 'recurring_transactions';

  final DatabaseHelper _databaseHelper;

  Future<int> insert(RecurringTransaction recurring) async {
    final Database database = await _databaseHelper.database;
    return database.insert(_tableName, recurring.toMap());
  }

  @override
  Future<List<RecurringTransaction>> getAll() async {
    final Database database = await _databaseHelper.database;
    final maps = await database.query(_tableName, orderBy: 'day_of_month ASC');

    return maps.map(RecurringTransaction.fromMap).toList(growable: false);
  }

  Future<void> update(RecurringTransaction recurring) async {
    final id = recurring.id;
    if (id == null) {
      throw ArgumentError.value(
        recurring,
        'recurring',
        'The recurring transaction must have an ID before it can be updated.',
      );
    }

    final Database database = await _databaseHelper.database;
    await database.update(
      _tableName,
      recurring.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> delete(int id) async {
    final Database database = await _databaseHelper.database;
    await database.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> deleteAll() async {
    final Database database = await _databaseHelper.database;
    await database.delete(_tableName);
  }

  @override
  Future<bool> insertOccurrence({
    required int recurringId,
    required Transaction transaction,
    required DateTime processedDate,
    required DateTime updatedAt,
  }) async {
    final Database database = await _databaseHelper.database;
    return database.transaction<bool>((databaseTransaction) async {
      final rows = await databaseTransaction.query(
        _tableName,
        columns: <String>['last_processed_date'],
        where: 'id = ?',
        whereArgs: <Object?>[recurringId],
        limit: 1,
      );
      if (rows.isEmpty) {
        return false;
      }

      final storedDate = rows.first['last_processed_date'] as String?;
      final lastProcessed = storedDate == null
          ? null
          : DateTime.tryParse(storedDate);
      if (lastProcessed != null &&
          _monthIndex(lastProcessed) >= _monthIndex(processedDate)) {
        return false;
      }

      await databaseTransaction.insert('transactions', transaction.toDatabaseMap());
      await databaseTransaction.update(
        _tableName,
        <String, Object?>{
          'last_processed_date': processedDate.toIso8601String(),
          'updated_at': updatedAt.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: <Object?>[recurringId],
      );
      return true;
    });
  }

  int _monthIndex(DateTime date) => date.year * 12 + date.month;
}
