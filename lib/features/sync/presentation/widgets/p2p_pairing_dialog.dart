import 'package:minimal_pocket_finance_app/core/notifications/app_snackbar_service.dart';
import 'package:minimal_pocket_finance_app/core/theme/app_spacing.dart';
import 'package:minimal_pocket_finance_app/core/theme/theme_context_extensions.dart';
import 'package:minimal_pocket_finance_app/features/sync/application/p2p_sync_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    formats: const <BarcodeFormat>[BarcodeFormat.qrCode],
  );

  String? _generatedKey;
  String? _lastScannedKey;
  bool _isGenerating = false;
  bool _hasScanned = false;
  bool _isConnecting = false;
  bool _showDebugInfo = false;
  bool _scannerStarted = false;
  int _scannedCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _initHostKey();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 1) {
      if (mounted) {
        setState(() {
          _hasScanned = false;
        });
      }
      _ensureScannerReady();
    } else {
      _scannerController.stop();
      _scannerStarted = false;
    }
  }

  // Ensure the scanner controller is initialized before starting
  Future<void> _ensureScannerReady() async {
    // Guard against multiple start calls
    if (_scannerStarted) return;
    const maxAttempts = 20;
    int attempts = 0;
    while (attempts < maxAttempts) {
      try {
        await _scannerController.start();
        _scannerStarted = true;
        break;
      } catch (_) {
        await Future.delayed(const Duration(milliseconds: 200));
        attempts++;
      }
    }
    if (attempts >= maxAttempts) {
      _scannerStarted = false;
      if (mounted) {
        ref.read(appSnackbarProvider).showError('Camera failed to initialize');
      }
    }
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

  Future<void> _onScannedKey(String scannedKey) async {
    if (_hasScanned) return;
    final trimmedKey = scannedKey.trim();
    if (trimmedKey.isEmpty) return;

    setState(() {
      _hasScanned = true;
      _scannedCount++;
      _lastScannedKey = trimmedKey;
      _inputKeyController.text = trimmedKey;
    });

    ref.read(appSnackbarProvider).showSuccess('QR Code scanned: $trimmedKey');
    await _joinWithKey();
  }

  Future<void> _joinWithKey() async {
    final key = _inputKeyController.text.trim();
    if (key.isEmpty) {
      setState(() => _hasScanned = false);
      return;
    }

    setState(() => _isConnecting = true);

    try {
      await ref.read(p2pSyncNotifierProvider.notifier).savePairingCode(key);
      if (mounted) {
        ref.read(appSnackbarProvider).showSuccess('Paired with key: $key');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasScanned = false;
        });
        ref.read(appSnackbarProvider).showError('Pairing failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  void _resetScanner() {
    setState(() {
      _hasScanned = false;
      _lastScannedKey = null;
    });
    _scannerController.start();
    ref.read(appSnackbarProvider).showInfo('Scanner reset. Ready to scan.');
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ref.read(appSnackbarProvider).showInfo('Pairing key copied to clipboard.');
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _inputKeyController.dispose();
    _scannerController.dispose();
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
                Tab(text: 'Show QR'),
                Tab(text: 'Scan QR'),
                Tab(text: 'Enter Key'),
              ],
            ),
            SizedBox(
              height: 310,
              child: TabBarView(
                controller: _tabController,
                children: <Widget>[
                  // Tab 1: QR Code & Key Generator
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        if (_isGenerating || _generatedKey == null)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                            child: CircularProgressIndicator(),
                          )
                        else ...<Widget>[
                          QrImageView(
                            data: _generatedKey!,
                            version: QrVersions.auto,
                            size: 150.0,
                            backgroundColor: Colors.white,
                          ),
                          const SizedBox(height: AppSpacing.xs),
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

                  // Tab 2: Camera Scanner View
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          MobileScanner(
                            controller: _scannerController,
                            errorBuilder: (context, error) {
                              return Container(
                                color: Colors.black,
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    const Icon(
                                      Icons.error_outline,
                                      color: Colors.redAccent,
                                      size: 40,
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      'Camera Error: ${error.errorCode.name}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      error.errorDetails?.message ??
                                          'Please check camera permissions.',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    ElevatedButton.icon(
                                      onPressed: () => _scannerController.start(),
                                      icon: const Icon(Icons.refresh, size: 16),
                                      label: const Text('Retry Camera'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDetect: (BarcodeCapture capture) {
                              if (_hasScanned) return;
                              final barcodes = capture.barcodes;
                              for (final barcode in barcodes) {
                                final code =
                                    barcode.rawValue ?? barcode.displayValue;
                                if (code != null && code.trim().isNotEmpty) {
                                  _onScannedKey(code);
                                  break;
                                }
                              }
                            },
                          ),

                          // Debug Info Overlay Box
                          if (_showDebugInfo)
                            Positioned(
                              top: AppSpacing.xs,
                              left: AppSpacing.xs,
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.xs),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.cyanAccent.withValues(alpha: 0.6),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    const Text(
                                      'DEBUG INFO',
                                      style: TextStyle(
                                        color: Colors.cyanAccent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Scans count: $_scannedCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                    Text(
                                      'Has scanned: $_hasScanned',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                    Text(
                                      'Last code: ${_lastScannedKey ?? "None"}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                    const Text(
                                      'Formats: [QR Code]',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Top Scanner Controls Bar
                          Positioned(
                            top: AppSpacing.xs,
                            right: AppSpacing.xs,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  IconButton(
                                    icon: Icon(
                                      _showDebugInfo
                                          ? Icons.bug_report
                                          : Icons.bug_report_outlined,
                                      color: _showDebugInfo
                                          ? Colors.cyanAccent
                                          : Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                      () => _showDebugInfo = !_showDebugInfo,
                                    ),
                                    tooltip: 'Toggle Debug Overlay',
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.flip_camera_android,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        _scannerController.switchCamera(),
                                    tooltip: 'Switch Camera',
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.flash_on,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        _scannerController.toggleTorch(),
                                    tooltip: 'Toggle Flashlight',
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.refresh,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: _resetScanner,
                                    tooltip: 'Reset Scanner',
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Bottom Status / Scanned Payload Banner
                          Positioned(
                            bottom: AppSpacing.xs,
                            left: AppSpacing.xs,
                            right: AppSpacing.xs,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: _hasScanned
                                    ? Colors.green.shade900.withValues(alpha: 0.9)
                                    : Colors.black87,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _hasScanned
                                      ? Colors.greenAccent
                                      : Colors.white24,
                                ),
                              ),
                              child: Row(
                                children: <Widget>[
                                  Icon(
                                    _hasScanned
                                        ? Icons.check_circle
                                        : Icons.qr_code_scanner,
                                    color: _hasScanned
                                        ? Colors.greenAccent
                                        : Colors.white70,
                                    size: 18,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          _hasScanned
                                              ? 'Scanned: ${_lastScannedKey ?? ""}'
                                              : 'Align QR code within frame',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (_isConnecting)
                                          const Text(
                                            'Connecting & pairing device...',
                                            style: TextStyle(
                                              color: Colors.yellowAccent,
                                              fontSize: 10,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (_hasScanned && !_isConnecting)
                                    TextButton(
                                      onPressed: _resetScanner,
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'Rescan',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Tab 3: Join Device with Key Manual Input
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          'Enter the Pairing Key displayed on the other device:',
                          style: context.text.bodyMedium?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: _inputKeyController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            labelText: 'Pairing Key',
                            hintText: 'e.g. AKM-SYNC-XXXXXX',
                            prefixIcon: const Icon(Icons.vpn_key),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.qr_code_scanner),
                              tooltip: 'Switch to Scanner',
                              onPressed: () {
                                _tabController.animateTo(1);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FilledButton.icon(
                          onPressed: _isConnecting ? null : _joinWithKey,
                          icon: _isConnecting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.link),
                          label: Text(
                            _isConnecting ? 'Pairing...' : 'Pair Device',
                          ),
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
