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

  /// Stream of incoming WebSocket messages.
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  /// Whether the WebSocket is currently connected.
  bool get isConnected => _channel != null;

  /// Connect to the WebSocket server with the given JWT token.
  void connect(String token) {
    if (_disposed) return;
    _currentToken = token;
    _intentionalClose = false;

    try {
      final wsUrl = ApiService.baseUrl
          .replaceFirst('http://', 'ws://')
          .replaceFirst('https://', 'wss://');

      _channel = WebSocketChannel.connect(
        Uri.parse('$wsUrl/ws?token=$token'),
      );

      debugPrint('[WS] Connecting (attempt $_reconnectAttempts)');

      _channel!.stream.listen(
        _onMessage,
        onDone: _onDisconnect,
        onError: (error) {
          debugPrint('[WS] Error: $error');
          _onDisconnect();
        },
      );

      // Only reset counter if we successfully stay connected
      Future.delayed(const Duration(seconds: 5), () {
        if (_channel != null && !_disposed) {
          _reconnectAttempts = 0;
          debugPrint('[WS] Connection stable');
        }
      });
    } catch (e) {
      debugPrint('[WS] Connection failed: $e');
      _channel = null;
      _scheduleReconnect();
    }
  }

  /// Send a message through the WebSocket.
  void sendMessage(String threadId, String content) {
    _send({
      'type': 'message',
      'thread_id': threadId,
      'content': content,
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
    _channel?.sink.close();
    _channel = null;
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
    // Cap at 10 retries (~60s max delay)
    if (_reconnectAttempts >= 10) {
      debugPrint('[WS] Max reconnect attempts reached, giving up');
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(
      seconds: min(60, pow(2, _reconnectAttempts).toInt()),
    );
    debugPrint('[WS] Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts)');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      connect(_currentToken!);
    });
  }
}
