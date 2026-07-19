import 'package:akm_finance_manager/core/database/database_helper.dart';
import 'package:akm_finance_manager/models/transaction.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm, Database;

/// Provides persistence operations for financial transactions.
class TransactionRepository {
  TransactionRepository(this._databaseHelper);

  static const String _tableName = 'transactions';

  final DatabaseHelper _databaseHelper;

  Future<int> insert(Transaction transaction) async {
    final Database database = await _databaseHelper.database;
    return database.insert(_tableName, transaction.toMap());
  }

  Future<void> restore(Transaction transaction) async {
    if (transaction.id == null) {
      throw ArgumentError.value(
        transaction,
        'transaction',
        'The transaction must have an ID before it can be restored.',
      );
    }

    final Database database = await _databaseHelper.database;
    await database.insert(
      _tableName,
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<List<Transaction>> getAll({int? year}) async {
    final Database database = await _databaseHelper.database;
    final maps = await database.query(
      _tableName,
      where: year == null ? null : "strftime('%Y', date) = ?",
      whereArgs: year == null ? null : <Object>[year.toString()],
      orderBy: 'date DESC',
    );

    return maps.map(Transaction.fromMap).toList(growable: false);
  }

  Future<List<int>> getAvailableYears() async {
    final Database database = await _databaseHelper.database;
    final rows = await database.rawQuery(
      "SELECT DISTINCT strftime('%Y', date) AS year FROM $_tableName "
      "WHERE date IS NOT NULL ORDER BY year DESC",
    );
    return rows
        .map((row) => int.tryParse(row['year'] as String? ?? ''))
        .whereType<int>()
        .toList(growable: false);
  }

  Future<void> update(Transaction transaction) async {
    final id = transaction.id;
    if (id == null) {
      throw ArgumentError.value(
        transaction,
        'transaction',
        'The transaction must have an ID before it can be updated.',
      );
    }

    final Database database = await _databaseHelper.database;
    await database.update(
      _tableName,
      transaction.toMap(),
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
}
