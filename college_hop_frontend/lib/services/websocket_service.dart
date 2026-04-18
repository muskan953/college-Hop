import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:college_hop/services/api_service.dart';

/// Manages the WebSocket connection for real-time messaging.
class WebSocketService {
  WebSocketChannel? _channel;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  String? _currentToken;
  bool _disposed = false;
  bool _intentionalClose = false;

  /// Monotonically increasing generation ID. Every call to connect() bumps
  /// this so that listeners from old channels can detect they are stale.
  int _generation = 0;

  /// Stream of incoming WebSocket messages.
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  /// Whether the WebSocket is currently connected.
  bool get isConnected => _channel != null;

  /// Connect to the WebSocket server with the given JWT token.
  void connect(String token) {
    if (_disposed) return;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    // Bump generation so any old channel listeners become stale.
    final gen = ++_generation;

    // Close previous channel (if any) without triggering reconnect.
    if (_channel != null) {
      final old = _channel!;
      _channel = null; // null BEFORE close so old onDone is a no-op
      old.sink.close();
    }

    _currentToken = token;
    _intentionalClose = false;

    try {
      final wsUrl = ApiService.baseUrl
          .replaceFirst('http://', 'ws://')
          .replaceFirst('https://', 'wss://');

      _channel = WebSocketChannel.connect(
        Uri.parse('$wsUrl/ws?token=$token'),
      );

      debugPrint('[WS] Connecting (attempt $_reconnectAttempts, gen $gen)');

      _channel!.stream.listen(
        _onMessage,
        onDone: () {
          if (_generation == gen) _onDisconnect();
        },
        onError: (error) {
          debugPrint('[WS] Error: $error');
          if (_generation == gen) _onDisconnect();
        },
      );

      // Only reset counter if we successfully stay connected for 5s
      Future.delayed(const Duration(seconds: 5), () {
        if (_generation == gen && _channel != null && !_disposed) {
          _reconnectAttempts = 0;
          debugPrint('[WS] Connection stable (gen $gen)');
        }
      });
    } catch (e) {
      debugPrint('[WS] Connection failed: $e');
      _channel = null;
      if (_generation == gen) _scheduleReconnect();
    }
  }

  /// Send a message through the WebSocket.
  void sendMessage(String threadId, String content, {String? replyToId, bool isForwarded = false}) {
    _send({
      'type': 'message',
      'thread_id': threadId,
      'content': content,
      if (replyToId != null) 'reply_to_id': replyToId,
      'is_forwarded': isForwarded,
    });
  }

  /// Send a typing indicator.
  void sendTyping(String threadId) {
    _send({
      'type': 'typing',
      'thread_id': threadId,
    });
  }

  /// Disconnect and clean up.
  void disconnect() {
    _intentionalClose = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    ++_generation; // invalidate any pending listeners
    final ch = _channel;
    _channel = null;
    ch?.sink.close();
  }

  /// Permanently dispose this service.
  void dispose() {
    _disposed = true;
    disconnect();
    _messageController.close();
  }

  void _send(Map<String, dynamic> data) {
    if (_channel == null) {
      debugPrint('[WS] Not connected, cannot send');
      return;
    }
    _channel!.sink.add(jsonEncode(data));
  }

  void _onMessage(dynamic data) {
    try {
      final Map<String, dynamic> msg = jsonDecode(data as String);
      _messageController.add(msg);
    } catch (e) {
      debugPrint('[WS] Failed to parse message: $e');
    }
  }

  void _onDisconnect() {
    _channel = null;
    debugPrint('[WS] Disconnected');
    if (!_disposed && !_intentionalClose) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_disposed || _currentToken == null) return;
    if (_reconnectAttempts >= 8) {
      debugPrint('[WS] Max reconnect attempts reached, giving up');
      return;
    }

    _reconnectAttempts++;
    // Minimum 10s delay prevents rapid reconnect loops (e.g. close 1005 cycles).
    final delay = Duration(
      seconds: min(120, max(10, pow(2, _reconnectAttempts).toInt())),
    );
    debugPrint('[WS] Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts)');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      connect(_currentToken!);
    });
  }
}
