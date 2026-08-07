import 'dart:async';
import 'package:minimal_pocket_finance_app/services/p2p/p2p_logger.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// WebRTC Peer-to-Peer data connection service handling direct E2E WebRTC DataChannel transfer.
///
/// Features:
/// - ICE candidate buffering before remote description is set
/// - Automatic chunking and reassembly for large payloads exceeding WebRTC SCTP MTU (12 KB)
/// - Comprehensive state transition logging
class WebRTCSyncService {
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;

  bool _isChannelOpen = false;
  bool get isChannelOpen => _isChannelOpen;

  bool _hasRemoteDescription = false;
  final List<RTCIceCandidate> _pendingCandidates = [];

  /// Completes when the data channel opens (or errors on timeout).
  Completer<bool>? _channelOpenCompleter;

  /// Chunk reassembly buffers: msgId -> `Map<chunkIndex, chunkData>`
  final Map<String, Map<int, String>> _incomingChunks = {};

  // Callbacks
  void Function(Map<String, dynamic> signalData)? onIceCandidate;
  void Function(String message)? onDataReceived;
  void Function(bool isOpen)? onConnectionStateChanged;

  static const Map<String, dynamic> _rtcConfig = <String, dynamic>{
    'iceServers': <Map<String, Object>>[
      <String, Object>{'urls': 'stun:stun.l.google.com:19302'},
      <String, Object>{'urls': 'stun:stun1.l.google.com:19302'},
      <String, Object>{'urls': 'stun:stun2.l.google.com:19302'},
    ],
  };

  static const int _maxChunkSize = 10000; // 10 KB per chunk for SCTP safety

  /// Initializes peer connection.
  Future<void> initialize() async {
    await close();
    _hasRemoteDescription = false;
    _pendingCandidates.clear();
    _incomingChunks.clear();

    _peerConnection = await createPeerConnection(_rtcConfig);

    _peerConnection?.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        _log('ICE candidate generated: ${_summarizeCandidate(candidate)}');
        onIceCandidate?.call(<String, dynamic>{
          'type': 'candidate',
          'candidate': candidate.toMap(),
        });
      }
    };

    _peerConnection?.onIceGatheringState = (state) {
      _log('ICE gathering state: $state');
    };

    _peerConnection?.onIceConnectionState = (state) {
      _log('ICE connection state: $state');
    };

    _peerConnection?.onConnectionState = (state) {
      _log('Peer connection state: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        _isChannelOpen = false;
        onConnectionStateChanged?.call(false);
        if (_channelOpenCompleter != null &&
            !_channelOpenCompleter!.isCompleted) {
          _channelOpenCompleter!.completeError(
            StateError('Peer connection $state'),
          );
        }
        _channelOpenCompleter = null;
      }
    };

    _peerConnection?.onDataChannel = (channel) {
      _log('Remote data channel received: ${channel.label}');
      _setupDataChannel(channel);
    };

    _log('Peer connection initialized.');
  }

  /// Creates SDP Offer (Initiator / Host).
  Future<Map<String, dynamic>> createOffer() async {
    await initialize();

    _channelOpenCompleter = Completer<bool>();

    final channelInit = RTCDataChannelInit()..ordered = true;
    final channel = await _peerConnection?.createDataChannel(
      'akm_sync_channel',
      channelInit,
    );
    if (channel != null) {
      _setupDataChannel(channel);
    }

    final offer = await _peerConnection?.createOffer();
    await _peerConnection?.setLocalDescription(offer!);
    _log('SDP offer created.');

    return <String, dynamic>{
      'type': 'offer',
      'sdp': offer?.sdp,
    };
  }

  /// Handles incoming SDP Offer and returns SDP Answer (Receiver / Client).
  Future<Map<String, dynamic>> handleOffer(
    Map<String, dynamic> offerMap,
  ) async {
    await initialize();

    _channelOpenCompleter = Completer<bool>();

    final sdp = offerMap['sdp'] as String;
    final description = RTCSessionDescription(sdp, 'offer');
    await _peerConnection?.setRemoteDescription(description);
    _hasRemoteDescription = true;
    _log('Remote offer set. Flushing ${_pendingCandidates.length} buffered candidates.');
    await _flushPendingCandidates();

    final answer = await _peerConnection?.createAnswer();
    await _peerConnection?.setLocalDescription(answer!);
    _log('SDP answer created.');

    return <String, dynamic>{
      'type': 'answer',
      'sdp': answer?.sdp,
    };
  }

  /// Handles incoming SDP Answer.
  Future<void> handleAnswer(Map<String, dynamic> answerMap) async {
    final sdp = answerMap['sdp'] as String;
    final description = RTCSessionDescription(sdp, 'answer');
    await _peerConnection?.setRemoteDescription(description);
    _hasRemoteDescription = true;
    _log('Remote answer set. Flushing ${_pendingCandidates.length} buffered candidates.');
    await _flushPendingCandidates();
  }

  /// Handles incoming ICE candidate.
  Future<void> handleIceCandidate(Map<String, dynamic> candidateMap) async {
    final candidateData =
        candidateMap['candidate'] as Map<String, dynamic>;
    final candidate = RTCIceCandidate(
      candidateData['candidate'] as String?,
      candidateData['sdpMid'] as String?,
      candidateData['sdpMLineIndex'] as int?,
    );

    if (!_hasRemoteDescription || _peerConnection == null) {
      _log('Buffering ICE candidate (remote description not set yet). '
          'Queue size: ${_pendingCandidates.length + 1}');
      _pendingCandidates.add(candidate);
      return;
    }

    _log('Adding ICE candidate: ${_summarizeCandidate(candidate)}');
    await _peerConnection?.addCandidate(candidate);
  }

  /// Waits for the data channel to open with a timeout.
  Future<bool> waitForChannelOpen({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (_isChannelOpen) return true;
    if (_channelOpenCompleter == null) return false;

    try {
      return await _channelOpenCompleter!.future.timeout(timeout);
    } on TimeoutException {
      _log('Data channel open timed out after ${timeout.inSeconds}s.');
      return false;
    } catch (e) {
      _log('Data channel open failed: $e');
      return false;
    }
  }

  Future<void> _flushPendingCandidates() async {
    if (_pendingCandidates.isEmpty) return;

    final candidates = List<RTCIceCandidate>.of(_pendingCandidates);
    _pendingCandidates.clear();

    for (final candidate in candidates) {
      try {
        await _peerConnection?.addCandidate(candidate);
      } catch (e) {
        _log('Failed to add buffered ICE candidate: $e');
      }
    }
    _log('Flushed ${candidates.length} buffered ICE candidates.');
  }

  void _setupDataChannel(RTCDataChannel channel) {
    _dataChannel = channel;
    _dataChannel?.onDataChannelState = (state) {
      _log('Data channel state: $state');
      final isOpen = state == RTCDataChannelState.RTCDataChannelOpen;
      _isChannelOpen = isOpen;
      onConnectionStateChanged?.call(isOpen);

      if (isOpen &&
          _channelOpenCompleter != null &&
          !_channelOpenCompleter!.isCompleted) {
        _channelOpenCompleter!.complete(true);
      }
    };

    _dataChannel?.onMessage = (data) {
      final text = data.text;
      if (text.isEmpty) return;

      if (text.startsWith('AKM_CHUNK:')) {
        _handleIncomingChunk(text);
      } else {
        _log('Data channel received complete message (${text.length} chars).');
        onDataReceived?.call(text);
      }
    };
  }

  void _handleIncomingChunk(String rawChunk) {
    try {
      // Format: AKM_CHUNK:<msgId>:<chunkIndex>:<totalChunks>:<data>
      final firstColon = rawChunk.indexOf(':', 10);
      final secondColon = rawChunk.indexOf(':', firstColon + 1);
      final thirdColon = rawChunk.indexOf(':', secondColon + 1);

      final msgId = rawChunk.substring(10, firstColon);
      final chunkIndex = int.parse(rawChunk.substring(firstColon + 1, secondColon));
      final totalChunks = int.parse(rawChunk.substring(secondColon + 1, thirdColon));
      final data = rawChunk.substring(thirdColon + 1);

      _log('Received chunk ${chunkIndex + 1}/$totalChunks for msgId=$msgId (${data.length} chars).');

      final buffer = _incomingChunks.putIfAbsent(msgId, () => {});
      buffer[chunkIndex] = data;

      if (buffer.length == totalChunks) {
        _log('All $totalChunks chunks received for msgId=$msgId. Reassembling...');
        final fullMessage = Iterable.generate(totalChunks, (i) => buffer[i]!).join();
        _incomingChunks.remove(msgId);
        _log('Reassembled full message (${fullMessage.length} chars). Processing...');
        onDataReceived?.call(fullMessage);
      }
    } catch (e) {
      _log('Error parsing incoming chunk: $e');
    }
  }

  /// Sends a string/JSON message directly to peer over WebRTC DataChannel.
  /// Automatically chunks large messages if they exceed [_maxChunkSize].
  Future<bool> sendData(String message) async {
    if (_dataChannel == null || !_isChannelOpen) {
      _log('Cannot send data: channel ${_isChannelOpen ? "exists" : "not open"}.');
      return false;
    }

    if (message.length <= _maxChunkSize) {
      _log('Sending ${message.length} chars over data channel (single packet).');
      await _dataChannel?.send(RTCDataChannelMessage(message));
      return true;
    }

    // Chunk large payloads
    final totalChunks = (message.length / _maxChunkSize).ceil();
    final msgId = DateTime.now().millisecondsSinceEpoch.toString();
    _log('Payload size (${message.length} chars) exceeds $_maxChunkSize chars. '
        'Splitting into $totalChunks chunks (msgId=$msgId)...');

    for (var i = 0; i < totalChunks; i++) {
      if (!_isChannelOpen || _dataChannel == null) {
        _log('Aborting chunk send for msgId=$msgId: data channel closed at chunk ${i + 1}/$totalChunks.');
        return false;
      }

      final start = i * _maxChunkSize;
      final end = (start + _maxChunkSize < message.length)
          ? start + _maxChunkSize
          : message.length;
      final chunkData = message.substring(start, end);
      final chunkPacket = 'AKM_CHUNK:$msgId:$i:$totalChunks:$chunkData';

      if (i == 0 || i == totalChunks - 1 || (i + 1) % 15 == 0) {
        _log('Sending chunk ${i + 1}/$totalChunks (${chunkPacket.length} chars)...');
      }
      await _dataChannel?.send(RTCDataChannelMessage(chunkPacket));

      // 10ms pacing delay between chunks to prevent WebRTC native buffer overflow
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    _log('Finished sending all $totalChunks chunks for msgId=$msgId.');
    return true;
  }

  /// Closes peer connection and data channel.
  Future<void> close() async {
    _isChannelOpen = false;
    _hasRemoteDescription = false;
    _pendingCandidates.clear();
    _incomingChunks.clear();
    _channelOpenCompleter = null;
    await _dataChannel?.close();
    _dataChannel = null;
    await _peerConnection?.close();
    _peerConnection = null;
    _log('WebRTC connection closed.');
  }

  void _log(String message) {
    P2PLogger.log('[P2P.WebRTC] $message');
  }

  static String _summarizeCandidate(dynamic candidate) {
    final str = candidate.toString();
    if (str.length > 80) return '${str.substring(0, 80)}…';
    return str;
  }
}
