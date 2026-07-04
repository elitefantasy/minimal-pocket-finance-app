import 'dart:io';

import 'package:akm_finance_manager/core/constants/app_constants.dart';
import 'package:akm_finance_manager/core/database/database_helper.dart';
import 'package:akm_finance_manager/repositories/transaction_repository.dart';
import 'package:akm_finance_manager/services/export/export_service.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class DatabaseManagementRepository {
  DatabaseManagementRepository(
    this._databaseHelper,
    this._transactionRepository,
    this._exportService,
  );

  final DatabaseHelper _databaseHelper;
  final TransactionRepository _transactionRepository;
  final ExportService _exportService;

  Future<String> getCurrentDatabaseName() {
    return _databaseHelper.currentDatabaseName;
  }

  Future<List<String>> getDatabases() async {
    final directory = Directory(await _databaseHelper.databaseDirectoryPath);
    final databases = await directory
        .list()
        .where((entity) => entity is File && entity.path.endsWith('.db'))
        .map((entity) => path.basename(entity.path))
        .toList();
    databases.sort((first, second) => first.compareTo(second));
    return databases;
  }

  Future<void> createDatabase(String databaseName) {
    return _databaseHelper.initializeDatabaseFile(databaseName);
  }

  Future<void> switchDatabase(String databaseName) {
    return _databaseHelper.switchDatabase(databaseName);
  }

  Future<void> renameDatabase(String oldName, String newName) async {
    final directoryPath = await _databaseHelper.databaseDirectoryPath;
    final oldFile = File(path.join(directoryPath, oldName));
    final newFile = File(path.join(directoryPath, newName));
    if (await newFile.exists()) {
      throw ArgumentError.value(newName, 'newName', 'Already exists.');
    }

    final isCurrent = await _databaseHelper.currentDatabaseName == oldName;
    if (isCurrent) {
      await _databaseHelper.closeDatabase();
    }
    await oldFile.rename(newFile.path);
    if (isCurrent) {
      await _databaseHelper.switchDatabase(newName);
    }
  }

  Future<void> deleteDatabase(String databaseName) async {
    final directoryPath = await _databaseHelper.databaseDirectoryPath;
    await File(path.join(directoryPath, databaseName)).delete();
  }

  Future<String> backupCurrentDatabase() async {
    final databaseName = await _databaseHelper.currentDatabaseName;
    final directoryPath = await _databaseHelper.databaseDirectoryPath;
    final backupDirectory = Directory(path.join(directoryPath, 'backups'));
    await backupDirectory.create(recursive: true);
    await _databaseHelper.closeDatabase();
    final backupPath = path.join(backupDirectory.path, databaseName);
    await File(path.join(directoryPath, databaseName)).copy(backupPath);
    return backupPath;
  }

  Future<List<String>> getBackups() async {
    final directoryPath = await _databaseHelper.databaseDirectoryPath;
    final backupDirectory = Directory(path.join(directoryPath, 'backups'));
    if (!await backupDirectory.exists()) {
      return const <String>[];
    }
    final backups = await backupDirectory
        .list()
        .where((entity) => entity is File && entity.path.endsWith('.db'))
        .map((entity) => path.basename(entity.path))
        .toList();
    backups.sort((first, second) => first.compareTo(second));
    return backups;
  }

  Future<void> importBackup(String backupName, {required bool replace}) async {
    final directoryPath = await _databaseHelper.databaseDirectoryPath;
    final backupPath = path.join(directoryPath, 'backups', backupName);
    await _validateDatabase(backupPath);

    final destination = File(path.join(directoryPath, backupName));
    if (await destination.exists() && !replace) {
      throw StateError('A database with this name already exists.');
    }

    final isCurrent = await _databaseHelper.currentDatabaseName == backupName;
    if (isCurrent) {
      await _databaseHelper.closeDatabase();
    }
    await File(backupPath).copy(destination.path);
  }

  Future<String> exportCurrentDatabase() async {
    final databaseName = await _databaseHelper.currentDatabaseName;
    final directoryPath = await _databaseHelper.databaseDirectoryPath;
    final sourcePath = path.join(directoryPath, databaseName);
    await _databaseHelper.closeDatabase();
    try {
      return await _exportService.exportFile(
        sourcePath: sourcePath,
        artifactFolder: AppConstants.databaseExportFolder,
      );
    } finally {
      await _databaseHelper.database;
    }
  }

  // this function handles csv export making sure it goes to userselectedfolder/appname/csv/
  /// Exports all transactions from the database into a CSV file,
  /// saves it temporarily, moves it to the user's selected export folder,
  /// cleans up the temporary file, and returns the final file path
  Future<String> exportTransactionsCsv() async {
    // 1. Fetch the data and database metadata asynchronously
    final transactions = await _transactionRepository.getAll();
    final databaseName = await _databaseHelper.currentDatabaseName;
    final directoryPath = await _databaseHelper.databaseDirectoryPath;

    // 2. Prepare the temporary export directory within the app's internal storage. path.join safely combines paths regardless of platform (Android/iOS)
    final exportDirectory = Directory(path.join(directoryPath, 'exports'));

    // Creates the directory if it doesn't exist yet (recursive: true creates parent folders too)
    await exportDirectory.create(recursive: true);

    // 3. Construct the CSV filename based on the current database name
    final csvName =
        '${path.basenameWithoutExtension(databaseName)}_transactions.csv';
    final csvFile = File(path.join(exportDirectory.path, csvName));
    // 4. Building the CSV String. // Initialize a StringBuffer to efficiently construct the file's text content.
    final buffer = StringBuffer()..writeln('ID,Type,Amount,Category,Note,Date');
    // 5. Loop through the fetched transactions and append them as CSV rows
    for (final transaction in transactions) {
      buffer.writeln(
        <String>[
          _csv(transaction.id?.toString() ?? ''),
          _csv(transaction.type),
          _csv(transaction.amount.toString()),
          _csv(transaction.category),
          _csv(transaction.note),
          _csv(transaction.date.toIso8601String()),
        ].join(','),
      );
    }
    // 6. Write the accumulated buffer string into the temporary file.
    await csvFile.writeAsString(
      buffer.toString(),
      flush: true,
    );
    // 7. Hand off the temporary file to the export service.
    final exportedPath = await _exportService.exportFile(
      sourcePath: csvFile.path,
      artifactFolder: AppConstants.csvExportFolder,
    );
    // 8. Delete the temporary file from internal storage to save device space
    await csvFile.delete();

    return exportedPath;
  }

  Future<void> clearTransactions() {
    return _transactionRepository.deleteAll();
  }

  Future<void> _validateDatabase(String databasePath) async {
    final database = await openDatabase(databasePath, readOnly: true);
    try {
      final integrity = await database.rawQuery('PRAGMA integrity_check');
      if (integrity.first.values.first != 'ok') {
        throw const FormatException('Database integrity check failed.');
      }
      final tables = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      );
      final tableNames = tables.map((table) => table['name']).toSet();
      if (!tableNames.containsAll(<String>{
        'transactions',
        'categories',
        'recurring_transactions',
      })) {
        throw const FormatException('Unsupported database schema.');
      }
    } finally {
      await database.close();
    }
  }

  String _csv(String value) => '"${value.replaceAll('"', '""')}"';
}
