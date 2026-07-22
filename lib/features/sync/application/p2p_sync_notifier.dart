import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:akm_finance_manager/app/providers.dart';
import 'package:akm_finance_manager/features/transactions/application/transaction_notifier.dart';
import 'package:akm_finance_manager/models/attachment.dart';
import 'package:akm_finance_manager/models/transaction.dart';
import 'package:akm_finance_manager/services/attachment_service.dart';
import 'package:akm_finance_manager/services/p2p/p2p_crypto_service.dart';
import 'package:akm_finance_manager/services/p2p/p2p_logger.dart';
import 'package:akm_finance_manager/services/p2p/signaling_client.dart';
import 'package:akm_finance_manager/services/p2p/webrtc_sync_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class P2PSyncState {
  const P2PSyncState({
    this.isPaired = false,
    this.pairingCode,
    this.isSignalingConnected = false,
    this.isRemoteChangeDetected = false,
    this.remoteDeviceName,
    this.remoteLastUpdated,
    this.isSyncing = false,
    this.statusMessage = 'Disconnected',
  });

  final bool isPaired;
  final String? pairingCode;
  final bool isSignalingConnected;
  final bool isRemoteChangeDetected;
  final String? remoteDeviceName;
  final DateTime? remoteLastUpdated;
  final bool isSyncing;
  final String statusMessage;

  P2PSyncState copyWith({
    bool? isPaired,
    String? pairingCode,
    bool? isSignalingConnected,
    bool? isRemoteChangeDetected,
    String? remoteDeviceName,
    DateTime? remoteLastUpdated,
    bool? isSyncing,
    String? statusMessage,
  }) {
    return P2PSyncState(
      isPaired: isPaired ?? this.isPaired,
      pairingCode: pairingCode ?? this.pairingCode,
      isSignalingConnected: isSignalingConnected ?? this.isSignalingConnected,
      isRemoteChangeDetected:
          isRemoteChangeDetected ?? this.isRemoteChangeDetected,
      remoteDeviceName: remoteDeviceName ?? this.remoteDeviceName,
      remoteLastUpdated: remoteLastUpdated ?? this.remoteLastUpdated,
      isSyncing: isSyncing ?? this.isSyncing,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

class P2PSyncNotifier extends AsyncNotifier<P2PSyncState> {
  final P2PCryptoService _cryptoService = P2PCryptoService();
  final SignalingClient _signalingClient = SignalingClient(debug: true);
  final WebRTCSyncService _webrtcService = WebRTCSyncService();
  final AttachmentService _attachmentService = AttachmentService();

  static const String _prefPairingKey = 'p2p_pairing_code';
  static const String _prefDeviceName = 'p2p_device_name';

  /// Heartbeat interval for presence broadcasts.
  ///
  /// ntfy.sh public tier allows ~250 messages/day. At 10 minutes per heartbeat,
  /// two devices produce ~288 messages/day, which is within limits and leaves
  /// headroom for signaling messages (offer/answer/ICE).
  static const Duration _heartbeatInterval = Duration(minutes: 10);

  late String _deviceId;
  Timer? _heartbeatTimer;
  Completer<bool>? _syncCompleter;
  Timer? _syncTimeout;

  @override
  Future<P2PSyncState> build() async {
    unawaited(P2PLogger.init());
    final prefs = await SharedPreferences.getInstance();
    final savedPairingCode = prefs.getString(_prefPairingKey);

    var deviceId = prefs.getString(_prefDeviceName);
    if (deviceId == null ||
        deviceId.isEmpty ||
        deviceId == 'localhost' ||
        deviceId == 'localhost.localdomain') {
      final randomSuffix = (Random().nextInt(900000) + 100000).toString();
      final platformName = Platform.isAndroid
          ? 'Android'
          : Platform.isIOS
              ? 'iOS'
              : Platform.isWindows
                  ? 'Windows'
                  : Platform.operatingSystem;
      deviceId = '$platformName-$randomSuffix';
      await prefs.setString(_prefDeviceName, deviceId);
    }
    _deviceId = deviceId;
    _log('Device ID: $_deviceId');

    _setupSignalingListeners();
    _setupWebRTCListeners();

    if (savedPairingCode != null && savedPairingCode.isNotEmpty) {
      unawaited(_connectSignaling(savedPairingCode));
      return P2PSyncState(
        isPaired: true,
        pairingCode: savedPairingCode,
        statusMessage: 'Connecting to P2P signaling...',
      );
    }

    return const P2PSyncState();
  }

  void _setupSignalingListeners() {
    _signalingClient.onConnected = () {
      _log('Signaling connected. Starting heartbeat.');
      state = AsyncData(
        state.valueOrNull?.copyWith(
              isSignalingConnected: true,
              statusMessage: 'Online & Listening for peer',
            ) ??
            const P2PSyncState(
              isSignalingConnected: true,
              statusMessage: 'Online & Listening for peer',
            ),
      );
      _startHeartbeat();
    };

    _signalingClient.onDisconnected = () {
      _log('Signaling disconnected.');
      state = AsyncData(
        state.valueOrNull?.copyWith(
              isSignalingConnected: false,
              statusMessage: 'Disconnected from signaling',
            ) ??
            const P2PSyncState(
              isSignalingConnected: false,
              statusMessage: 'Disconnected from signaling',
            ),
      );
      _stopHeartbeat();
    };

    _signalingClient.onPresenceReceived = (senderId, encryptedPayload) {
      final code = state.valueOrNull?.pairingCode;
      if (code == null) return;

      final payload = _cryptoService.decryptPayload(encryptedPayload, code);
      if (payload == null) {
        _log('Failed to decrypt presence from $senderId (wrong key?).');
        return;
      }

      final remoteDeviceName = payload['device'] as String? ?? senderId;
      final remoteTimestampIso = payload['timestamp'] as String?;
      final remoteTimestamp = remoteTimestampIso != null
          ? DateTime.tryParse(remoteTimestampIso)
          : null;

      _log('Presence received from $remoteDeviceName.');

      state = AsyncData(
        state.valueOrNull?.copyWith(
              isRemoteChangeDetected: true,
              remoteDeviceName: remoteDeviceName,
              remoteLastUpdated: remoteTimestamp,
              statusMessage: 'Peer online: $remoteDeviceName',
            ) ??
            P2PSyncState(
              isRemoteChangeDetected: true,
              remoteDeviceName: remoteDeviceName,
              remoteLastUpdated: remoteTimestamp,
              statusMessage: 'Peer online: $remoteDeviceName',
            ),
      );
    };

    _signalingClient.onSignalReceived = (senderId, signalData) async {
      final type = signalData['type'] as String?;
      _log('Signal received from $senderId: type=$type');

      try {
        if (type == 'offer') {
          final answerData = await _webrtcService.handleOffer(signalData);
          // Await the answer publish so ICE candidates queue behind it
          final sent =
              await _signalingClient.sendSignal(answerData, _deviceId);
          if (!sent) {
            _log('WARNING: Failed to publish SDP answer.');
          }
        } else if (type == 'answer') {
          await _webrtcService.handleAnswer(signalData);
        } else if (type == 'candidate') {
          await _webrtcService.handleIceCandidate(signalData);
        } else {
          _log('Unknown signal type: $type');
        }
      } catch (e) {
        _log('Error handling signal type=$type: $e');
      }
    };
  }

  void _setupWebRTCListeners() {
    _webrtcService.onIceCandidate = (candidateData) {
      // ICE candidates are queued behind offer/answer by SignalingClient's
      // sequential publish queue.
      _signalingClient.sendSignal(candidateData, _deviceId);
    };

    _webrtcService.onDataReceived = (encryptedData) async {
      final code = state.valueOrNull?.pairingCode;
      if (code == null) return;

      final payload = _cryptoService.decryptPayload(encryptedData, code);
      if (payload == null) {
        _log('Failed to decrypt data channel message.');
        return;
      }

      final action = payload['action'] as String?;
      _log('Data channel action received: $action');

      if (action == 'request_sync') {
        await _sendLocalDataToPeer();
      } else if (action == 'sync_payload') {
        await _processIncomingSyncPayload(payload);
      }
    };

    _webrtcService.onConnectionStateChanged = (isOpen) {
      _log('Data channel ${isOpen ? "opened" : "closed"}.');
    };
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      broadcastPresence();
    });
    // Send initial presence immediately
    broadcastPresence();
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> broadcastPresence() async {
    final code = state.valueOrNull?.pairingCode;
    if (code == null || !_signalingClient.isConnected) return;

    final payload = <String, dynamic>{
      'device': _deviceId,
      'timestamp': DateTime.now().toIso8601String(),
    };

    final encrypted = _cryptoService.encryptPayload(payload, code);
    final sent = await _signalingClient.sendPresence(encrypted, _deviceId);
    if (!sent) {
      _log('Presence broadcast failed.');
    }
  }

  /// Create new pairing key for host device.
  Future<String> createPairingCode() async {
    final code = _cryptoService.generatePairingCode();
    await savePairingCode(code);
    return code;
  }

  /// Save pairing code and join signaling network.
  Future<void> savePairingCode(String code) async {
    final cleanCode = code.toUpperCase().trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefPairingKey, cleanCode);

    state = AsyncData(
      state.valueOrNull?.copyWith(
            isPaired: true,
            pairingCode: cleanCode,
            statusMessage: 'Connecting to P2P signaling...',
          ) ??
          P2PSyncState(
            isPaired: true,
            pairingCode: cleanCode,
            statusMessage: 'Connecting to P2P signaling...',
          ),
    );

    await _connectSignaling(cleanCode);
  }

  Future<void> _connectSignaling(String code) async {
    final roomId = _cryptoService.deriveRoomId(code);
    _log('Connecting signaling for room (truncated): '
        '${roomId.substring(0, 8)}…');
    try {
      await _signalingClient.connect(roomId, _deviceId);
    } catch (e) {
      _log('Signaling connection failed: $e');
      state = AsyncData(
        state.valueOrNull?.copyWith(
              isSignalingConnected: false,
              statusMessage: 'Signaling offline/timeout. Tap to retry.',
            ) ??
            P2PSyncState(
              isPaired: true,
              pairingCode: code,
              isSignalingConnected: false,
              statusMessage: 'Signaling offline/timeout. Tap to retry.',
            ),
      );
    }
  }

  /// Manually retry connecting to signaling network.
  Future<void> retryConnect() async {
    final code = state.valueOrNull?.pairingCode;
    if (code != null && code.isNotEmpty) {
      state = AsyncData(
        state.valueOrNull?.copyWith(
              statusMessage: 'Reconnecting to P2P signaling...',
            ) ??
            P2PSyncState(
              isPaired: true,
              pairingCode: code,
              statusMessage: 'Reconnecting to P2P signaling...',
            ),
      );
      await _connectSignaling(code);
    }
  }

  /// Disconnect and clear pairing key.
  Future<void> unpair() async {
    _stopHeartbeat();
    await _signalingClient.disconnect();
    await _webrtcService.close();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefPairingKey);

    state = const AsyncData(P2PSyncState());
  }

  /// Trigger sync with remote peer.
  Future<void> syncNow() async {
    final current = state.valueOrNull;
    if (current == null || !current.isPaired || current.pairingCode == null) {
      return;
    }

    // Prevent double-sync
    if (current.isSyncing) {
      _log('syncNow skipped: already syncing.');
      return;
    }

    // Fail fast if signaling is not connected
    if (!_signalingClient.isConnected) {
      _log('syncNow aborted: signaling not connected.');
      state = AsyncData(
        current.copyWith(
          statusMessage: 'Cannot sync: signaling offline. Tap to retry.',
        ),
      );
      return;
    }

    state = AsyncData(
      current.copyWith(
        isSyncing: true,
        statusMessage: 'Creating WebRTC offer...',
      ),
    );

    // Create a completer that _processIncomingSyncPayload will complete
    _syncCompleter = Completer<bool>();

    try {
      final offerData = await _webrtcService.createOffer();
      _log('SDP offer created, publishing via signaling...');

      // Await the offer publish so ICE candidates queue behind it
      final offerSent =
          await _signalingClient.sendSignal(offerData, _deviceId);
      if (!offerSent) {
        throw StateError('Failed to publish SDP offer via signaling.');
      }

      state = AsyncData(
        state.valueOrNull?.copyWith(
              statusMessage: 'Waiting for peer to respond...',
            ) ??
            current,
      );

      // Use the completer-based wait instead of busy-poll
      final channelOpened = await _webrtcService.waitForChannelOpen(
        timeout: const Duration(seconds: 20),
      );

      if (channelOpened) {
        _log('Data channel open. Requesting sync data from peer.');
        state = AsyncData(
          state.valueOrNull?.copyWith(
                statusMessage: 'Requesting data from peer...',
              ) ??
              current,
        );

        final requestPayload = <String, dynamic>{'action': 'request_sync'};
        final encryptedReq = _cryptoService.encryptPayload(
          requestPayload,
          current.pairingCode!,
        );
        final sent = await _webrtcService.sendData(encryptedReq);
        if (!sent) {
          throw StateError('Failed to send sync request over data channel.');
        }

        // Start a safety timeout — if peer doesn't respond in 30s, give up
        _syncTimeout?.cancel();
        _syncTimeout = Timer(const Duration(seconds: 30), () {
          if (_syncCompleter != null && !_syncCompleter!.isCompleted) {
            _log('Sync response timed out after 30s.');
            _syncCompleter!.complete(false);
          }
        });

        // Wait for the sync payload to arrive and be processed
        final syncCompleted = await _syncCompleter!.future;
        _syncTimeout?.cancel();
        _syncTimeout = null;

        if (!syncCompleted) {
          state = AsyncData(
            state.valueOrNull?.copyWith(
                  isSyncing: false,
                  statusMessage:
                      'Sync timed out waiting for peer data. Try again.',
                ) ??
                current,
          );
        }
      } else {
        _log('Data channel did not open within timeout.');
        state = AsyncData(
          current.copyWith(
            isSyncing: false,
            statusMessage: 'P2P channel timeout. Peer may be offline.',
          ),
        );
      }
    } catch (e) {
      _log('syncNow error: $e');
      _syncCompleter?.complete(false);
      state = AsyncData(
        current.copyWith(
          isSyncing: false,
          statusMessage: 'Sync error: $e',
        ),
      );
    } finally {
      // Allow data channel buffers to flush before closing WebRTC connection
      await Future<void>.delayed(const Duration(milliseconds: 500));
      _syncCompleter = null;
      await _webrtcService.close();
    }
  }

  Future<void> _sendLocalDataToPeer() async {
    final code = state.valueOrNull?.pairingCode;
    if (code == null) return;

    _log('Sending local transaction data & physical attachments to peer...');
    final txService = ref.read(transactionServiceProvider);
    final transactions = await txService.getAllTransactions();

    final serializedTxList = <Map<String, dynamic>>[];
    for (final tx in transactions) {
      final txMap = tx.toMap();
      if (tx.attachments.isNotEmpty) {
        final attachmentMaps = <Map<String, dynamic>>[];
        for (final att in tx.attachments) {
          final attMap = att.toMap();
          try {
            final file = File(att.filePath);
            if (await file.exists()) {
              var bytes = await file.readAsBytes();
              if (att.isImage) {
                _log('Compressing image attachment "${att.fileName}" (${bytes.length} bytes)...');
                final resized = await _resizeImageBytes(bytes, maxDimension: 400);
                if (resized != null) {
                  bytes = resized;
                  _log('Compressed image thumbnail to ${bytes.length} bytes for fast P2P transfer.');
                }
              }

              // Guardrail: limit individual attachment bytes to 500 KB to keep WebRTC channel fast
              if (bytes.length <= 500 * 1024) {
                attMap['file_bytes_base64'] = base64Encode(bytes);
                _log('Attached physical file "${att.fileName ?? att.filePath}" (${bytes.length} bytes) for TX id=${tx.id}.');
              } else {
                _log('Skipped heavy attachment payload for "${att.fileName}" (${bytes.length} bytes > 500 KB limit).');
              }
            } else {
              _log('Attachment file not found on disk at ${att.filePath}');
            }
          } catch (e) {
            _log('Could not read attachment file ${att.filePath}: $e');
          }
          attachmentMaps.add(attMap);
        }
        txMap['attachments'] = attachmentMaps;
      }
      serializedTxList.add(txMap);
    }

    final payload = <String, dynamic>{
      'action': 'sync_payload',
      'transactions': serializedTxList,
    };

    final encrypted = _cryptoService.encryptPayload(payload, code);
    final sent = await _webrtcService.sendData(encrypted);
    _log('Sent ${transactions.length} transactions to peer (success=$sent).');
  }

  Future<Uint8List?> _resizeImageBytes(
    Uint8List bytes, {
    int maxDimension = 400,
  }) async {
    try {
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: maxDimension,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      _log('Image resize error: $e');
      return null;
    }
  }

  Future<void> _processIncomingSyncPayload(
    Map<String, dynamic> payload,
  ) async {
    final rawTxList = payload['transactions'] as List<dynamic>?;
    if (rawTxList == null) {
      if (_syncCompleter != null && !_syncCompleter!.isCompleted) {
        _syncCompleter!.complete(false);
      }
      return;
    }

    _log('Processing incoming sync payload: ${rawTxList.length} transactions.');
    try {
      final txService = ref.read(transactionServiceProvider);
      final existingTransactions = await txService.getAllTransactions();

      // Normalized UTC signature matching to prevent local database ID collisions & timezone mismatches
      String txSignature(Transaction t) {
        final dateUtcIso = t.date.toUtc().toIso8601String();
        final amountFormatted = t.amount.toStringAsFixed(2);
        return '${dateUtcIso}_${amountFormatted}_${t.type.toLowerCase()}_${t.category.toLowerCase()}_${t.note.trim()}';
      }

      final existingSignatures = <String, Transaction>{};
      for (final t in existingTransactions) {
        existingSignatures[txSignature(t)] = t;
      }

      var addedCount = 0;
      var updatedCount = 0;

      for (final rawItem in rawTxList) {
        try {
          if (rawItem is! Map<String, dynamic>) continue;
          final rawMap = Map<String, dynamic>.from(rawItem);
          rawMap['id'] = null; // Explicitly remove remote primary key

          // Process & save physical file attachments if present
          final rawAttachments = rawMap['attachments'] as List<dynamic>?;
          final processedAttachments = <Attachment>[];

          if (rawAttachments != null && rawAttachments.isNotEmpty) {
            for (final attItem in rawAttachments) {
              if (attItem is! Map<String, dynamic>) continue;
              final attMap = Map<String, dynamic>.from(attItem);
              final base64BytesStr = attMap['file_bytes_base64'] as String?;

              if (base64BytesStr != null && base64BytesStr.isNotEmpty) {
                try {
                  final bytes = base64Decode(base64BytesStr);
                  final fileType = AttachmentType.fromString(
                    attMap['file_type'] as String? ?? 'other',
                  );
                  final originalName = attMap['file_name'] as String?;

                  final savedAttachment =
                      await _attachmentService.saveBytesToStorage(
                    bytes,
                    fileType: fileType,
                    originalName: originalName,
                  );

                  attMap['file_path'] = savedAttachment.filePath;
                  _log('Saved incoming attachment "${savedAttachment.fileName}" to local disk: ${savedAttachment.filePath}');
                } catch (e) {
                  _log('Failed to save incoming attachment bytes: $e');
                }
              }
              // Create attachment without remote database ID
              final attWithoutId = Attachment.fromMap(attMap).copyWith(id: null);
              processedAttachments.add(attWithoutId);
            }
            rawMap['attachments'] = processedAttachments.map((a) => a.toMap()).toList();
          }

          final incomingTx = Transaction.fromMap(rawMap);
          final incomingSig = txSignature(incomingTx);

          final existingTx = existingSignatures[incomingSig];

          if (existingTx == null) {
            // New transaction from peer: strip remote SQLite ID so local device assigns a new primary key
            final newTx = incomingTx.copyWith(
              id: null,
              attachments: processedAttachments,
            );
            await txService.addTransaction(newTx);
            addedCount++;
            _log('Added new synced transaction: ${newTx.note} (${newTx.amount})');
          } else {
            // Transaction already exists locally: merge any new attachments
            if (processedAttachments.isNotEmpty && existingTx.id != null) {
              final existingAttNames =
                  existingTx.attachments.map((a) => a.fileName).toSet();
              final newAttsToInsert = processedAttachments
                  .where((p) => !existingAttNames.contains(p.fileName))
                  .toList();

              if (newAttsToInsert.isNotEmpty) {
                final updatedTx = existingTx.copyWith(
                  attachments: <Attachment>[
                    ...existingTx.attachments,
                    ...newAttsToInsert,
                  ],
                );
                await txService.updateTransaction(updatedTx);
                updatedCount++;
                _log('Updated attachments for existing transaction id=${existingTx.id}.');
              }
            }
          }
        } catch (txErr, txSt) {
          _log('Error importing individual transaction item: $txErr\n$txSt');
        }
      }

      await ref.read(transactionNotifierProvider.notifier).refresh();

      _log('Sync complete: $addedCount new entries added, '
          '$updatedCount existing updated.');

      state = AsyncData(
        state.valueOrNull?.copyWith(
              isSyncing: false,
              isRemoteChangeDetected: false,
              statusMessage: 'Synced successfully ($addedCount new entries added).',
            ) ??
            const P2PSyncState(),
      );

      // Signal the sync completer so syncNow() can finish immediately
      if (_syncCompleter != null && !_syncCompleter!.isCompleted) {
        _syncCompleter!.complete(true);
      }
    } catch (e, st) {
      _log('Error processing sync payload: $e\n$st');
      state = AsyncData(
        state.valueOrNull?.copyWith(
              isSyncing: false,
              statusMessage: 'Failed to merge peer data: $e',
            ) ??
            const P2PSyncState(),
      );
      if (_syncCompleter != null && !_syncCompleter!.isCompleted) {
        _syncCompleter!.complete(false);
      }
    }
  }

  void _log(String message) {
    P2PLogger.log('[P2P.Sync] $message');
  }
}

final p2pSyncNotifierProvider =
    AsyncNotifierProvider<P2PSyncNotifier, P2PSyncState>(
      P2PSyncNotifier.new,
    );
