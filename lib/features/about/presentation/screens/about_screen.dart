import 'package:minimal_pocket_finance_app/app/providers.dart';
import 'package:minimal_pocket_finance_app/core/constants/app_constants.dart';
import 'package:minimal_pocket_finance_app/core/database/database_helper.dart';
import 'package:minimal_pocket_finance_app/core/notifications/app_snackbar_service.dart';
import 'package:minimal_pocket_finance_app/core/theme/app_icons.dart';
import 'package:minimal_pocket_finance_app/core/theme/app_sizes.dart';
import 'package:minimal_pocket_finance_app/core/theme/app_spacing.dart';
import 'package:minimal_pocket_finance_app/core/theme/theme_context_extensions.dart';
import 'package:minimal_pocket_finance_app/core/utils/package_info_provider.dart';
import 'package:minimal_pocket_finance_app/shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packageInfoAsync = ref.watch(packageInfoProvider);

    return AppScaffold(
      title: 'About',
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.card),
              child: Column(
                children: <Widget>[
                  CircleAvatar(
                    radius: AppSizes.avatarMedium / 2,
                    backgroundColor: context.colors.primaryContainer,
                    foregroundColor: context.colors.onPrimaryContainer,
                    child: const Icon(AppIcons.wallet),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    AppConstants.appName,
                    style: context.text.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  packageInfoAsync.when(
                    loading: () => _VersionText('Loading version...'),
                    error: (error, stackTrace) => _VersionText(
                      'Version Unknown • Database v${DatabaseHelper.databaseVersion}',
                    ),
                    data: (packageInfo) => _VersionText(
                      'Version ${packageInfo.version} • Database v${DatabaseHelper.databaseVersion}',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _AboutSection(
            title: 'What’s New',
            child: Column(
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
          const SizedBox(height: AppSpacing.lg),
          _AboutSection(
            title: 'Export locations',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  AppConstants.exportLocationDescription,
                  style: context.text.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _LocationItem(
                  icon: AppIcons.database,
                  label: 'Database exports',
                  path:
                      '${AppConstants.appName}/${AppConstants.databaseExportFolder}',
                ),
                const SizedBox(height: AppSpacing.sm),
                _LocationItem(
                  icon: AppIcons.csv,
                  label: 'CSV exports',
                  path:
                      '${AppConstants.appName}/${AppConstants.csvExportFolder}',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _AboutSection(
            title: 'Created by',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  AppConstants.creatorCredit,
                  style: context.text.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(AppIcons.github),
                  title: Text('GitHub', style: context.text.titleSmall),
                  subtitle: Text(AppConstants.githubUrl),
                  trailing: const Icon(AppIcons.openInNew),
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VersionText extends StatelessWidget {
  const _VersionText(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: context.text.bodyMedium?.copyWith(
        color: context.colors.onSurfaceVariant,
      ),
      textAlign: TextAlign.center,
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
        padding: const EdgeInsets.all(AppSpacing.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: context.text.titleMedium),
            const SizedBox(height: AppSpacing.md),
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
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          Icon(
            AppIcons.checkOutlined,
            size: AppIcons.smallSize,
            color: context.semantic.success,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(label, style: context.text.bodyMedium)),
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
        Icon(icon, size: AppIcons.smallSize, color: context.colors.secondary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label, style: context.text.titleSmall),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                path,
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
