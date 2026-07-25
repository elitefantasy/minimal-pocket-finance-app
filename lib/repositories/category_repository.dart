import 'package:akm_finance_manager/core/database/database_helper.dart';
import 'package:akm_finance_manager/models/category.dart';
import 'package:sqflite/sqflite.dart' show Database, Sqflite;
import 'package:uuid/uuid.dart';
import 'package:akm_finance_manager/models/tombstone.dart';
import 'package:akm_finance_manager/repositories/tombstone_repository.dart';

/// Provides persistence operations for transaction categories.
class CategoryRepository {
  CategoryRepository(
    this._databaseHelper, {
    TombstoneRepository? tombstoneRepository,
  }) : _tombstoneRepository = 
           tombstoneRepository ?? TombstoneRepository(_databaseHelper);

  static const String _tableName = 'categories';
  static const String _transactionsTableName = 'transactions';

  final DatabaseHelper _databaseHelper;
  final TombstoneRepository _tombstoneRepository;

  static const List<String> defaultCategories = <String>[
    'Food',
    'Travel',
    'Shopping',
    'Medical',
    'Education',
    'Other',
  ];

  Future<void> ensureDefaultCategoriesExist() async {
    final Database database = await _databaseHelper.database;
    final maps = await database.query(_tableName, columns: ['name']);
    final existingNames = maps.map((e) => (e['name'] as String).toLowerCase()).toSet();

    final batch = database.batch();
    var hasNew = false;
    const uuid = Uuid();

    for (final defaultCat in defaultCategories) {
      if (!existingNames.contains(defaultCat.toLowerCase())) {
        batch.insert(_tableName, <String, Object?>{
          'id': uuid.v4(),
          'name': defaultCat,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
        hasNew = true;
      }
    }

    if (hasNew) {
      await batch.commit(noResult: true);
    }
  }

  Future<String> insert(Category category) async {
    final Database database = await _databaseHelper.database;
    final id = category.id ?? const Uuid().v4();
    final categoryToInsert = category.copyWith(
      id: id,
      updatedAt: category.updatedAt ?? DateTime.now().toUtc(),
    );
    await database.insert(_tableName, categoryToInsert.toMap());
    return id;
  }

  Future<List<Category>> getAll() async {
    await ensureDefaultCategoriesExist();
    final Database database = await _databaseHelper.database;
    final maps = await database.query(_tableName, orderBy: 'name ASC');

    return maps.map(Category.fromMap).toList(growable: false);
  }

  Future<void> update(Category category) async {
    final id = category.id;
    if (id == null) {
      throw ArgumentError.value(
        category,
        'category',
        'The category must have an ID before it can be updated.',
      );
    }

    final Database database = await _databaseHelper.database;
    await database.update(
      _tableName,
      category.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> delete(String id) async {
    final Database database = await _databaseHelper.database;
    await database.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
    await _tombstoneRepository.insert(Tombstone(
      id: id,
      tableName: _tableName,
      deletedAt: DateTime.now().toUtc(),
    ));
  }

  Future<int> getUsageCount(String name) async {
    final Database database = await _databaseHelper.database;
    final result = await database.rawQuery(
      'SELECT COUNT(*) FROM $_transactionsTableName WHERE category = ?',
      <Object?>[name],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<bool> isCategoryInUse(String name) async {
    final count = await getUsageCount(name);
    return count > 0;
  }
}

