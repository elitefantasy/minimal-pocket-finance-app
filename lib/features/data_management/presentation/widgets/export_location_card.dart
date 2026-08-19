import 'package:flutter/material.dart';
import 'package:minimal_pocket_finance_app/core/theme/app_icons.dart';
import 'package:minimal_pocket_finance_app/core/theme/app_spacing.dart';
import 'package:minimal_pocket_finance_app/core/theme/theme_context_extensions.dart';

/// Card widget showing the default/custom export folder location and options to change or reset it.
class ExportLocationCard extends StatelessWidget {
  const ExportLocationCard({
    required this.exportPath,
    required this.isCustomPath,
    required this.onChangeLocation,
    required this.onResetToDefault,
    super.key,
  });

  final String exportPath;
  final bool isCustomPath;
  final VoidCallback onChangeLocation;
  final VoidCallback onResetToDefault;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: [
                Expanded(
                  child: Text('Export Folder', style: context.text.titleMedium),
                ),
                Chip(
                  avatar: Icon(
                    isCustomPath ? AppIcons.category : AppIcons.export,
                    size: 16,
                  ),
                  label: Text(
                    isCustomPath ? 'Custom' : 'Default (Downloads)',
                    style: context.text.labelSmall,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            SelectableText(
              exportPath,
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onChangeLocation,
                    icon: const Icon(AppIcons.export),
                    label: const Text('Change Export Folder'),
                  ),
                ),
                if (isCustomPath) ...[
                  const SizedBox(width: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: onResetToDefault,
                    icon: const Icon(AppIcons.restore),
                    label: const Text('Reset'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
