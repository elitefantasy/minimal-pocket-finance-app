import 'package:akm_finance_manager/core/database/database_helper.dart';
import 'package:akm_finance_manager/models/transaction.dart';
import 'package:sqflite/sqflite.dart' show Database;

/// Provides persistence operations for financial transactions.
class TransactionRepository {
  TransactionRepository(this._databaseHelper);

  static const String _tableName = 'transactions';

  final DatabaseHelper _databaseHelper;

  Future<int> insert(Transaction transaction) async {
    final Database database = await _databaseHelper.database;
    return database.insert(_tableName, transaction.toMap());
  }

  Future<List<Transaction>> getAll({int? year}) async {
    final Database database = await _databaseHelper.database;
    await _purgeExpired(database);
    final maps = await database.query(
      _tableName,
      where: year == null
          ? 'deleted_at IS NULL'
          : "deleted_at IS NULL AND strftime('%Y', date) = ?",
      whereArgs: year == null ? null : <Object>[year.toString()],
      orderBy: 'date DESC',
    );

    return maps.map(Transaction.fromMap).toList(growable: false);
  }

  Future<List<int>> getAvailableYears() async {
    final Database database = await _databaseHelper.database;
    await _purgeExpired(database);
    final rows = await database.rawQuery(
      "SELECT DISTINCT strftime('%Y', date) AS year FROM $_tableName "
      "WHERE date IS NOT NULL AND deleted_at IS NULL ORDER BY year DESC",
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
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> moveToTrash(int id) async {
    final Database database = await _databaseHelper.database;
    await database.update(
      _tableName,
      <String, Object?>{'deleted_at': DateTime.now().toIso8601String()},
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: <Object?>[id],
    );
  }

  Future<List<Transaction>> getTrashed() async {
    final Database database = await _databaseHelper.database;
    await _purgeExpired(database);
    final maps = await database.query(
      _tableName,
      where: 'deleted_at IS NOT NULL',
      orderBy: 'deleted_at DESC',
    );
    return maps.map(Transaction.fromMap).toList(growable: false);
  }

  Future<void> restore(int id) async {
    final Database database = await _databaseHelper.database;
    await database.update(
      _tableName,
      <String, Object?>{'deleted_at': null},
      where: 'id = ? AND deleted_at IS NOT NULL',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> permanentlyDelete(int id) async {
    final Database database = await _databaseHelper.database;
    await database.delete(
      _tableName,
      where: 'id = ? AND deleted_at IS NOT NULL',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> emptyTrash() async {
    final Database database = await _databaseHelper.database;
    await database.delete(_tableName, where: 'deleted_at IS NOT NULL');
  }

  Future<void> _purgeExpired(Database database) {
    final expiry = DateTime.now().subtract(const Duration(days: 30));
    return database.delete(
      _tableName,
      where: 'deleted_at IS NOT NULL AND deleted_at < ?',
      whereArgs: <Object>[expiry.toIso8601String()],
    );
  }
}
