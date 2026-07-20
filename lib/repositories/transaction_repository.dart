import 'package:akm_finance_manager/core/database/database_helper.dart';
import 'package:akm_finance_manager/models/attachment.dart';
import 'package:akm_finance_manager/models/transaction.dart';
import 'package:akm_finance_manager/repositories/attachment_repository.dart';
import 'package:sqflite/sqflite.dart' show Database;

/// Provides persistence operations for financial transactions and their attachments.
class TransactionRepository {
  TransactionRepository(
    this._databaseHelper, {
    AttachmentRepository? attachmentRepository,
  }) : _attachmentRepository =
            attachmentRepository ?? AttachmentRepository(_databaseHelper);

  static const String _tableName = 'transactions';

  final DatabaseHelper _databaseHelper;
  final AttachmentRepository _attachmentRepository;

  Future<int> insert(Transaction transaction) async {
    final Database database = await _databaseHelper.database;
    final insertedId = await database.insert(_tableName, transaction.toMap());

    if (transaction.attachments.isNotEmpty) {
      await _attachmentRepository.insertBatch(transaction.attachments, insertedId);
    }

    return insertedId;
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

    final rawTransactions = maps.map(Transaction.fromMap).toList(growable: false);
    return _populateAttachments(rawTransactions);
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

    // Synchronize attachments
    final existingAttachments = await _attachmentRepository.getByTransactionId(id);
    final currentAttachmentIds = transaction.attachments
        .map((a) => a.id)
        .whereType<int>()
        .toSet();

    // Delete attachments removed by the user
    for (final existing in existingAttachments) {
      if (existing.id != null && !currentAttachmentIds.contains(existing.id)) {
        await _attachmentRepository.delete(existing.id!);
      }
    }

    // Insert new attachments
    final newAttachments = transaction.attachments
        .where((a) => a.id == null)
        .toList();
    if (newAttachments.isNotEmpty) {
      await _attachmentRepository.insertBatch(newAttachments, id);
    }
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

    final rawTransactions = maps.map(Transaction.fromMap).toList(growable: false);
    return _populateAttachments(rawTransactions);
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

  /// Bulk loads attachments for transactions to avoid N+1 query overhead.
  Future<List<Transaction>> _populateAttachments(List<Transaction> transactions) async {
    if (transactions.isEmpty) return transactions;

    final txIds = transactions.map((t) => t.id).whereType<int>().toList();
    if (txIds.isEmpty) return transactions;

    final attachmentsMap = await _attachmentRepository.getByTransactionIds(txIds);

    return transactions.map((tx) {
      if (tx.id == null) return tx;
      final attachments = attachmentsMap[tx.id] ?? const <Attachment>[];
      return tx.copyWith(attachments: attachments);
    }).toList(growable: false);
  }
}
