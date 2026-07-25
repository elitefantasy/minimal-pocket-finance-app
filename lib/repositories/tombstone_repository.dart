import 'package:akm_finance_manager/core/database/database_helper.dart';
import 'package:akm_finance_manager/models/tombstone.dart';
import 'package:sqflite/sqflite.dart';

class TombstoneRepository {
  TombstoneRepository(this._databaseHelper);

  static const String _tableName = 'tombstones';
  final DatabaseHelper _databaseHelper;

  Future<void> insert(Tombstone tombstone) async {
    final Database database = await _databaseHelper.database;
    await database.insert(
      _tableName,
      tombstone.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertBatch(List<Tombstone> tombstones) async {
    if (tombstones.isEmpty) return;
    final Database database = await _databaseHelper.database;
    final batch = database.batch();
    for (final t in tombstones) {
      batch.insert(
        _tableName,
        t.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Tombstone>> getAll() async {
    final Database database = await _databaseHelper.database;
    final maps = await database.query(_tableName);
    return maps.map(Tombstone.fromMap).toList();
  }

  Future<void> delete(String id, String tableName) async {
    final Database database = await _databaseHelper.database;
    await database.delete(
      _tableName,
      where: 'id = ? AND table_name = ?',
      whereArgs: <Object>[id, tableName],
    );
  }

  Future<void> deleteAll() async {
    final Database database = await _databaseHelper.database;
    await database.delete(_tableName);
  }
}
