import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:akm_finance_manager/services/p2p/p2p_logger.dart';

/// A transport-level error raised while opening the ntfy signaling stream.
class SignalingConnectionException implements Exception {
  const SignalingConnectionException(
    this.message, {
    this.statusCode,
    this.retryable = true,
  });

  final String message;
  final int? statusCode;
  final bool retryable;

  @override
  String toString() => 'SignalingConnectionException: $message';
}

/// Lightweight HTTP signaling client used for peer discovery and WebRTC SDP/ICE
/// exchange. The signaling payload is compressed before publishing, but its
/// contents remain end-to-end encrypted by [P2PCryptoService] where required.
///
/// ntfy uses a long-lived JSON HTTP stream for subscriptions and a plain-text
/// HTTP POST for publishing. This client deliberately marks signaling messages
/// as non-cached because stale offer/answer/candidate messages must never be
/// replayed into a later WebRTC session.
class SignalingClient {
  SignalingClient({
    String? serverUrl,
    this.debug = false,
  }) : _serverUri = _normaliseServerUri(serverUrl ?? 'ntfy.sh');

  static const String _topicPrefix = 'akm_p2p_';
  static const int maxTopicLength = 64;
  static const int _maxMessageBytes = 4096;
  static const int _maxReconnectAttempts = 5;
  static const String _compressedMessagePrefix = 'akm-p2p-v1:';
  static final RegExp _topicPattern =
      RegExp(r'^[-_A-Za-z0-9]{1,64}$');

  /// Enables detailed, redacted P2P transport diagnostics in the debug log.
  final bool debug;
  final Uri _serverUri;
  final HttpClient _httpClient = HttpClient();

  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isManualDisconnect = false;
  int _connectionGeneration = 0;
  int _reconnectAttempt = 0;
  Future<void> _publishQueue = Future<void>.value();

  bool get isConnected => _isConnected;

  String? _currentRoomId;
  String? _currentChannelName;
  String? _deviceId;

  StreamSubscription<String>? _streamSubscription;
  Timer? _connectionMonitorTimer;
  Timer? _reconnectTimer;

  // Callbacks
  void Function(String senderId, String encryptedPayload)? onPresenceReceived;
  void Function(String senderId, Map<String, dynamic> signalData)?
      onSignalReceived;
  void Function()? onConnected;
  void Function()? onDisconnected;

  /// Converts a room hash to a valid ntfy topic.
  ///
  /// ntfy topic names are limited to 64 URL-safe characters. The P2P prefix
  /// consumes eight characters, leaving 56 characters (224 bits) of the room
  /// hash, which is still more than enough entropy for an unguessable topic.
  static String topicForRoom(String roomId) {
    final sanitized = roomId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
    if (sanitized.isEmpty) {
      throw ArgumentError.value(roomId, 'roomId', 'must contain a valid token');
    }

    final availableRoomLength = maxTopicLength - _topicPrefix.length;
    final roomToken = sanitized.length > availableRoomLength
        ? sanitized.substring(0, availableRoomLength)
        : sanitized;
    final topic = '$_topicPrefix$roomToken';

    if (!_topicPattern.hasMatch(topic)) {
      throw StateError('Generated an invalid ntfy topic');
    }
    return topic;
  }

  static bool isValidTopicName(String topic) => _topicPattern.hasMatch(topic);

  /// Opens the ntfy JSON stream for [roomId].
  Future<void> connect(String roomId, String deviceId) async {
    if (_isConnecting) {
      _log('Connect skipped because another connection attempt is active.');
      return;
    }
    if (_isConnected && _currentRoomId == roomId) {
      _log('Connect skipped because signaling is already connected.');
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _isConnecting = true;
    _isManualDisconnect = false;

    try {
      await _disconnectInternal(clearTarget: true);
      final generation = ++_connectionGeneration;
      final channelName = topicForRoom(roomId);

      _currentRoomId = roomId;
      _currentChannelName = channelName;
      _deviceId = deviceId;

      _log(
        'Opening ntfy JSON stream '
        '(topic=${_redact(channelName)}, length=${channelName.length}, '
        'device=$deviceId).',
      );

      final request = await _httpClient
          .getUrl(_streamUri(channelName))
          .timeout(const Duration(seconds: 15));
      request.headers.set(HttpHeaders.acceptHeader, 'application/x-ndjson');
      request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');

      final response = await request
          .close()
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != HttpStatus.ok) {
        final body = await _readResponsePreview(response);
        throw SignalingConnectionException(
          'ntfy returned HTTP ${response.statusCode}'
          ' (${response.reasonPhrase})'
          '${body.isEmpty ? '' : ': $body'}',
          statusCode: response.statusCode,
          retryable: _isRetryableStatusCode(response.statusCode),
        );
      }

      if (_connectionGeneration != generation || _currentChannelName != channelName) {
        _log('Ignoring a completed stream request because its connection was replaced.');
        await response.drain();
        return;
      }

      _streamSubscription = response
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) => _handleStreamLine(line, deviceId),
        onError: (Object error, StackTrace stackTrace) {
          _handleTransportClosed(
            reason: 'ntfy stream error',
            error: error,
            stackTrace: stackTrace,
          );
        },
        onDone: () => _handleTransportClosed(reason: 'ntfy stream closed'),
        cancelOnError: false,
      );

      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempt = 0;
      _startConnectionMonitor();
      _log('Signaling stream connected successfully (HTTP 200).');
      onConnected?.call();
    } catch (error, stackTrace) {
      _isConnecting = false;
      final retryable = error is SignalingConnectionException
          ? error.retryable
          : true;
      _handleTransportClosed(
        reason: 'Unable to open ntfy signaling stream',
        error: error,
        stackTrace: stackTrace,
        retryable: retryable,
      );
      rethrow;
    }
  }

  /// Broadcasts an encrypted presence heartbeat.
  Future<bool> sendPresence(String encryptedPayload, String deviceId) {
    return send(<String, dynamic>{
      'type': 'presence',
      'room': _currentRoomId,
      'sender': deviceId,
      'payload': encryptedPayload,
    });
  }

  /// Sends a WebRTC SDP offer, answer, or ICE candidate.
  Future<bool> sendSignal(Map<String, dynamic> signalData, String deviceId) {
    return send(<String, dynamic>{
      'type': 'signal',
      'room': _currentRoomId,
      'sender': deviceId,
      'data': signalData,
    });
  }

  /// Publishes a signaling envelope and reports whether ntfy accepted it.
  ///
  /// Messages are serialised through one queue so the SDP offer/answer is
  /// published before the ICE candidates generated immediately afterwards.
  Future<bool> send(Map<String, dynamic> message) {
    final channelName = _currentChannelName;
    final generation = _connectionGeneration;
    final type = message['type']?.toString() ?? 'unknown';

    if (!_isConnected || channelName == null) {
      _log('Dropped $type message because signaling is not connected.');
      return Future<bool>.value(false);
    }

    late final String payload;
    try {
      payload = _encodeMessage(message);
    } catch (error, stackTrace) {
      _log('Could not encode $type signaling message.',
          error: error, stackTrace: stackTrace);
      return Future<bool>.value(false);
    }

    final payloadBytes = utf8.encode(payload).length;
    if (payloadBytes > _maxMessageBytes) {
      _log(
        'Refused $type signaling message: $payloadBytes bytes exceeds '
        'ntfy\'s $_maxMessageBytes-byte limit.',
      );
      return Future<bool>.value(false);
    }

    _log('Queueing $type signaling message ($payloadBytes bytes).');
    final publish = _publishQueue.then((_) async {
      if (!_isConnected ||
          _connectionGeneration != generation ||
          _currentChannelName != channelName) {
        _log('Dropped queued $type signaling message after connection changed.');
        return false;
      }
      return _publishHttp(channelName, payload, type);
    });
    _publishQueue = publish.then<void>((_) {});
    return publish;
  }

  Future<bool> _publishHttp(
    String channelName,
    String payload,
    String type,
  ) async {
    try {
      final request = await _httpClient
          .postUrl(_topicUri(channelName))
          .timeout(const Duration(seconds: 15));
      // Posting JSON to /<topic> invokes ntfy's JSON API, which expects a
      // separate `topic` field. Sending plain text makes the compressed envelope
      // the message body, as required by the topic publishing endpoint.
      request.headers.contentType =
          ContentType('text', 'plain', charset: 'utf-8');
      request.headers.set('Cache', 'no');
      request.headers.set('Firebase', 'no');
      request.write(payload);

      final response = await request
          .close()
          .timeout(const Duration(seconds: 15));
      final body = await _readResponsePreview(response);
      final accepted = response.statusCode >= HttpStatus.ok &&
          response.statusCode < HttpStatus.multipleChoices;

      if (accepted) {
        _log('ntfy accepted $type signaling message (HTTP ${response.statusCode}).');
      } else {
        _log(
          'ntfy rejected $type signaling message '
          '(HTTP ${response.statusCode}${body.isEmpty ? '' : ': $body'}).',
        );
      }
      return accepted;
    } catch (error, stackTrace) {
      _log('Failed to publish $type signaling message.',
          error: error, stackTrace: stackTrace);
      return false;
    }
  }

  void _handleStreamLine(String line, String localDeviceId) {
    if (line.trim().isEmpty) {
      return;
    }

    try {
      final outerMap = jsonDecode(line) as Map<String, dynamic>;
      final event = outerMap['event']?.toString();

      if (event == 'open') {
        _log('ntfy stream sent its open event.');
        return;
      }
      if (event == 'keepalive') {
        _log('ntfy stream keepalive received.');
        return;
      }
      if (event != 'message') {
        _log('Ignoring ntfy stream event "$event".');
        return;
      }

      final content = outerMap['message'];
      final message = switch (content) {
        final String value => _decodeMessage(value),
        final Map<dynamic, dynamic> value => Map<String, dynamic>.from(value),
        _ => throw const FormatException('ntfy message has no string payload'),
      };
      final sender = message['sender']?.toString();
      final type = message['type']?.toString();
      final room = message['room']?.toString();

      if (room != _currentRoomId) {
        _log('Ignoring $type message for a different room.');
        return;
      }
      if (sender == null || sender.isEmpty || sender == localDeviceId) {
        _log('Ignoring self-originated or malformed $type message.');
        return;
      }

      if (type == 'presence') {
        final payload = message['payload'];
        if (payload is! String) {
          _log('Ignoring presence message from $sender without an encrypted payload.');
          return;
        }
        _log('Received presence from $sender.');
        onPresenceReceived?.call(sender, payload);
      } else if (type == 'signal') {
        final data = message['data'];
        if (data is! Map) {
          _log('Ignoring signal message from $sender without signal data.');
          return;
        }
        final signalData = Map<String, dynamic>.from(data);
        _log('Received ${signalData['type'] ?? 'unknown'} signal from $sender.');
        onSignalReceived?.call(sender, signalData);
      } else {
        _log('Ignoring unknown signaling message type "$type" from $sender.');
      }
    } catch (error, stackTrace) {
      _log('Ignoring malformed ntfy signaling message.',
          error: error, stackTrace: stackTrace);
    }
  }

  void _handleTransportClosed({
    required String reason,
    Object? error,
    StackTrace? stackTrace,
    bool retryable = true,
  }) {
    if (!_isConnected && _streamSubscription == null && error == null) {
      return;
    }

    final wasConnected = _isConnected;
    _isConnected = false;
    _isConnecting = false;
    _streamSubscription = null;
    _connectionMonitorTimer?.cancel();
    _connectionMonitorTimer = null;

    _log(reason, error: error, stackTrace: stackTrace);
    if (wasConnected || error != null) {
      onDisconnected?.call();
    }

    if (!_isManualDisconnect && retryable) {
      _scheduleReconnect();
    } else if (!retryable) {
      _log('Not retrying signaling because the server response is not retryable.');
    }
  }

  void _scheduleReconnect() {
    if (_reconnectTimer != null ||
        _isManualDisconnect ||
        _currentRoomId == null ||
        _deviceId == null) {
      return;
    }
    if (_reconnectAttempt >= _maxReconnectAttempts) {
      _log('Automatic signaling reconnect limit reached.');
      return;
    }

    final attempt = ++_reconnectAttempt;
    final delaySeconds = 2 * (1 << (attempt - 1));
    final delay = Duration(seconds: delaySeconds.clamp(2, 30));
    _log(
      'Scheduling signaling reconnect attempt $attempt/$_maxReconnectAttempts '
      'in ${delay.inSeconds}s.',
    );
    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      final roomId = _currentRoomId;
      final deviceId = _deviceId;
      if (roomId == null || deviceId == null || _isConnected || _isManualDisconnect) {
        return;
      }
      _log('Starting signaling reconnect attempt $attempt.');
      unawaited(_reconnect(roomId, deviceId));
    });
  }

  Future<void> _reconnect(String roomId, String deviceId) async {
    try {
      await connect(roomId, deviceId);
    } catch (_) {
      // connect() logs the detailed failure and schedules the next attempt.
    }
  }

  void _startConnectionMonitor() {
    _connectionMonitorTimer?.cancel();
    _connectionMonitorTimer = Timer.periodic(
      const Duration(minutes: 2),
      (timer) {
        if (!_isConnected) {
          timer.cancel();
          return;
        }
        _log('Signaling stream remains active.');
      },
    );
  }

  Future<void> disconnect() async {
    _isManualDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _disconnectInternal(clearTarget: true);
    _isManualDisconnect = false;
    _log('Signaling disconnected by caller.');
  }

  Future<void> dispose() async {
    await disconnect();
    _httpClient.close(force: true);
  }

  Future<void> _disconnectInternal({required bool clearTarget}) async {
    ++_connectionGeneration;
    _isConnected = false;
    _connectionMonitorTimer?.cancel();
    _connectionMonitorTimer = null;
    final subscription = _streamSubscription;
    _streamSubscription = null;
    await subscription?.cancel();
    if (clearTarget) {
      _currentRoomId = null;
      _currentChannelName = null;
      _deviceId = null;
    }
  }

  String _encodeMessage(Map<String, dynamic> message) {
    final jsonBytes = utf8.encode(jsonEncode(message));
    final compressedBytes = gzip.encode(jsonBytes);
    return '$_compressedMessagePrefix${base64UrlEncode(compressedBytes)}';
  }

  Map<String, dynamic> _decodeMessage(String message) {
    if (!message.startsWith(_compressedMessagePrefix)) {
      return jsonDecode(message) as Map<String, dynamic>;
    }

    final encoded = message.substring(_compressedMessagePrefix.length);
    final compressed = base64Url.decode(encoded);
    final jsonText = utf8.decode(gzip.decode(compressed));
    return jsonDecode(jsonText) as Map<String, dynamic>;
  }

  Uri _topicUri(String channelName) => _uriFor(channelName);

  Uri _streamUri(String channelName) => _uriFor(channelName, endpoint: 'json');

  Uri _uriFor(String channelName, {String? endpoint}) {
    final baseSegments = _serverUri.pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);
    return _serverUri.replace(
      pathSegments: <String>[
        ...baseSegments,
        channelName,
        ?endpoint,
      ],
      queryParameters: null,
      fragment: null,
    );
  }

  static Uri _normaliseServerUri(String value) {
    final trimmed = value.trim();
    final withScheme = trimmed.contains('://') ? trimmed : 'https://$trimmed';
    final uri = Uri.parse(withScheme);
    if (uri.host.isEmpty) {
      throw ArgumentError.value(value, 'serverUrl', 'must contain a host');
    }
    return uri.replace(queryParameters: null, fragment: null);
  }

  static bool _isRetryableStatusCode(int statusCode) {
    return statusCode == HttpStatus.requestTimeout ||
        statusCode == HttpStatus.tooManyRequests ||
        statusCode >= HttpStatus.internalServerError;
  }

  Future<String> _readResponsePreview(HttpClientResponse response) async {
    final text = await utf8.decoder.bind(response).join();
    return _shorten(text.trim(), 300);
  }

  void _log(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!debug) {
      return;
    }
    final logText = '[P2P.Signaling] $message'
        '${error != null ? ' | ERROR: $error' : ''}';
    P2PLogger.log(logText);
    if (stackTrace != null) {
      P2PLogger.log('[P2P.Signaling] STACKTRACE: $stackTrace');
    }
  }

  static String _redact(String value) {
    if (value.length <= 12) {
      return value;
    }
    return '${value.substring(0, 6)}…${value.substring(value.length - 6)}';
  }

  static String _shorten(String value, int maxLength) {
    if (value.length <= maxLength) {
      return value;
    }
    return '${value.substring(0, maxLength)}…';
  }
}
