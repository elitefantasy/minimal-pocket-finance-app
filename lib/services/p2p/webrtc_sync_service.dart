import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// WebRTC Peer-to-Peer data connection service handling direct E2E WebRTC DataChannel transfer.
class WebRTCSyncService {
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;

  bool _isChannelOpen = false;
  bool get isChannelOpen => _isChannelOpen;

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

  /// Initializes peer connection.
  Future<void> initialize() async {
    await close();

    _peerConnection = await createPeerConnection(_rtcConfig);

    _peerConnection?.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        onIceCandidate?.call(<String, dynamic>{
          'type': 'candidate',
          'candidate': candidate.toMap(),
        });
      }
    };

    _peerConnection?.onDataChannel = (channel) {
      _setupDataChannel(channel);
    };
  }

  /// Creates SDP Offer (Initiator / Host).
  Future<Map<String, dynamic>> createOffer() async {
    await initialize();

    final channelInit = RTCDataChannelInit()..ordered = true;
    final channel = await _peerConnection?.createDataChannel('akm_sync_channel', channelInit);
    if (channel != null) {
      _setupDataChannel(channel);
    }

    final offer = await _peerConnection?.createOffer();
    await _peerConnection?.setLocalDescription(offer!);

    return <String, dynamic>{
      'type': 'offer',
      'sdp': offer?.sdp,
    };
  }

  /// Handles incoming SDP Offer and returns SDP Answer (Receiver / Client).
  Future<Map<String, dynamic>> handleOffer(Map<String, dynamic> offerMap) async {
    await initialize();

    final sdp = offerMap['sdp'] as String;
    final description = RTCSessionDescription(sdp, 'offer');
    await _peerConnection?.setRemoteDescription(description);

    final answer = await _peerConnection?.createAnswer();
    await _peerConnection?.setLocalDescription(answer!);

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
  }

  /// Handles incoming ICE candidate.
  Future<void> handleIceCandidate(Map<String, dynamic> candidateMap) async {
    final candidateData = candidateMap['candidate'] as Map<String, dynamic>;
    final candidate = RTCIceCandidate(
      candidateData['candidate'] as String?,
      candidateData['sdpMid'] as String?,
      candidateData['sdpMLineIndex'] as int?,
    );
    await _peerConnection?.addCandidate(candidate);
  }

  void _setupDataChannel(RTCDataChannel channel) {
    _dataChannel = channel;
    _dataChannel?.onDataChannelState = (state) {
      _isChannelOpen = state == RTCDataChannelState.RTCDataChannelOpen;
      onConnectionStateChanged?.call(_isChannelOpen);
    };

    _dataChannel?.onMessage = (data) {
      if (data.text.isEmpty) return;
      onDataReceived?.call(data.text);
    };
  }

  /// Sends a string/JSON message directly to peer over WebRTC DataChannel.
  Future<bool> sendData(String message) async {
    if (_dataChannel == null || !_isChannelOpen) return false;
    await _dataChannel?.send(RTCDataChannelMessage(message));
    return true;
  }

  /// Closes peer connection and data channel.
  Future<void> close() async {
    _isChannelOpen = false;
    await _dataChannel?.close();
    _dataChannel = null;
    await _peerConnection?.close();
    _peerConnection = null;
  }
}
