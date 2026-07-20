import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Lightweight WebSocket signaling client used for zero-knowledge peer presence discovery
/// and WebRTC SDP/ICE handshake candidate exchange.
class SignalingClient {
  SignalingClient({
    String? serverUrl,
  }) : _serverUrl = serverUrl ?? 'wss://socketsbay.com/wss/v2/1/akm_p2p_sync/';

  final String _serverUrl;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  String? _currentRoomId;

  // Callbacks
  void Function(String senderId, String encryptedPayload)? onPresenceReceived;
  void Function(String senderId, Map<String, dynamic> signalData)? onSignalReceived;
  void Function()? onConnected;
  void Function()? onDisconnected;

  /// Connect to the signaling WebSocket server and join room.
  Future<void> connect(String roomId, String deviceId) async {
    if (_isConnected && _currentRoomId == roomId) return;

    await disconnect();
    _currentRoomId = roomId;

    try {
      final uri = Uri.parse('$_serverUrl$roomId');
      _channel = WebSocketChannel.connect(uri);
      await _channel?.ready;
      _isConnected = true;
      onConnected?.call();

      _subscription = _channel?.stream.listen(
        (message) => _handleIncomingMessage(message.toString(), deviceId),
        onError: (_) => _handleDisconnect(),
        onDone: () => _handleDisconnect(),
      );

      // Send join event
      send(<String, dynamic>{
        'type': 'join',
        'room': roomId,
        'sender': deviceId,
      });
    } catch (_) {
      _handleDisconnect();
    }
  }

  void _handleIncomingMessage(String rawMessage, String localDeviceId) {
    try {
      final map = jsonDecode(rawMessage) as Map<String, dynamic>;
      final sender = map['sender'] as String?;
      final type = map['type'] as String?;

      // Ignore self messages
      if (sender == localDeviceId) return;

      if (type == 'presence' && map.containsKey('payload')) {
        onPresenceReceived?.call(sender ?? '', map['payload'] as String);
      } else if (type == 'signal' && map.containsKey('data')) {
        onSignalReceived?.call(
          sender ?? '',
          map['data'] as Map<String, dynamic>,
        );
      }
    } catch (_) {
      // Ignore malformed signaling packets
    }
  }

  /// Broadcast presence heartbeat.
  void sendPresence(String encryptedPayload, String deviceId) {
    if (!_isConnected || _currentRoomId == null) return;
    send(<String, dynamic>{
      'type': 'presence',
      'room': _currentRoomId,
      'sender': deviceId,
      'payload': encryptedPayload,
    });
  }

  /// Send WebRTC SDP offer, answer, or ICE candidate.
  void sendSignal(Map<String, dynamic> signalData, String deviceId) {
    if (!_isConnected || _currentRoomId == null) return;
    send(<String, dynamic>{
      'type': 'signal',
      'room': _currentRoomId,
      'sender': deviceId,
      'data': signalData,
    });
  }

  void send(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      _channel?.sink.add(jsonEncode(message));
    }
  }

  void _handleDisconnect() {
    _isConnected = false;
    onDisconnected?.call();
  }

  Future<void> disconnect() async {
    _isConnected = false;
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
    _currentRoomId = null;
  }
}
