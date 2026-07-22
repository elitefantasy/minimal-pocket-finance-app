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
                // Connection status row
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
                    if (!syncState.isSignalingConnected)
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        tooltip: 'Retry Connection',
                        onPressed: () => ref
                            .read(p2pSyncNotifierProvider.notifier)
                            .retryConnect(),
                      ),
                    TextButton(
                      onPressed: () => ref
                          .read(p2pSyncNotifierProvider.notifier)
                          .unpair(),
                      child: const Text('Unpair'),
                    ),
                  ],
                ),

                // Peer device info chip
                if (syncState.remoteDeviceName != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  _PeerDeviceChip(
                    deviceName: syncState.remoteDeviceName!,
                    lastSeen: syncState.remoteLastUpdated,
                    isOnline: syncState.isSignalingConnected &&
                        syncState.isRemoteChangeDetected,
                  ),
                ],

                // Syncing animation
                if (syncState.isSyncing) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  _SyncProgressBanner(
                    statusMessage: syncState.statusMessage,
                    remoteDeviceName: syncState.remoteDeviceName,
                  ),
                ]
                // Remote Change Detection Alert Banner
                else if (syncState.isRemoteChangeDetected) ...<Widget>[
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
                          onPressed: () => ref
                              .read(p2pSyncNotifierProvider.notifier)
                              .syncNow(),
                          child: const Text('Sync Now'),
                        ),
                      ],
                    ),
                  ),
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

/// Shows a chip with the paired peer device name and online status.
class _PeerDeviceChip extends StatelessWidget {
  const _PeerDeviceChip({
    required this.deviceName,
    this.lastSeen,
    this.isOnline = false,
  });

  final String deviceName;
  final DateTime? lastSeen;
  final bool isOnline;

  String _formatLastSeen() {
    if (lastSeen == null) return '';
    final diff = DateTime.now().difference(lastSeen!);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  IconData _deviceIcon() {
    final lower = deviceName.toLowerCase();
    if (lower.contains('android')) return Icons.phone_android;
    if (lower.contains('ios') || lower.contains('iphone')) return Icons.phone_iphone;
    if (lower.contains('windows')) return Icons.laptop_windows;
    if (lower.contains('mac')) return Icons.laptop_mac;
    if (lower.contains('linux')) return Icons.computer;
    return Icons.devices;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest.withAlpha(120),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            _deviceIcon(),
            size: 16,
            color: context.colors.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            deviceName,
            style: context.text.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOnline
                  ? context.semantic.success
                  : context.colors.outline,
            ),
          ),
          if (lastSeen != null) ...<Widget>[
            const SizedBox(width: AppSpacing.xs),
            Text(
              _formatLastSeen(),
              style: context.text.labelSmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Animated sync progress banner shown while a sync is in progress.
class _SyncProgressBanner extends StatelessWidget {
  const _SyncProgressBanner({
    required this.statusMessage,
    this.remoteDeviceName,
  });

  final String statusMessage;
  final String? remoteDeviceName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: context.colors.onTertiaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  remoteDeviceName != null
                      ? 'Syncing with $remoteDeviceName...'
                      : 'Syncing with peer device...',
                  style: context.text.titleSmall?.copyWith(
                    color: context.colors.onTertiaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.only(left: 34),
            child: Text(
              statusMessage,
              style: context.text.bodySmall?.copyWith(
                color: context.colors.onTertiaryContainer.withAlpha(180),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              minHeight: 4,
              backgroundColor:
                  context.colors.onTertiaryContainer.withAlpha(40),
              color: context.colors.onTertiaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
