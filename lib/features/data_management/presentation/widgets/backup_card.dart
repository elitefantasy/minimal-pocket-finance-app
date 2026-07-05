import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// BackupCard
///
/// This card is responsible only for Data Export / Import actions.
///
/// Previous architecture:
///     • Backup Current Database
///     • Internal Backup List
///     • Import Selected Backup
///
/// New architecture:
///     • Export Database (SAF)
///     • Import Database (SAF)
///     • Export CSV (SAF)
///
/// Notice:
/// There is NO backup list anymore.
/// Android's Storage Access Framework lets the user choose any database file.
/// ---------------------------------------------------------------------------
class BackupCard extends StatelessWidget {
  const BackupCard({
    required this.onImport,
    required this.onExportDatabase,
    required this.onExportCsv,
    super.key,
  });

  /// Opens Android file picker.
  final VoidCallback onImport;

  /// Exports current database.
  final VoidCallback onExportDatabase;

  /// Exports transactions CSV.
  final VoidCallback onExportCsv;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Import / Export',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: 16),

            FilledButton.icon(
              onPressed: onExportDatabase,
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('Export Database'),
            ),

            const SizedBox(height: 8),

            FilledButton.icon(
              onPressed: onImport,
              icon: const Icon(Icons.download_outlined),
              label: const Text('Import Database'),
            ),

            const SizedBox(height: 8),

            FilledButton.icon(
              onPressed: onExportCsv,
              icon: const Icon(Icons.table_view_outlined),
              label: const Text('Export CSV'),
            ),
          ],
        ),
      ),
    );
  }
}