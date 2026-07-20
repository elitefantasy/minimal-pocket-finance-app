import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Provides lazy, shared access to the application's SQLite database.
class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const String defaultDatabaseName = 'finance.db';
  static const int databaseVersion = 2;
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

  Future<void> _onCreate(Database database, int version) async {
    final batch = database.batch()
      ..execute('''
        CREATE TABLE recurring_transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT NOT NULL,
          amount REAL NOT NULL,
          category TEXT NOT NULL,
          note TEXT NOT NULL,
          day_of_month INTEGER NOT NULL CHECK(day_of_month BETWEEN 1 AND 31),
          is_enabled INTEGER NOT NULL CHECK(is_enabled IN (0, 1)),
          last_processed_date TEXT,
          created_at TEXT NOT NULL,
          start_date TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''')
      ..execute('''
        CREATE TABLE transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT NOT NULL CHECK(type IN ('Income', 'Expense')),
          amount REAL NOT NULL,
          category TEXT NOT NULL,
          note TEXT NOT NULL,
          date TEXT NOT NULL,
          recurring_transaction_id INTEGER,
          generated_at TEXT,
          deleted_at TEXT,
          FOREIGN KEY (recurring_transaction_id)
            REFERENCES recurring_transactions(id)
            ON DELETE SET NULL
        )
      ''')
      ..execute('''
        CREATE TABLE categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE
        )
      ''')
      ..execute('''
        CREATE TABLE attachments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          transaction_id INTEGER NOT NULL,
          file_path TEXT NOT NULL,
          file_type TEXT NOT NULL,
          file_name TEXT,
          file_size INTEGER,
          created_at TEXT NOT NULL,
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
      await database.execute('''
        CREATE TABLE IF NOT EXISTS attachments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          transaction_id INTEGER NOT NULL,
          file_path TEXT NOT NULL,
          file_type TEXT NOT NULL,
          file_name TEXT,
          file_size INTEGER,
          created_at TEXT NOT NULL,
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

    for (final category in defaultCategories) {
      batch.insert('categories', <String, Object?>{'name': category});
    }

    await batch.commit(noResult: true);
  }
}
