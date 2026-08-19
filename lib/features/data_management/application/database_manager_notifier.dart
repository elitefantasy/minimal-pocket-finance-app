import 'package:minimal_pocket_finance_app/app/providers.dart';
import 'package:minimal_pocket_finance_app/features/categories/application/category_notifier.dart';
import 'package:minimal_pocket_finance_app/features/recurring/application/recurring_notifier.dart';
import 'package:minimal_pocket_finance_app/features/transactions/application/transaction_notifier.dart';
import 'package:minimal_pocket_finance_app/models/export_result.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class DatabaseManagerState {
  DatabaseManagerState({
    required this.currentDatabase,
    required List<String> databases,
    required this.exportPath,
    required this.isCustomExportPath,
  }) : databases = List<String>.unmodifiable(databases);

  final String currentDatabase;
  final List<String> databases;
  final String exportPath;
  final bool isCustomExportPath;
}

class DatabaseManagerNotifier extends AsyncNotifier<DatabaseManagerState> {
  @override
  Future<DatabaseManagerState> build() {
    return _loadState();
  }

  Future<void> changeExportFolder({
    required String newPath,
    required bool moveExistingFiles,
  }) async {
    final exportService = ref.read(exportServiceProvider);
    final currentPath = await exportService.getExportDirectoryPath();

    if (newPath == currentPath) return;

    if (moveExistingFiles) {
      await exportService.moveExportFiles(
        sourcePath: currentPath,
        targetPath: newPath,
      );
    }

    await exportService.setCustomExportFolder(newPath);
    await _refresh();
  }

  Future<void> resetExportFolder({
    required bool moveExistingFiles,
  }) async {
    final exportService = ref.read(exportServiceProvider);
    final currentPath = await exportService.getExportDirectoryPath();

    await exportService.resetExportFolder();
    final defaultPath = await exportService.getExportDirectoryPath();

    if (moveExistingFiles && currentPath != defaultPath) {
      await exportService.moveExportFiles(
        sourcePath: currentPath,
        targetPath: defaultPath,
      );
    }

    await _refresh();
  }

  Future<String?> createDatabase(String name) async {
    final databaseName = _normalizeName(name);
    if (databaseName == null) {
      return 'Database name cannot be empty.';
    }
    if (_databaseExists(databaseName)) {
      return 'A database with this name already exists.';
    }
    await ref
        .read(databaseManagementRepositoryProvider)
        .createDatabase(databaseName);
    await _refresh();
    return null;
  }

  Future<String?> renameDatabase(String oldName, String newName) async {
    final normalizedName = _normalizeName(newName);
    if (normalizedName == null) {
      return 'Database name cannot be empty.';
    }
    if (oldName.toLowerCase() != normalizedName.toLowerCase() &&
        _databaseExists(normalizedName)) {
      return 'A database with this name already exists.';
    }
    if (oldName == normalizedName) {
      return null;
    }
    await ref
        .read(databaseManagementRepositoryProvider)
        .renameDatabase(oldName, normalizedName);
    await _refresh();
    return null;
  }

  Future<String?> deleteDatabase(String databaseName) async {
    final current = state.requireValue.currentDatabase;
    if (databaseName == current) {
      return 'The active database cannot be deleted.';
    }
    await ref
        .read(databaseManagementRepositoryProvider)
        .deleteDatabase(databaseName);
    await _refresh();
    return null;
  }

  Future<void> switchDatabase(String databaseName) async {
    if (databaseName == state.requireValue.currentDatabase) {
      return;
    }
    await ref
        .read(databaseManagementRepositoryProvider)
        .switchDatabase(databaseName);
    _invalidateDataProviders();
    await _refresh();
  }

  Future<ExportResult> backupCurrentDatabase() async {
    final location = await ref
        .read(databaseManagementRepositoryProvider)
        .backupCurrentDatabase();
    await _refresh();
    return location;
  }

  Future<String?> importDatabase({required bool replace}) async {
    final databaseName = await ref
        .read(databaseManagementRepositoryProvider)
        .importDatabase(replace: replace);

    if (databaseName == null) {
      return null;
    }

    if (databaseName == state.requireValue.currentDatabase) {
      _invalidateDataProviders();
    }

    await _refresh();

    return databaseName;
  }

  Future<String> getDefaultExportFileName() {
    return ref
        .read(databaseManagementRepositoryProvider)
        .getDefaultExportFileName();
  }

  Future<ExportResult> exportCurrentDatabase({String? customFileName}) {
    return ref
        .read(databaseManagementRepositoryProvider)
        .exportCurrentDatabase(customFileName: customFileName);
  }

  Future<ExportResult> exportTransactionsCsv() {
    return ref
        .read(databaseManagementRepositoryProvider)
        .exportTransactionsCsv();
  }

  Future<DatabaseManagerState> _loadState() async {
    final repository = ref.read(databaseManagementRepositoryProvider);
    final exportService = ref.read(exportServiceProvider);
    await ref.read(databaseProvider).database;
    return DatabaseManagerState(
      currentDatabase: await repository.getCurrentDatabaseName(),
      databases: await repository.getDatabases(),
      exportPath: await exportService.getExportDirectoryPath(),
      isCustomExportPath: await exportService.isCustomExportFolder(),
    );
  }

  Future<void> _refresh() async {
    state = AsyncData(await _loadState());
  }

  void _invalidateDataProviders() {
    ref
      ..invalidate(transactionNotifierProvider)
      ..invalidate(categoryNotifierProvider)
      ..invalidate(recurringNotifierProvider);
  }

  bool _databaseExists(String databaseName) {
    return state.requireValue.databases.any(
      (existing) => existing.toLowerCase() == databaseName.toLowerCase(),
    );
  }

  String? _normalizeName(String name) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return null;
    }
    return trimmedName.toLowerCase().endsWith('.db')
        ? trimmedName
        : '$trimmedName.db';
  }
}

final databaseManagerProvider =
    AsyncNotifierProvider<DatabaseManagerNotifier, DatabaseManagerState>(
      DatabaseManagerNotifier.new,
    );
