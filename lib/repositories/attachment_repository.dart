import 'package:akm_finance_manager/core/database/database_helper.dart';
import 'package:akm_finance_manager/models/attachment.dart';
import 'package:sqflite/sqflite.dart' show Database;

/// Provides persistence operations for file attachments associated with transactions.
class AttachmentRepository {
  AttachmentRepository(this._databaseHelper);

  static const String _tableName = 'attachments';

  final DatabaseHelper _databaseHelper;

  Future<int> insert(Attachment attachment) async {
    final Database database = await _databaseHelper.database;
    return database.insert(_tableName, attachment.toMap());
  }

  Future<void> insertBatch(List<Attachment> attachments, int transactionId) async {
    if (attachments.isEmpty) return;

    final Database database = await _databaseHelper.database;
    final batch = database.batch();
    for (final attachment in attachments) {
      final attachmentWithTxId = attachment.copyWith(transactionId: transactionId);
      batch.insert(_tableName, attachmentWithTxId.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<List<Attachment>> getByTransactionId(int transactionId) async {
    final Database database = await _databaseHelper.database;
    final maps = await database.query(
      _tableName,
      where: 'transaction_id = ?',
      whereArgs: <Object>[transactionId],
      orderBy: 'created_at ASC',
    );
    return maps.map(Attachment.fromMap).toList(growable: false);
  }

  /// Bulk loads attachments for multiple transaction IDs to prevent N+1 queries.
  Future<Map<int, List<Attachment>>> getByTransactionIds(List<int> transactionIds) async {
    if (transactionIds.isEmpty) return <int, List<Attachment>>{};

    final Database database = await _databaseHelper.database;
    final placeholders = List.filled(transactionIds.length, '?').join(',');
    final maps = await database.query(
      _tableName,
      where: 'transaction_id IN ($placeholders)',
      whereArgs: transactionIds.cast<Object>(),
      orderBy: 'created_at ASC',
    );

    final result = <int, List<Attachment>>{};
    for (final map in maps) {
      final attachment = Attachment.fromMap(map);
      final txId = attachment.transactionId;
      if (txId != null) {
        result.putIfAbsent(txId, () => <Attachment>[]).add(attachment);
      }
    }
    return result;
  }

  Future<void> delete(int id) async {
    final Database database = await _databaseHelper.database;
    await database.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: <Object>[id],
    );
  }

  Future<void> deleteByTransactionId(int transactionId) async {
    final Database database = await _databaseHelper.database;
    await database.delete(
      _tableName,
      where: 'transaction_id = ?',
      whereArgs: <Object>[transactionId],
    );
  }
}
