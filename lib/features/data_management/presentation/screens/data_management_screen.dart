import 'package:akm_finance_manager/features/data_management/application/database_manager_notifier.dart';
import 'package:akm_finance_manager/features/data_management/presentation/widgets/backup_card.dart';
import 'package:akm_finance_manager/features/data_management/presentation/widgets/danger_zone_card.dart';
import 'package:akm_finance_manager/features/data_management/presentation/widgets/database_card.dart';
import 'package:akm_finance_manager/features/data_management/presentation/widgets/database_tile.dart';
import 'package:akm_finance_manager/shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DataManagementScreen extends ConsumerWidget {
  const DataManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final managerAsync = ref.watch(databaseManagerProvider);

    return AppScaffold(
      title: 'Data Management',
      body: managerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text(error.toString())),
        data: (state) => ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            DatabaseCard(databaseName: state.currentDatabase),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Available Databases',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _createDatabase(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Create'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: state.databases
                    .map(
                      (database) => DatabaseTile(
                        databaseName: database,
                        isActive: database == state.currentDatabase,
                        onSelect: () => _switchDatabase(context, ref, database),
                        onRename: () => _renameDatabase(context, ref, database),
                        onDelete: database == state.currentDatabase
                            ? null
                            : () => _deleteDatabase(context, ref, database),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
            const SizedBox(height: 16),
            BackupCard(
              backups: state.backups,
              onBackup: () => _backup(context, ref),
              onImport: (backup) => _import(context, ref, backup),
              onExportDatabase: () => _exportDatabase(context, ref),
              onExportCsv: () => _exportCsv(context, ref),
            ),
            const SizedBox(height: 16),
            DangerZoneCard(
              onClearTransactions: () => _clearTransactions(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createDatabase(BuildContext context, WidgetRef ref) async {
    final name = await _requestName(context, title: 'Create Database');
    if (name == null || !context.mounted) {
      return;
    }
    await _perform(context, () async {
      final message = await ref
          .read(databaseManagerProvider.notifier)
          .createDatabase(name);
      if (context.mounted) {
        _showMessage(context, message ?? 'Database created.');
      }
    });
  }

  Future<void> _renameDatabase(
    BuildContext context,
    WidgetRef ref,
    String database,
  ) async {
    final name = await _requestName(
      context,
      title: 'Rename Database',
      initialValue: database,
    );
    if (name == null || !context.mounted) {
      return;
    }
    await _perform(context, () async {
      final message = await ref
          .read(databaseManagerProvider.notifier)
          .renameDatabase(database, name);
      if (context.mounted) {
        _showMessage(context, message ?? 'Database renamed.');
      }
    });
  }

  Future<void> _deleteDatabase(
    BuildContext context,
    WidgetRef ref,
    String database,
  ) async {
    final confirmed = await _confirm(
      context,
      title: 'Delete Database?',
      message: 'Permanently delete $database?',
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    await _perform(context, () async {
      final message = await ref
          .read(databaseManagerProvider.notifier)
          .deleteDatabase(database);
      if (context.mounted) {
        _showMessage(context, message ?? 'Database deleted.');
      }
    });
  }

  Future<void> _switchDatabase(
    BuildContext context,
    WidgetRef ref,
    String database,
  ) async {
    await _perform(context, () async {
      await ref.read(databaseManagerProvider.notifier).switchDatabase(database);
      if (context.mounted) {
        _showMessage(context, 'Switched to $database.');
      }
    });
  }

  Future<void> _backup(BuildContext context, WidgetRef ref) async {
    await _perform(context, () async {
      final location = await ref
          .read(databaseManagerProvider.notifier)
          .backupCurrentDatabase();
      if (context.mounted) {
        _showMessage(context, 'Backup created at $location');
      }
    });
  }

  Future<void> _import(
    BuildContext context,
    WidgetRef ref,
    String backup,
  ) async {
    final notifier = ref.read(databaseManagerProvider.notifier);
    var replace = false;
    if (notifier.importWouldReplace(backup)) {
      replace = await _confirm(
        context,
        title: 'Replace Database?',
        message: '$backup already exists. Replace it with this backup?',
      );
      if (!replace || !context.mounted) {
        return;
      }
    }
    await _perform(context, () async {
      await notifier.importBackup(backup, replace: replace);
      if (context.mounted) {
        _showMessage(context, 'Database imported.');
      }
    });
  }

  Future<void> _exportDatabase(BuildContext context, WidgetRef ref) async {
    await _perform(context, () async {
      final location = await ref
          .read(databaseManagerProvider.notifier)
          .exportCurrentDatabase();
      if (context.mounted) {
        _showMessage(context, 'Database exported to $location');
      }
    });
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    await _perform(context, () async {
      final location = await ref
          .read(databaseManagerProvider.notifier)
          .exportTransactionsCsv();
      if (context.mounted) {
        _showMessage(context, 'CSV exported to $location');
      }
    });
  }

  Future<void> _clearTransactions(BuildContext context, WidgetRef ref) async {
    final confirmed = await _confirm(
      context,
      title: 'Clear All Transactions?',
      message: 'This will permanently delete every transaction.',
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    await _perform(context, () async {
      await ref.read(databaseManagerProvider.notifier).clearTransactions();
      if (context.mounted) {
        _showMessage(context, 'All transactions deleted.');
      }
    });
  }

  Future<String?> _requestName(
    BuildContext context, {
    required String title,
    String initialValue = '',
  }) async {
    final controller = TextEditingController(text: initialValue);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Database name'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _perform(
    BuildContext context,
    Future<void> Function() operation,
  ) async {
    try {
      await operation();
    } on Object catch (error) {
      if (context.mounted) {
        _showMessage(context, 'Operation failed: $error');
      }
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
