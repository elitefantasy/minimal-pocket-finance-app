import 'dart:async';
import 'dart:io';
import 'package:akm_finance_manager/app/providers.dart';
import 'package:akm_finance_manager/features/transactions/application/transaction_notifier.dart';
import 'package:akm_finance_manager/models/transaction.dart';
import 'package:akm_finance_manager/services/p2p/p2p_crypto_service.dart';
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
  final SignalingClient _signalingClient = SignalingClient();
  final WebRTCSyncService _webrtcService = WebRTCSyncService();

  static const String _prefPairingKey = 'p2p_pairing_code';
  static const String _prefDeviceName = 'p2p_device_name';

  late String _deviceId;
  Timer? _heartbeatTimer;

  @override
  Future<P2PSyncState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPairingCode = prefs.getString(_prefPairingKey);
    _deviceId = prefs.getString(_prefDeviceName) ?? Platform.localHostname;

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
      if (payload == null) return;

      final remoteDeviceName = payload['device'] as String? ?? senderId;
      final remoteTimestampIso = payload['timestamp'] as String?;
      final remoteTimestamp = remoteTimestampIso != null
          ? DateTime.tryParse(remoteTimestampIso)
          : null;

      state = AsyncData(
        state.valueOrNull?.copyWith(
              isRemoteChangeDetected: true,
              remoteDeviceName: remoteDeviceName,
              remoteLastUpdated: remoteTimestamp,
              statusMessage: 'Changes detected on $remoteDeviceName',
            ) ??
            P2PSyncState(
              isRemoteChangeDetected: true,
              remoteDeviceName: remoteDeviceName,
              remoteLastUpdated: remoteTimestamp,
              statusMessage: 'Changes detected on $remoteDeviceName',
            ),
      );
    };

    _signalingClient.onSignalReceived = (senderId, signalData) async {
      final type = signalData['type'] as String?;
      if (type == 'offer') {
        final answerData = await _webrtcService.handleOffer(signalData);
        _signalingClient.sendSignal(answerData, _deviceId);
      } else if (type == 'answer') {
        await _webrtcService.handleAnswer(signalData);
      } else if (type == 'candidate') {
        await _webrtcService.handleIceCandidate(signalData);
      }
    };
  }

  void _setupWebRTCListeners() {
    _webrtcService.onIceCandidate = (candidateData) {
      _signalingClient.sendSignal(candidateData, _deviceId);
    };

    _webrtcService.onDataReceived = (encryptedData) async {
      final code = state.valueOrNull?.pairingCode;
      if (code == null) return;

      final payload = _cryptoService.decryptPayload(encryptedData, code);
      if (payload == null) return;

      final action = payload['action'] as String?;
      if (action == 'request_sync') {
        // Peer requested sync data — send transactions & attachments
        await _sendLocalDataToPeer();
      } else if (action == 'sync_payload') {
        // Received synced data from peer — import locally
        await _processIncomingSyncPayload(payload);
      }
    };
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      broadcastPresence();
    });
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
    _signalingClient.sendPresence(encrypted, _deviceId);
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
    await _signalingClient.connect(roomId, _deviceId);
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

    state = AsyncData(
      current.copyWith(
        isSyncing: true,
        statusMessage: 'Establishing E2E WebRTC connection...',
      ),
    );

    try {
      final offerData = await _webrtcService.createOffer();
      _signalingClient.sendSignal(offerData, _deviceId);

      // Wait briefly for DataChannel opening
      var waitCount = 0;
      while (!_webrtcService.isChannelOpen && waitCount < 10) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        waitCount++;
      }

      if (_webrtcService.isChannelOpen) {
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
        await _webrtcService.sendData(encryptedReq);
      } else {
        state = AsyncData(
          current.copyWith(
            isSyncing: false,
            statusMessage: 'P2P channel timeout. Peer may be offline.',
          ),
        );
      }
    } catch (e) {
      state = AsyncData(
        current.copyWith(
          isSyncing: false,
          statusMessage: 'Sync error: $e',
        ),
      );
    }
  }

  Future<void> _sendLocalDataToPeer() async {
    final code = state.valueOrNull?.pairingCode;
    if (code == null) return;

    final txService = ref.read(transactionServiceProvider);
    final transactions = await txService.getAllTransactions();

    final payload = <String, dynamic>{
      'action': 'sync_payload',
      'transactions': transactions.map((t) => t.toMap()).toList(),
    };

    final encrypted = _cryptoService.encryptPayload(payload, code);
    await _webrtcService.sendData(encrypted);
  }

  Future<void> _processIncomingSyncPayload(Map<String, dynamic> payload) async {
    final rawTxList = payload['transactions'] as List<dynamic>?;
    if (rawTxList == null) return;

    final txService = ref.read(transactionServiceProvider);
    final existingTransactions = await txService.getAllTransactions();
    final existingIds = existingTransactions.map((t) => t.id).whereType<int>().toSet();

    var addedCount = 0;
    for (final rawMap in rawTxList) {
      final incomingTx = Transaction.fromMap(rawMap as Map<String, dynamic>);
      if (incomingTx.id == null || !existingIds.contains(incomingTx.id)) {
        await txService.addTransaction(incomingTx);
        addedCount++;
      } else {
        await txService.updateTransaction(incomingTx);
      }
    }

    await ref.read(transactionNotifierProvider.notifier).refresh();

    state = AsyncData(
      state.valueOrNull?.copyWith(
            isSyncing: false,
            isRemoteChangeDetected: false,
            statusMessage: 'Synced successfully ($addedCount new entries).',
          ) ??
          const P2PSyncState(),
    );
  }
}

final p2pSyncNotifierProvider =
    AsyncNotifierProvider<P2PSyncNotifier, P2PSyncState>(
      P2PSyncNotifier.new,
    );
