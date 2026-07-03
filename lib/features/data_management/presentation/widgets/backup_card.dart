import 'package:flutter/material.dart';

class BackupCard extends StatelessWidget {
  const BackupCard({
    required this.backups,
    required this.onBackup,
    required this.onImport,
    required this.onExportDatabase,
    required this.onExportCsv,
    super.key,
  });

  final List<String> backups;
  final VoidCallback onBackup;
  final ValueChanged<String> onImport;
  final VoidCallback onExportDatabase;
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
              'Backup & Restore',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onBackup,
              icon: const Icon(Icons.backup_outlined),
              label: const Text('Backup Current Database'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onExportDatabase,
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('Export Database'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onExportCsv,
              icon: const Icon(Icons.table_view_outlined),
              label: const Text('Export CSV'),
            ),
            const SizedBox(height: 16),
            Text(
              'Import Database',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (backups.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('No backups available'),
              )
            else
              ...backups.map(
                (backup) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(backup),
                  trailing: IconButton(
                    onPressed: () => onImport(backup),
                    icon: const Icon(Icons.download_outlined),
                    tooltip: 'Import',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
