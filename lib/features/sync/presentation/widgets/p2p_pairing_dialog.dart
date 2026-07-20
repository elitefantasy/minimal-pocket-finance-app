import 'package:akm_finance_manager/core/notifications/app_snackbar_service.dart';
import 'package:akm_finance_manager/core/theme/app_spacing.dart';
import 'package:akm_finance_manager/core/theme/theme_context_extensions.dart';
import 'package:akm_finance_manager/features/sync/application/p2p_sync_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Modal dialog for generating pairing QR code or joining a remote peer pairing key.
class P2PPairingDialog extends ConsumerStatefulWidget {
  const P2PPairingDialog({super.key});

  @override
  ConsumerState<P2PPairingDialog> createState() => _P2PPairingDialogState();
}

class _P2PPairingDialogState extends ConsumerState<P2PPairingDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _inputKeyController = TextEditingController();
  String? _generatedKey;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initHostKey();
  }

  Future<void> _initHostKey() async {
    final currentSyncState = ref.read(p2pSyncNotifierProvider).valueOrNull;
    if (currentSyncState?.pairingCode != null) {
      setState(() => _generatedKey = currentSyncState!.pairingCode);
    } else {
      _generateNewKey();
    }
  }

  Future<void> _generateNewKey() async {
    setState(() => _isGenerating = true);
    try {
      final key = await ref
          .read(p2pSyncNotifierProvider.notifier)
          .createPairingCode();
      if (mounted) {
        setState(() => _generatedKey = key);
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _joinWithKey() async {
    final key = _inputKeyController.text.trim();
    if (key.isEmpty) return;

    await ref.read(p2pSyncNotifierProvider.notifier).savePairingCode(key);

    if (mounted) {
      ref.read(appSnackbarProvider).showSuccess('Paired with key $key');
      Navigator.of(context).pop();
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ref.read(appSnackbarProvider).showInfo('Pairing key copied to clipboard.');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _inputKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Pair Devices (P2P Sync)', style: context.text.titleLarge),
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TabBar(
              controller: _tabController,
              tabs: const <Widget>[
                Tab(text: 'Show QR Code'),
                Tab(text: 'Enter Key'),
              ],
            ),
            SizedBox(
              height: 320,
              child: TabBarView(
                controller: _tabController,
                children: <Widget>[
                  // Tab 1: QR Code & Key Generator
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        if (_isGenerating || _generatedKey == null)
                          const CircularProgressIndicator()
                        else ...<Widget>[
                          QrImageView(
                            data: _generatedKey!,
                            version: QrVersions.auto,
                            size: 180.0,
                            backgroundColor: Colors.white,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          SelectableText(
                            _generatedKey!,
                            style: context.text.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              TextButton.icon(
                                onPressed: () => _copyToClipboard(_generatedKey!),
                                icon: const Icon(Icons.copy, size: 16),
                                label: const Text('Copy Key'),
                              ),
                              IconButton(
                                onPressed: _generateNewKey,
                                icon: const Icon(Icons.refresh, size: 18),
                                tooltip: 'Generate New Key',
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Tab 2: Join Device with Key
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          'Scan QR code or enter the 16-character Pairing Key displayed on Device 1:',
                          style: context.text.bodyMedium?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextField(
                          controller: _inputKeyController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Pairing Key',
                            hintText: 'e.g. AKM-SYNC-XXXXXX',
                            prefixIcon: Icon(Icons.vpn_key),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        FilledButton.icon(
                          onPressed: _joinWithKey,
                          icon: const Icon(Icons.link),
                          label: const Text('Pair Device'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
