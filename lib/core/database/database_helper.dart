import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

/// Provides lazy, shared access to the application's SQLite database.
class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const String defaultDatabaseName = 'finance.db';
  static const int databaseVersion = 5;
  static const String _selectionFileName = '.current_database';

  Future<Database>? _databaseFuture;
  String? _currentDatabaseName;

  Future<Database> get database {
    return _databaseFuture ??= _initializeDatabase();
  }

  Future<Database> _initializeDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final databaseName = await currentDatabaseName;
    final databasePath = path.join(directory.path, databaseName);

    return _openDatabase(databasePath);
  }

  Future<String> get currentDatabaseName async {
    final cachedName = _currentDatabaseName;
    if (cachedName != null) {
      return cachedName;
    }

    final directory = await getApplicationDocumentsDirectory();
    final selectionFile = File(path.join(directory.path, _selectionFileName));
    if (await selectionFile.exists()) {
      final selectedName = (await selectionFile.readAsString()).trim();
      if (_isValidDatabaseName(selectedName) &&
          await File(path.join(directory.path, selectedName)).exists()) {
        _currentDatabaseName = selectedName;
        return selectedName;
      }
    }

    _currentDatabaseName = defaultDatabaseName;
    return defaultDatabaseName;
  }

  Future<String> get databaseDirectoryPath async {
    return (await getApplicationDocumentsDirectory()).path;
  }

  Future<void> switchDatabase(String databaseName) async {
    _validateDatabaseName(databaseName);
    final directory = await getApplicationDocumentsDirectory();
    if (!await File(path.join(directory.path, databaseName)).exists()) {
      throw ArgumentError.value(databaseName, 'databaseName', 'Not found.');
    }

    await closeDatabase();
    _currentDatabaseName = databaseName;
    await File(
      path.join(directory.path, _selectionFileName),
    ).writeAsString(databaseName, flush: true);
  }

  Future<void> closeDatabase() async {
    final databaseFuture = _databaseFuture;
    _databaseFuture = null;
    if (databaseFuture != null) {
      await (await databaseFuture).close();
    }
  }

  Future<void> initializeDatabaseFile(String databaseName) async {
    _validateDatabaseName(databaseName);
    final directory = await getApplicationDocumentsDirectory();
    final databasePath = path.join(directory.path, databaseName);
    if (await File(databasePath).exists()) {
      throw ArgumentError.value(
        databaseName,
        'databaseName',
        'A database with this name already exists.',
      );
    }
    final createdDatabase = await _openDatabase(databasePath);
    await createdDatabase.close();
  }

  Future<Database> _openDatabase(String databasePath) {
    return openDatabase(
      databasePath,
      version: databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );
  }

  bool _isValidDatabaseName(String databaseName) {
    return databaseName.isNotEmpty &&
        databaseName.toLowerCase().endsWith('.db') &&
        path.basename(databaseName) == databaseName;
  }

  void _validateDatabaseName(String databaseName) {
    if (!_isValidDatabaseName(databaseName)) {
      throw ArgumentError.value(
        databaseName,
        'databaseName',
        'Must be a valid .db file name.',
      );
    }
  }

  Future<void> _onConfigure(Database database) async {
    await database.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onOpen(Database database) async {
    await _ensureTablesExist(database);
  }

  Future<void> _ensureTablesExist(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS attachments (
        id TEXT PRIMARY KEY,
        transaction_id TEXT NOT NULL,
        file_path TEXT NOT NULL,
        file_type TEXT NOT NULL,
        file_name TEXT,
        file_size INTEGER,
        created_at TEXT NOT NULL,
        device_id TEXT,
        updated_at TEXT,
        FOREIGN KEY (transaction_id)
          REFERENCES transactions(id)
          ON DELETE CASCADE
      )
    ''');
    await database.execute(
      'CREATE INDEX IF NOT EXISTS index_attachments_transaction_id '
      'ON attachments(transaction_id)',
    );
  }

  Future<void> _onCreate(Database database, int version) async {
    final batch = database.batch()
      ..execute('''
        CREATE TABLE recurring_transactions (
          id TEXT PRIMARY KEY,
          type TEXT NOT NULL,
          amount REAL NOT NULL,
          category TEXT NOT NULL,
          note TEXT NOT NULL,
          day_of_month INTEGER NOT NULL CHECK(day_of_month BETWEEN 1 AND 31),
          is_enabled INTEGER NOT NULL CHECK(is_enabled IN (0, 1)),
          last_processed_date TEXT,
          created_at TEXT NOT NULL,
          start_date TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          device_id TEXT
        )
      ''')
      ..execute('''
        CREATE TABLE transactions (
          id TEXT PRIMARY KEY,
          type TEXT NOT NULL CHECK(type IN ('Income', 'Expense')),
          amount REAL NOT NULL,
          category TEXT NOT NULL,
          note TEXT NOT NULL,
          date TEXT NOT NULL,
          recurring_transaction_id TEXT,
          generated_at TEXT,
          deleted_at TEXT,
          device_id TEXT,
          updated_at TEXT,
          FOREIGN KEY (recurring_transaction_id)
            REFERENCES recurring_transactions(id)
            ON DELETE SET NULL
        )
      ''')
      ..execute('''
        CREATE TABLE categories (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL UNIQUE,
          device_id TEXT,
          updated_at TEXT
        )
      ''')
      ..execute('''
        CREATE TABLE attachments (
          id TEXT PRIMARY KEY,
          transaction_id TEXT NOT NULL,
          file_path TEXT NOT NULL,
          file_type TEXT NOT NULL,
          file_name TEXT,
          file_size INTEGER,
          created_at TEXT NOT NULL,
          device_id TEXT,
          updated_at TEXT,
          FOREIGN KEY (transaction_id)
            REFERENCES transactions(id)
            ON DELETE CASCADE
        )
      ''')
      ..execute('CREATE INDEX index_transactions_date ON transactions(date)')
      ..execute(
        'CREATE INDEX index_transactions_category ON transactions(category)',
      )
      ..execute('CREATE INDEX index_transactions_type ON transactions(type)')
      ..execute(
        'CREATE INDEX index_transactions_deleted_at ON transactions(deleted_at)',
      )
      ..execute(
        'CREATE INDEX index_transactions_recurring_transaction_id '
        'ON transactions(recurring_transaction_id)',
      )
      ..execute(
        'CREATE INDEX index_attachments_transaction_id '
        'ON attachments(transaction_id)',
      );

    await batch.commit(noResult: true);
    await _insertDefaultCategoriesIfEmpty(database);
  }

  Future<void> _onUpgrade(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _ensureTablesExist(database);
    }
    
    if (oldVersion < 3) {
      try {
        await database.execute(
          'ALTER TABLE transactions ADD COLUMN deleted_at TEXT',
        );
      } catch (e) {
        if (!e.toString().contains('duplicate column')) {
          rethrow;
        }
      }
      await database.execute(
        'CREATE INDEX IF NOT EXISTS index_transactions_deleted_at ON transactions(deleted_at)',
      );
    }

    if (oldVersion < 4) {
      await _ensureTablesExist(database);
    }
    
    if (oldVersion < 5) {
      await _migrateToV5(database);
    }
  }

  Future<void> _migrateToV5(Database database) async {
    const uuid = Uuid();
    
    // 1. Rename old tables
    await database.execute('ALTER TABLE recurring_transactions RENAME TO old_recurring_transactions');
    await database.execute('ALTER TABLE transactions RENAME TO old_transactions');
    await database.execute('ALTER TABLE categories RENAME TO old_categories');
    await database.execute('ALTER TABLE attachments RENAME TO old_attachments');

    // 2. Create new tables
    // Drop existing indices from renamed tables to avoid creation conflicts
    await database.execute('DROP INDEX IF EXISTS index_transactions_date');
    await database.execute('DROP INDEX IF EXISTS index_transactions_category');
    await database.execute('DROP INDEX IF EXISTS index_transactions_type');
    await database.execute('DROP INDEX IF EXISTS index_transactions_deleted_at');
    await database.execute('DROP INDEX IF EXISTS index_transactions_recurring_transaction_id');
    await database.execute('DROP INDEX IF EXISTS index_attachments_transaction_id');
    await _onCreate(database, 5);

    // 3. Migrate Categories
    final oldCategories = await database.query('old_categories');
    for (final row in oldCategories) {
      final newId = uuid.v4();
      await database.insert(
        'categories',
        {
          'id': newId,
          'name': row['name'],
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    // 4. Migrate Recurring Transactions
    final recurringMap = <int, String>{};
    final oldRecurring = await database.query('old_recurring_transactions');
    for (final row in oldRecurring) {
      final oldId = row['id'] as int;
      final newId = uuid.v4();
      recurringMap[oldId] = newId;
      final newRow = Map<String, dynamic>.from(row);
      newRow['id'] = newId;
      await database.insert('recurring_transactions', newRow);
    }

    // 5. Migrate Transactions
    final transactionMap = <int, String>{};
    final oldTransactions = await database.query('old_transactions');
    for (final row in oldTransactions) {
      final oldId = row['id'] as int;
      final newId = uuid.v4();
      transactionMap[oldId] = newId;
      final newRow = Map<String, dynamic>.from(row);
      newRow['id'] = newId;
      if (newRow['recurring_transaction_id'] != null) {
        newRow['recurring_transaction_id'] = recurringMap[newRow['recurring_transaction_id'] as int];
      }
      newRow['updated_at'] = DateTime.now().toUtc().toIso8601String();
      await database.insert('transactions', newRow);
    }

    // 6. Migrate Attachments
    final oldAttachments = await database.query('old_attachments');
    for (final row in oldAttachments) {
      final newId = uuid.v4();
      final newRow = Map<String, dynamic>.from(row);
      newRow['id'] = newId;
      if (newRow['transaction_id'] != null) {
        newRow['transaction_id'] = transactionMap[newRow['transaction_id'] as int];
      }
      newRow['updated_at'] = DateTime.now().toUtc().toIso8601String();
      // Only insert if the transaction still exists (we don't want orphaned attachments crashing due to FK)
      if (newRow['transaction_id'] != null) {
        await database.insert('attachments', newRow);
      }
    }

    // 7. Drop old tables
    await database.execute('DROP TABLE old_attachments');
    await database.execute('DROP TABLE old_transactions');
    await database.execute('DROP TABLE old_recurring_transactions');
    await database.execute('DROP TABLE old_categories');
  }

  Future<void> _insertDefaultCategoriesIfEmpty(Database database) async {
    final categoryCount =
        Sqflite.firstIntValue(
          await database.rawQuery('SELECT COUNT(*) FROM categories'),
        ) ??
        0;

    if (categoryCount != 0) {
      return;
    }

    const defaultCategories = <String>[
      'Food',
      'Travel',
      'Shopping',
      'Medical',
      'Education',
      'Other',
    ];
    final batch = database.batch();
    const uuid = Uuid();

    for (final category in defaultCategories) {
      batch.insert('categories', <String, Object?>{
        'id': uuid.v4(),
        'name': category,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    }

    await batch.commit(noResult: true);
  }
}
