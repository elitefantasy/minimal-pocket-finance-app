import 'dart:io';

import 'package:minimal_pocket_finance_app/core/constants/app_constants.dart';
import 'package:minimal_pocket_finance_app/core/database/database_helper.dart';
import 'package:minimal_pocket_finance_app/repositories/transaction_repository.dart';
import 'package:minimal_pocket_finance_app/services/export/export_service.dart';
import 'package:minimal_pocket_finance_app/services/import/android_saf_import_service.dart';
import 'package:minimal_pocket_finance_app/models/export_result.dart';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class DatabaseManagementRepository {
  DatabaseManagementRepository(
    this._databaseHelper,
    this._transactionRepository,
    this._exportService, {
    AndroidSafImportService? importService,
  }) : _importService = importService ?? AndroidSafImportService();

  final DatabaseHelper _databaseHelper;
  final TransactionRepository _transactionRepository;
  final ExportService _exportService;
  final AndroidSafImportService _importService;

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

  //
  Future<ExportResult> backupCurrentDatabase() async {
    // Get current database.
    final databaseName = await _databaseHelper.currentDatabaseName;
    final directoryPath = await _databaseHelper.databaseDirectoryPath;

    // Local database path.
    final sourcePath = path.join(directoryPath, databaseName);

    // Close SQLite before copying.
    await _databaseHelper.closeDatabase();

    try {
      // Export through SAF (Android)
      // or Downloads (Desktop).
      return await _exportService.exportFile(
        sourcePath: sourcePath,
        artifactFolder: AppConstants.backupFolder,
        fileName: _backupFileName(databaseName),
      );
    } finally {
      // Reopen database.
      await _databaseHelper.database;
    }
  }
  //

  /// Imports a database selected by the user through Android SAF.
  /// If a database with the same name already exists:
  /// - replace = false → throws an exception.
  /// - replace = true  → overwrites the existing database.
  Future<String?> importDatabase({required bool replace}) async {
    // Let the user choose a database.
    // ------------------------------------
    final selection = await _importService.pickDatabase();

    if (selection == null) {
      return null;
    }

    await _validateDatabase(selection.localPath);

    final importedFile = File(selection.localPath);

    final databaseName = selection.databaseName;
    // ----------------------------

    final directoryPath = await _databaseHelper.databaseDirectoryPath;

    final destination = File(path.join(directoryPath, databaseName));

    final exists = await destination.exists();

    if (exists && !replace) {
      throw StateError('A database with this name already exists.');
    }

    final isCurrent = await _databaseHelper.currentDatabaseName == databaseName;

    if (isCurrent) {
      await _databaseHelper.closeDatabase();
    }

    if (exists) {
      await destination.delete();
    }

    await importedFile.copy(destination.path);

    if (isCurrent) {
      await _databaseHelper.database;
    }

    // Remove temporary file.
    await importedFile.delete();

    return databaseName;
  }

  Future<String> getDefaultExportFileName() async {
    final databaseName = await _databaseHelper.currentDatabaseName;
    return _backupFileName(databaseName);
  }

  Future<ExportResult> exportCurrentDatabase({String? customFileName}) async {
    final databaseName = await _databaseHelper.currentDatabaseName;
    final directoryPath = await _databaseHelper.databaseDirectoryPath;
    final sourcePath = path.join(directoryPath, databaseName);

    String fileName;
    if (customFileName != null && customFileName.trim().isNotEmpty) {
      final trimmed = customFileName.trim();
      fileName = trimmed.toLowerCase().endsWith('.db') ? trimmed : '$trimmed.db';
    } else {
      fileName = _backupFileName(databaseName);
    }

    await _databaseHelper.closeDatabase();
    try {
      return await _exportService.exportFile(
        sourcePath: sourcePath,
        artifactFolder: AppConstants.databaseExportFolder,
        fileName: fileName,
      );
    } finally {
      await _databaseHelper.database;
    }
  }

  /// Exports all transactions from the database into a CSV file,
  /// saves it temporarily, moves it to the user's selected export folder,
  /// cleans up the temporary file, and returns the final file path
  Future<ExportResult> exportTransactionsCsv() async {
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
    await csvFile.writeAsString(buffer.toString(), flush: true);
    // 7. Hand off the temporary file to the export service.
    final exportedPath = await _exportService.exportFile(
      sourcePath: csvFile.path,
      artifactFolder: AppConstants.csvExportFolder,
    );
    // 8. Delete the temporary file from internal storage to save device space
    await csvFile.delete();

    return exportedPath;
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

  String _backupFileName(String databaseName) {
    final now = DateTime.now();
    final timestamp = [
      now.day,
      now.month,
      now.year % 100,
      now.hour,
      now.minute,
      now.second,
    ].map((value) => value.toString().padLeft(2, '0')).join();

    return '${path.basenameWithoutExtension(databaseName)}_$timestamp.db';
  }
}
