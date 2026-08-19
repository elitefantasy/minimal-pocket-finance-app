import 'package:minimal_pocket_finance_app/core/notifications/app_snackbar_service.dart';
import 'package:minimal_pocket_finance_app/core/theme/app_icons.dart';
import 'package:minimal_pocket_finance_app/core/theme/app_spacing.dart';
import 'package:minimal_pocket_finance_app/core/theme/theme_context_extensions.dart';
import 'package:minimal_pocket_finance_app/features/data_management/application/database_manager_notifier.dart';
import 'package:minimal_pocket_finance_app/features/data_management/presentation/widgets/backup_card.dart';
import 'package:minimal_pocket_finance_app/features/data_management/presentation/widgets/database_card.dart';
import 'package:minimal_pocket_finance_app/features/data_management/presentation/widgets/database_tile.dart';
import 'package:minimal_pocket_finance_app/features/sync/presentation/widgets/p2p_sync_status_card.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minimal_pocket_finance_app/features/data_management/presentation/widgets/export_location_card.dart';
import 'package:minimal_pocket_finance_app/shared/widgets/app_scaffold.dart';

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
          padding: const EdgeInsets.all(AppSpacing.page),
          children: <Widget>[
            DatabaseCard(databaseName: state.currentDatabase),
            const SizedBox(height: AppSpacing.section),
            const P2PSyncStatusCard(),
            const SizedBox(height: AppSpacing.section),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Available Databases',
                    style: context.text.titleLarge,
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _createDatabase(context, ref),
                  icon: const Icon(AppIcons.add),
                  label: const Text('Create'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
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
            const SizedBox(height: AppSpacing.section),
            ExportLocationCard(
              exportPath: state.exportPath,
              isCustomPath: state.isCustomExportPath,
              onChangeLocation: () => _changeExportLocation(context, ref),
              onResetToDefault: () => _resetExportLocation(context, ref),
            ),
            const SizedBox(height: AppSpacing.section),
            BackupCard(
              onImport: () => _import(context, ref),
              onExportDatabase: () => _exportDatabase(context, ref),
              onExportCsv: () => _exportCsv(context, ref),
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
    await _perform(context, ref, () async {
      final message = await ref
          .read(databaseManagerProvider.notifier)
          .createDatabase(name);
      if (context.mounted) {
        _showMessage(ref, message ?? 'Database created.');
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
    await _perform(context, ref, () async {
      final message = await ref
          .read(databaseManagerProvider.notifier)
          .renameDatabase(database, name);
      if (context.mounted) {
        _showMessage(ref, message ?? 'Database renamed.');
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
    await _perform(context, ref, () async {
      final message = await ref
          .read(databaseManagerProvider.notifier)
          .deleteDatabase(database);
      if (context.mounted) {
        _showMessage(ref, message ?? 'Database deleted.');
      }
    });
  }

  Future<void> _switchDatabase(
    BuildContext context,
    WidgetRef ref,
    String database,
  ) async {
    await _perform(context, ref, () async {
      await ref.read(databaseManagerProvider.notifier).switchDatabase(database);
      if (context.mounted) {
        _showMessage(ref, 'Switched to $database.');
      }
    });
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(databaseManagerProvider.notifier);

    try {
      final database = await notifier.importDatabase(replace: false);

      if (database == null || !context.mounted) {
        return;
      }

      _showMessage(ref, 'Database imported.');
    } on StateError {
      if (!context.mounted) {
        return;
      }

      final replace = await _confirm(
        context,
        title: 'Replace Database?',
        message: 'A database with this name already exists.\nReplace it?',
      );

      if (!replace || !context.mounted) {
        return;
      }

      await notifier.importDatabase(replace: true);

      if (context.mounted) {
        _showMessage(ref, 'Database replaced.');
      }
    }
  }

  Future<void> _exportDatabase(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(databaseManagerProvider.notifier);
    final defaultFileName = await notifier.getDefaultExportFileName();

    if (!context.mounted) return;

    final exportName = await _requestName(
      context,
      title: 'Export Database',
      initialValue: defaultFileName,
    );

    if (exportName == null || !context.mounted) {
      return;
    }

    await _perform(context, ref, () async {
      final result = await notifier.exportCurrentDatabase(
        customFileName: exportName,
      );

      _showMessage(
        ref,
        'Database exported successfully.\n\n'
        'Location:\n${result.absolutePath ?? result.relativePath}',
      );
    });
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    await _perform(context, ref, () async {
      final result = await ref
          .read(databaseManagerProvider.notifier)
          .exportTransactionsCsv();

      _showMessage(
        ref,
        'CSV exported successfully.\n\nLocation:\n${result.relativePath}',
      );
    });
  }

  Future<String?> _requestName(
    BuildContext context, {
    required String title,
    String initialValue = '',
  }) async {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        // The controller belongs to this dialog only.
        final controller = TextEditingController(text: initialValue);

        return AlertDialog(
          title: Text(title, style: context.text.titleLarge),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Database name'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(controller.text.trim());
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
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
            content: Text(
              message,
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
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
    WidgetRef ref,
    Future<void> Function() operation,
  ) async {
    try {
      await operation();
    } on Object catch (error) {
      if (context.mounted) {
        ref.read(appSnackbarProvider).showError('Operation failed: $error');
      }
    }
  }

  void _showMessage(WidgetRef ref, String message) {
    ref.read(appSnackbarProvider).showInfo(message);
  }

  Future<void> _changeExportLocation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Export Folder',
    );

    if (selectedDirectory == null || !context.mounted) {
      return;
    }

    final moveExistingFiles = await _promptExportMigration(
      context,
      title: 'Move Existing Exports to New Folder?',
      message:
          'Would you like to move your previously exported database backups and CSV files to:\n\n$selectedDirectory?',
    );

    if (moveExistingFiles == null || !context.mounted) {
      return;
    }

    await _perform(context, ref, () async {
      await ref.read(databaseManagerProvider.notifier).changeExportFolder(
            newPath: selectedDirectory,
            moveExistingFiles: moveExistingFiles,
          );
      if (context.mounted) {
        _showMessage(ref, 'Export folder changed to:\n$selectedDirectory');
      }
    });
  }

  Future<void> _resetExportLocation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final moveExistingFiles = await _promptExportMigration(
      context,
      title: 'Reset Export Folder?',
      message:
          'Would you like to move your exported files back to default Downloads directory?',
    );

    if (moveExistingFiles == null || !context.mounted) {
      return;
    }

    await _perform(context, ref, () async {
      await ref
          .read(databaseManagerProvider.notifier)
          .resetExportFolder(moveExistingFiles: moveExistingFiles);
      if (context.mounted) {
        _showMessage(ref, 'Export folder reset to default.');
      }
    });
  }

  Future<bool?> _promptExportMigration(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    return showDialog<bool?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title, style: context.text.titleLarge),
        content: Text(
          message,
          style: context.text.bodyMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('New Folder Only'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Move Files'),
          ),
        ],
      ),
    );
  }
}
