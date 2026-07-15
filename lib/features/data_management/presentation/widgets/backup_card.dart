import 'package:flutter/material.dart';
import 'package:akm_finance_manager/core/theme/app_icons.dart';
import 'package:akm_finance_manager/core/theme/app_spacing.dart';
import 'package:akm_finance_manager/core/theme/theme_context_extensions.dart';

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
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('Import / Export', style: context.text.titleMedium),

            const SizedBox(height: AppSpacing.lg),

            FilledButton.icon(
              onPressed: onExportDatabase,
              icon: const Icon(AppIcons.export),
              label: const Text('Export Database'),
            ),

            const SizedBox(height: AppSpacing.sm),

            FilledButton.icon(
              onPressed: onImport,
              icon: const Icon(AppIcons.importFile),
              label: const Text('Import Database'),
            ),

            const SizedBox(height: AppSpacing.sm),

            FilledButton.icon(
              onPressed: onExportCsv,
              icon: const Icon(AppIcons.csv),
              label: const Text('Export CSV'),
            ),
          ],
        ),
      ),
    );
  }
}
