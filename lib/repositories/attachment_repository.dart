import 'package:minimal_pocket_finance_app/core/database/database_helper.dart';
import 'package:minimal_pocket_finance_app/models/attachment.dart';
import 'package:sqflite/sqflite.dart' show Database;
import 'package:uuid/uuid.dart';

/// Provides persistence operations for file attachments associated with transactions.
class AttachmentRepository {
  AttachmentRepository(this._databaseHelper);

  static const String _tableName = 'attachments';

  final DatabaseHelper _databaseHelper;

  Future<String> insert(Attachment attachment) async {
    final Database database = await _databaseHelper.database;
    final id = attachment.id ?? const Uuid().v4();
    final attachmentToInsert = attachment.copyWith(
      id: id,
      updatedAt: attachment.updatedAt ?? DateTime.now().toUtc(),
    );
    await database.insert(_tableName, attachmentToInsert.toMap());
    return id;
  }

  Future<void> insertBatch(List<Attachment> attachments, String transactionId) async {
    if (attachments.isEmpty) return;

    final Database database = await _databaseHelper.database;
    final batch = database.batch();
    const uuid = Uuid();
    for (final attachment in attachments) {
      final attachmentWithTxId = attachment.copyWith(
        id: attachment.id ?? uuid.v4(),
        transactionId: transactionId,
        updatedAt: attachment.updatedAt ?? DateTime.now().toUtc(),
      );
      batch.insert(_tableName, attachmentWithTxId.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<List<Attachment>> getByTransactionId(String transactionId) async {
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
  Future<Map<String, List<Attachment>>> getByTransactionIds(List<String> transactionIds) async {
    if (transactionIds.isEmpty) return <String, List<Attachment>>{};

    final Database database = await _databaseHelper.database;
    final placeholders = List.filled(transactionIds.length, '?').join(',');
    final maps = await database.query(
      _tableName,
      where: 'transaction_id IN ($placeholders)',
      whereArgs: transactionIds.cast<Object>(),
      orderBy: 'created_at ASC',
    );

    final result = <String, List<Attachment>>{};
    for (final map in maps) {
      final attachment = Attachment.fromMap(map);
      final txId = attachment.transactionId;
      if (txId != null) {
        result.putIfAbsent(txId, () => <Attachment>[]).add(attachment);
      }
    }
    return result;
  }

  Future<void> delete(String id) async {
    final Database database = await _databaseHelper.database;
    await database.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: <Object>[id],
    );
  }

  Future<void> deleteByTransactionId(String transactionId) async {
    final Database database = await _databaseHelper.database;
    await database.delete(
      _tableName,
      where: 'transaction_id = ?',
      whereArgs: <Object>[transactionId],
    );
  }
}
