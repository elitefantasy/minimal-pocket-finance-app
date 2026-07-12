import 'package:akm_finance_manager/core/constants/app_constants.dart';
import 'package:akm_finance_manager/core/database/database_helper.dart';
import 'package:akm_finance_manager/shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:akm_finance_manager/app/providers.dart';
import 'package:akm_finance_manager/core/notifications/app_snackbar_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akm_finance_manager/core/utils/package_info_provider.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
	final packageInfoAsync = ref.watch(packageInfoProvider); 

    return AppScaffold(
      title: 'About',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: <Widget>[
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundColor: colorScheme.onPrimaryContainer,
                    child: const Icon(Icons.account_balance_wallet_outlined),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  packageInfoAsync.when(
					  loading: () => Text(
						'Loading version...',
						style: Theme.of(context).textTheme.bodyMedium?.copyWith(
						  color: colorScheme.onSurfaceVariant,
						),
						textAlign: TextAlign.center,
					  ),
					  error: (_, __) => Text(
						'Version Unknown '
						'\u2022 Database v${DatabaseHelper.databaseVersion}',
						style: Theme.of(context).textTheme.bodyMedium?.copyWith(
						  color: colorScheme.onSurfaceVariant,
						),
						textAlign: TextAlign.center,
					  ),
					  data: (packageInfo) => Text(
						'Version ${packageInfo.version} '
						'\u2022 Database v${DatabaseHelper.databaseVersion}',
						style: Theme.of(context).textTheme.bodyMedium?.copyWith(
						  color: colorScheme.onSurfaceVariant,
						),
						textAlign: TextAlign.center,
					  ),
					),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _AboutSection(
            title: 'What\u2019s New',
            child: const Column(
              children: <Widget>[
                _FeatureItem('Offline-first finance tracking'),
                _FeatureItem('Multi-database support'),
                _FeatureItem('Add, edit, and delete transactions'),
                _FeatureItem('Recurring transactions'),
                _FeatureItem('Categories management'),
                _FeatureItem('Search, filter, and sort'),
                _FeatureItem('Database and CSV export/import'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _AboutSection(
            title: 'Export locations',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(AppConstants.exportLocationDescription),
                const SizedBox(height: 12),
                _LocationItem(
                  icon: Icons.storage_outlined,
                  label: 'Database exports',
                  path:
                      '${AppConstants.appName}/${AppConstants.databaseExportFolder}',
                ),
                const SizedBox(height: 8),
                _LocationItem(
                  icon: Icons.table_chart_outlined,
                  label: 'CSV exports',
                  path:
                      '${AppConstants.appName}/${AppConstants.csvExportFolder}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _AboutSection(
            title: 'Created by',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(AppConstants.creatorCredit),
                const SizedBox(height: 8),                
				ListTile(
				  contentPadding: EdgeInsets.zero,
				  leading: const Icon(Icons.code),
				  title: const Text('GitHub'),
				  subtitle: const Text(AppConstants.githubUrl,
				  ),
				  trailing: const Icon(Icons.open_in_new),
				  onTap: () async {
					  final opened = await ref
						  .read(urlLauncherServiceProvider)
						  .openUrl(AppConstants.githubUrl);

					  if (!opened && context.mounted) {
						ref
							.read(appSnackbarProvider)
							.showError('Unable to open GitHub.');
					  }
					},
				)
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          const Icon(Icons.check_circle_outline, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

class _LocationItem extends StatelessWidget {
  const _LocationItem({
    required this.icon,
    required this.label,
    required this.path,
  });

  final IconData icon;
  final String label;
  final String path;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(path, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
