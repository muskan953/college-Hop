import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:college_hop/services/api_service.dart';
import 'package:college_hop/services/websocket_service.dart';

/// Manages message threads, messages, WebSocket connection, and FCM tokens.
class MessageProvider with ChangeNotifier {
  final WebSocketService _ws = WebSocketService();
  StreamSubscription? _wsSubscription;
  String? _currentToken;
  bool _initialized = false;

  // Thread state
  List<Map<String, dynamic>> threads = [];
  bool isLoadingThreads = false;

  // Active chat state
  String? activeThreadId;
  List<Map<String, dynamic>> messages = [];
  bool isLoadingMessages = false;

  /// Expose the raw WS message stream for per-screen listeners.
  Stream<Map<String, dynamic>> get messageStream => _ws.messageStream;

  /// Expose the WebSocket connection status.
  bool get isConnected => _ws.isConnected;

  /// Connect WebSocket and register FCM token.
  Future<void> init(String token) async {
    // Prevent duplicate initialization on screen revisits
    if (_initialized && _currentToken == token) return;
    _initialized = true;
    _currentToken = token;

    // WebSocket works on Web for ws://localhost!
    _ws.connect(token);
    _wsSubscription?.cancel();
    _wsSubscription = _ws.messageStream.listen(_handleWSMessage);

    // Register FCM device token
    _registerFCMToken(token);
  }

  /// Load all threads from the server.
  Future<void> loadThreads() async {
    if (_currentToken == null) return;
    isLoadingThreads = true;
    notifyListeners();

    try {
      final res = await ApiService.getThreads(_currentToken!);
      if (res.statusCode == 200) {
        threads = List<Map<String, dynamic>>.from(jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint('[MsgProvider] Failed to load threads: $e');
    }

    isLoadingThreads = false;
    notifyListeners();
  }

  /// Load messages for a specific thread.
  Future<void> loadMessages(String threadId) async {
    if (_currentToken == null) return;
    activeThreadId = threadId;
    isLoadingMessages = true;
    notifyListeners();

    try {
      final res = await ApiService.getMessages(_currentToken!, threadId);
      if (res.statusCode == 200) {
        messages = List<Map<String, dynamic>>.from(jsonDecode(res.body));
        // Messages come newest-first, reverse for display
        messages = messages.reversed.toList();
      }
    } catch (e) {
      debugPrint('[MsgProvider] Failed to load messages: $e');
    }

    isLoadingMessages = false;
    notifyListeners();
  }

  /// Send a message via WebSocket (primary) or HTTP (fallback).
  Future<String?> sendMessage(String threadId, String content, {String? replyToId, String? replyToContent, String? replyToSender, bool isForwarded = false}) async {
    if (_currentToken == null) return null;

    // Optimistic UI: add the message locally
    final optimistic = {
      'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
      'thread_id': threadId,
      'sender_id': 'me',
      'sender_name': 'You',
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
      'status': 'sending',
      if (replyToId != null) 'reply_to_id': replyToId,
      if (replyToContent != null) 'reply_to_content': replyToContent,
      if (replyToSender != null) 'reply_to_sender': replyToSender,
      'is_forwarded': isForwarded,
    };
    messages.add(optimistic);
    notifyListeners();

    if (_ws.isConnected) {
      _ws.sendMessage(threadId, content, replyToId: replyToId, isForwarded: isForwarded);
      return null;
    } else {
      // HTTP fallback
      try {
        final res = await ApiService.sendMessage(_currentToken!, {
          'thread_id': threadId,
          'content': content,
          if (replyToId != null) 'reply_to_id': replyToId,
          'is_forwarded': isForwarded,
        });
        if (res.statusCode == 201) {
          final msg = jsonDecode(res.body);
          // Replace optimistic message with real one
          final idx = messages.indexWhere((m) => m['id'] == optimistic['id']);
          if (idx != -1) {
            messages[idx] = msg;
          }
          notifyListeners();
          return msg['id'] as String?;
        }
      } catch (e) {
        debugPrint('[MsgProvider] HTTP send failed: $e');
      }
    }
    return null;
  }

  /// Send typing indicator.
  void sendTyping(String threadId) {
    _ws.sendTyping(threadId);
  }

  /// Get or create a direct thread with a user.
  Future<String?> getOrCreateDirectThread(String otherUserId) async {
    if (_currentToken == null) return null;
    try {
      final res = await ApiService.createDirectThread(_currentToken!, otherUserId);
      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return data['id'] as String;
      }
    } catch (e) {
      debugPrint('[MsgProvider] Failed to create thread: $e');
    }
    return null;
  }

  /// Clear chat for the current user.
  Future<void> clearThread(String threadId) async {
    if (_currentToken == null) return;
    try {
      await ApiService.clearThread(_currentToken!, threadId);
      if (threadId == activeThreadId) {
        messages.clear();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[MsgProvider] Failed to clear thread: $e');
    }
  }

  /// Delete a single message.
  Future<void> deleteMessage(String messageId) async {
    if (_currentToken == null) return;
    try {
      final res = await ApiService.deleteMessage(_currentToken!, messageId);
      if (res.statusCode == 204) {
        messages.removeWhere((m) => m['id'] == messageId);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[MsgProvider] Failed to delete message: $e');
    }
  }

  /// Reset the message provider state and actively tear down connections (e.g. on logout)
  void reset() {
    _ws.disconnect();
    _currentToken = null;
    _initialized = false;
    threads.clear();
    messages.clear();
    activeThreadId = null;
    notifyListeners();
  }

  /// Handle incoming WebSocket messages.
  void _handleWSMessage(Map<String, dynamic> data) {
    final type = data['type'];

    switch (type) {
      case 'new_message':
        final msg = data['payload'] as Map<String, dynamic>;
        // Add to messages if we're in the right thread
        if (msg['thread_id'] == activeThreadId) {
          messages.add(msg);
          notifyListeners();
        }
        // Update thread list with new last message
        _updateThreadLastMessage(msg);
        break;

      case 'message_sent':
        // Mark optimistic message as sent
        final payload = data['payload'] as Map<String, dynamic>;
        final idx = messages.indexWhere(
          (m) => m['status'] == 'sending' && m['thread_id'] == payload['thread_id'],
        );
        if (idx != -1) {
          messages[idx]['id'] = payload['message_id'];
          messages[idx]['status'] = 'sent';
          notifyListeners();
        }
        break;

      case 'user_typing':
        // Could add typing indicator state here
        break;

      case 'error':
        debugPrint('[WS] Server error: ${data['payload']}');
        break;
    }
  }

  void _updateThreadLastMessage(Map<String, dynamic> msg) {
    final idx = threads.indexWhere((t) => t['id'] == msg['thread_id']);
    if (idx != -1) {
      threads[idx]['last_message'] = msg['content'];
      threads[idx]['last_message_at'] = msg['created_at'];
      // Move thread to top
      final thread = threads.removeAt(idx);
      threads.insert(0, thread);
      notifyListeners();
    }
  }

  Future<void> _registerFCMToken(String authToken) async {
    // FCM push tokens are not available on Flutter Web without full Firebase config
    if (kIsWeb) return;
    try {
      final fcm = FirebaseMessaging.instance;

      // Request permission (iOS will show a dialog, Android auto-grants)
      await fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final fcmToken = await fcm.getToken();
      if (fcmToken != null) {
        // Determine platform without dart:io on web
        final platform = kIsWeb ? 'web' : _mobilePlatform();
        await ApiService.registerDeviceToken(authToken, fcmToken, platform);
        debugPrint('[FCM] Token registered');
      }

      // Listen for token refresh
      fcm.onTokenRefresh.listen((newToken) {
        if (_currentToken != null) {
          final platform = kIsWeb ? 'web' : _mobilePlatform();
          ApiService.registerDeviceToken(_currentToken!, newToken, platform);
        }
      });
    } catch (e) {
      debugPrint('[FCM] Failed to register token: $e');
    }
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _ws.dispose();
    super.dispose();
  }

  /// Returns 'ios' or 'android' — only call when !kIsWeb.
  static String _mobilePlatform() {
    // Use defaultTargetPlatform which is available everywhere
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    return 'android';
  }
}
