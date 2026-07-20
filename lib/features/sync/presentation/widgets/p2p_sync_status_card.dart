import 'package:akm_finance_manager/core/theme/app_icons.dart';
import 'package:akm_finance_manager/core/theme/app_spacing.dart';
import 'package:akm_finance_manager/core/theme/theme_context_extensions.dart';
import 'package:akm_finance_manager/features/sync/application/p2p_sync_notifier.dart';
import 'package:akm_finance_manager/features/sync/presentation/widgets/p2p_pairing_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Interactive UI Card for P2P Device Synchronization status and triggers.
class P2PSyncStatusCard extends ConsumerWidget {
  const P2PSyncStatusCard({super.key});

  void _openPairingDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => const P2PPairingDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStateAsync = ref.watch(p2pSyncNotifierProvider);

    return syncStateAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (err, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text('Sync error: $err'),
        ),
      ),
      data: (syncState) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Header Row
              Row(
                children: <Widget>[
                  Icon(
                    Icons.sync_lock_outlined,
                    size: AppIcons.mediumSize,
                    color: context.colors.primary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'P2P Device Sync',
                          style: context.text.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Direct WebRTC E2EE • Zero Cloud Storage',
                          style: context.text.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _openPairingDialog(context),
                    icon: const Icon(Icons.qr_code_2),
                    tooltip: 'Pair / QR Code',
                  ),
                ],
              ),
              const Divider(height: AppSpacing.lg),

              // Pairing Status
              if (!syncState.isPaired) ...<Widget>[
                Text(
                  'No devices paired yet. Pair with your phone or PC to automatically detect changes.',
                  style: context.text.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: () => _openPairingDialog(context),
                  icon: const Icon(Icons.phonelink_setup),
                  label: const Text('Pair Device with QR Code'),
                ),
              ] else ...<Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: syncState.isSignalingConnected
                            ? context.semantic.success
                            : context.colors.error,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        syncState.statusMessage,
                        style: context.text.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref
                          .read(p2pSyncNotifierProvider.notifier)
                          .unpair(),
                      child: const Text('Unpair'),
                    ),
                  ],
                ),

                // Remote Change Detection Alert Banner
                if (syncState.isRemoteChangeDetected) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: context.colors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.system_update_alt,
                          color: context.colors.onPrimaryContainer,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Updates Detected on ${syncState.remoteDeviceName ?? 'Peer Device'}',
                                style: context.text.titleSmall?.copyWith(
                                  color: context.colors.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Tap to stream and merge changes.',
                                style: context.text.bodySmall?.copyWith(
                                  color: context.colors.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton(
                          onPressed: syncState.isSyncing
                              ? null
                              : () => ref
                                  .read(p2pSyncNotifierProvider.notifier)
                                  .syncNow(),
                          child: Text(
                            syncState.isSyncing ? 'Syncing...' : 'Sync Now',
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (syncState.isSyncing) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  const LinearProgressIndicator(),
                ] else ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: () => ref
                        .read(p2pSyncNotifierProvider.notifier)
                        .syncNow(),
                    icon: const Icon(Icons.sync),
                    label: const Text('Sync Now with Peer'),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
