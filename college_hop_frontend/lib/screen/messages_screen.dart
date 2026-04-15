import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:college_hop/providers/auth_provider.dart';
import 'package:college_hop/providers/message_provider.dart';
import 'package:college_hop/services/api_service.dart';
import 'package:college_hop/theme/app_scaffold.dart';
import 'package:college_hop/screen/notification_screen.dart';
import 'package:college_hop/screen/public_profile_screen.dart';
import 'package:college_hop/providers/profile_provider.dart';
import 'package:college_hop/widgets/custom_app_bar.dart';
import 'package:http/http.dart' as http;
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────
enum _ChatType { direct, group, request }

class _ChatThread {
  final String id;
  final String name;
  final String lastMessage;
  final String time;
  final Color avatarColor;
  final String avatarLabel;
  final bool isVerified;
  final bool isPinged;
  final int unreadCount;
  final _ChatType type;
  final String? eventTag;

  final String? otherUserId;
  final bool isOnline;

  const _ChatThread({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.avatarColor,
    required this.avatarLabel,
    this.isVerified = false,
    this.isPinged = false,
    this.unreadCount = 0,
    required this.type,
    this.eventTag,
    this.otherUserId,
    this.isOnline = false,
  });
}

class _Connection {
  final String id;
  final String name;
  final Color fallbackColor;
  final bool isOnline;

  const _Connection(this.id, this.name, this.fallbackColor, this.isOnline);
}

// Full-featured mock data for fallback when backend is unavailable
const _mockThreads = <_ChatThread>[
  _ChatThread(id: '1', name: 'Sarah Chen', lastMessage: 'Sounds good! See you at the airport 🛫', time: '2m ago', avatarColor: Color(0xFF5C6BC0), avatarLabel: 'S', isVerified: true, type: _ChatType.direct),
  _ChatThread(id: '2', name: 'Michael Kim', lastMessage: 'Did you book the hotel yet?', time: '15m ago', unreadCount: 3, avatarColor: Color(0xFFEC407A), avatarLabel: 'M', isVerified: true, type: _ChatType.direct),
  _ChatThread(id: '3', name: 'Hackathon @ IIT Deli', lastMessage: 'Alex: Can we split an Uber from the airport?', time: '1h ago', unreadCount: 5, avatarColor: Color(0xFF26A69A), avatarLabel: 'H', type: _ChatType.group, eventTag: 'IIT Delhi'),
  _ChatThread(id: '4', name: 'Emma Wilson', lastMessage: 'Great connecting with you at the event!', time: '3h ago', avatarColor: Color(0xFFFF7043), avatarLabel: 'E', isPinged: true, type: _ChatType.direct),
  _ChatThread(id: '5', name: 'AWS Summit Trave...', lastMessage: 'Nina: Train leaves at 8 AM sharp', time: '5h ago', avatarColor: Color(0xFF42A5F5), avatarLabel: 'A', type: _ChatType.group, eventTag: 'AWS Summit'),
  _ChatThread(id: '6', name: 'Jessica Lee', lastMessage: 'Looking forward to the hackathon!', time: 'Yesterday', avatarColor: Color(0xFFAB47BC), avatarLabel: 'J', isVerified: true, type: _ChatType.direct),
  _ChatThread(id: '7', name: 'TechFest Travel Group', lastMessage: 'You: See everyone there 🎉', time: 'Yesterday', avatarColor: Color(0xFF66BB6A), avatarLabel: 'T', type: _ChatType.group, eventTag: 'NIT Trichy'),
  _ChatThread(id: '8', name: 'Ravi Sharma', lastMessage: 'Can you share your notes from the talk?', time: '2d ago', avatarColor: Color(0xFFFFCA28), avatarLabel: 'R', type: _ChatType.direct),
  _ChatThread(id: '9', name: 'Unknown User', lastMessage: 'Hey, I saw your profile and would love to connect!', time: '1h ago', avatarColor: Color(0xFF607D8B), avatarLabel: 'U', type: _ChatType.request),
];

const _mockConnections = <_Connection>[
  _Connection('1', 'Sarah', Color(0xFF5C6BC0), true),
  _Connection('2', 'Alex', Color(0xFF26A69A), false),
  _Connection('3', 'Emma', Color(0xFFFF7043), true),
  _Connection('4', 'Naman', Color(0xFFAB47BC), true),
  _Connection('5', 'Michael', Color(0xFFEC407A), false),
];

// ─────────────────────────────────────────────────────────────────────────────
//  MESSAGES SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final TextEditingController _searchCtrl = TextEditingController();
  
  List<_ChatThread> _threads = [];
  List<_Connection> _connections = [];
  
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _fetchData();
    final msgProvider = context.read<MessageProvider>();
    _wsSub = msgProvider.messageStream.listen((_) {
      if (mounted) _refreshThreads();
    });

    // Poll thread list every 4 seconds for live last-message updates ONLY if disconnected
    _threadPollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      final isConnected = context.read<MessageProvider>().isConnected;
      if (!isConnected) {
        _refreshThreads();
      }
    });
  }

  Timer? _threadPollTimer;
  StreamSubscription? _wsSub;
  StreamSubscription? _globalWsSub;

  /// Silently refresh only the thread list (last messages, unread counts).
  Future<void> _refreshThreads() async {
    final auth = context.read<AuthProvider>();
    final token = auth.accessToken;
    if (token == null || !mounted) return;
    try {
      final res = await ApiService.getThreads(token);
      if (!mounted || res.statusCode != 200) return;
      final List<dynamic> data = jsonDecode(res.body);
      final updated = data.map((t) {
        final name = (t['other_user_name'] as String? ?? '').isNotEmpty
            ? t['other_user_name'] as String
            : (t['name'] as String? ?? t['thread_type'] as String? ?? 'Chat');
        final lastMsg = t['last_message'] ?? '';
        final isGroup = (t['thread_type'] ?? t['type']) == 'group';
        return _ChatThread(
          id: t['id'] ?? '',
          name: name,
          lastMessage: lastMsg,
          time: _formatTime(t['last_message_at'] ?? ''),
          avatarColor: _colorFromId(t['id'] ?? ''),
          avatarLabel: name.isNotEmpty ? name[0].toUpperCase() : '?',
          type: isGroup ? _ChatType.group : _ChatType.direct,
          otherUserId: t['other_user_id'] as String?,
          unreadCount: t['unread_count'] as int? ?? 0,
          isOnline: t['is_online'] == true,
        );
      }).toList();
      if (mounted) setState(() => _threads = updated);
    } catch (e) {
      debugPrint('[MessagesScreen] thread poll error: $e');
    }
  }

  Future<void> _fetchData() async {
    final auth = context.read<AuthProvider>();
    final token = auth.accessToken;
    if (token == null) {
      if (!mounted) return;
      setState(() {
        _threads = List.from(_mockThreads);
        _connections = List.from(_mockConnections);
        _loading = false;
      });
      return;
    }

    // Initialize WebSocket + FCM via MessageProvider
    final msgProvider = context.read<MessageProvider>();
    await msgProvider.init(token);

    _globalWsSub?.cancel();
    _globalWsSub = msgProvider.messageStream.listen((data) {
      if (data['type'] == 'presence_update') {
        final payload = data['payload'] as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            for (int i = 0; i < _threads.length; i++) {
              if (_threads[i].otherUserId == payload['user_id']) {
                final t = _threads[i];
                _threads[i] = _ChatThread(
                  id: t.id,
                  name: t.name,
                  lastMessage: t.lastMessage,
                  time: t.time,
                  avatarColor: t.avatarColor,
                  avatarLabel: t.avatarLabel,
                  isVerified: t.isVerified,
                  isPinged: t.isPinged,
                  unreadCount: t.unreadCount,
                  type: t.type,
                  eventTag: t.eventTag,
                  otherUserId: t.otherUserId,
                  isOnline: payload['is_online'] == true,
                );
              }
            }
            // Update connections
            for (int i = 0; i < _connections.length; i++) {
              if (_connections[i].id == payload['user_id']) {
                final c = _connections[i];
                _connections[i] = _Connection(
                  c.id,
                  c.name,
                  c.fallbackColor,
                  payload['is_online'] == true,
                );
              }
            }
          });
        }
      }
    });

    try {
      // Fetch real connections and threads in parallel
      final results = await Future.wait([
        ApiService.getConnections(token),
        ApiService.getThreads(token),
      ]);

      if (!mounted) return;

      // Parse connections
      final connRes = results[0];
      if (connRes.statusCode == 200) {
        final List<dynamic> connData = jsonDecode(connRes.body);
        _connections = connData.map((c) {
          final name = c['full_name'] ?? c['email'] ?? 'User';
          return _Connection(
            c['user_id'] ?? '',
            name.split(' ').first,
            _colorFromId(c['user_id'] ?? ''),
            false,
          );
        }).toList();
      }

      // Parse threads
      final threadRes = results[1];
      if (threadRes.statusCode == 200) {
        final List<dynamic> threadData = jsonDecode(threadRes.body);
        _threads = threadData.map((t) {
          // Backend returns other_user_name (falls back to email) and name
          final name = (t['other_user_name'] as String? ?? '').isNotEmpty
              ? t['other_user_name'] as String
              : (t['name'] as String? ?? t['thread_type'] as String? ?? 'Chat');
          final lastMsg = t['last_message'] ?? '';
          final isGroup = (t['thread_type'] ?? t['type']) == 'group';
          return _ChatThread(
            id: t['id'] ?? '',
            name: name,
            lastMessage: lastMsg,
            time: _formatTime(t['last_message_at'] ?? t['updated_at'] ?? ''),
            avatarColor: _colorFromId(t['id'] ?? ''),
            avatarLabel: name.isNotEmpty ? name[0].toUpperCase() : '?',
            type: isGroup ? _ChatType.group : _ChatType.direct,
            otherUserId: t['other_user_id'] as String?,
            unreadCount: t['unread_count'] as int? ?? 0,
            isOnline: t['is_online'] == true,
          );
        }).toList();
      }

      // Sync connection statuses with thread statuses since connections API lacks online state
      if (_threads.isNotEmpty && _connections.isNotEmpty) {
        for (int i = 0; i < _connections.length; i++) {
          final threadIdx = _threads.indexWhere((t) => t.otherUserId == _connections[i].id);
          if (threadIdx != -1) {
            final c = _connections[i];
            _connections[i] = _Connection(c.id, c.name, c.fallbackColor, _threads[threadIdx].isOnline);
          }
        }
      }

      // Only show mocks if NOTHING was returned at all
      if (_threads.isEmpty && _connections.isEmpty) {
        _threads = List.from(_mockThreads);
        _connections = List.from(_mockConnections);
      } else if (_connections.isEmpty) {
        // Keep connections mock if real ones aren't available yet
        _connections = List.from(_mockConnections);
      }

      setState(() => _loading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _threads = List.from(_mockThreads);
        _connections = List.from(_mockConnections);
        _loading = false;
      });
    }
  }

  static Color _colorFromId(String id) {
    final colors = [
      const Color(0xFF5C6BC0), const Color(0xFFEC407A),
      const Color(0xFF26A69A), const Color(0xFFFF7043),
      const Color(0xFF42A5F5), const Color(0xFFAB47BC),
      const Color(0xFF66BB6A), const Color(0xFFFFCA28),
    ];
    return colors[id.hashCode.abs() % colors.length];
  }

  static String _formatTime(String isoTime) {
    if (isoTime.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoTime);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays == 1) return 'Yesterday';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }

  Future<void> _startDirectChat(_Connection conn) async {
    final auth = context.read<AuthProvider>();
    final token = auth.accessToken;
    if (token == null) return;

    try {
      final res = await ApiService.createDirectThread(token, conn.id);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final threadId = (data['id'] ?? data['thread_id'] ?? '').toString();
        if (threadId.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not start chat — try again')),
          );
          return;
        }
        final thread = _ChatThread(
          id: threadId,
          name: conn.name,
          lastMessage: '',
          time: 'Now',
          avatarColor: conn.fallbackColor,
          avatarLabel: conn.name.isNotEmpty ? conn.name[0] : '?',
          type: _ChatType.direct,
          otherUserId: conn.id,
        );
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => _ChatDetailScreen(thread: thread)),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start chat')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Trying to fallback...')),
      );
    }
  }

  @override
  void dispose() {
    _threadPollTimer?.cancel();
    _wsSub?.cancel();
    _globalWsSub?.cancel();
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_ChatThread> _filtered(_ChatType? typeFilter) {
    return _threads.where((t) {
      if (typeFilter == null && t.type == _ChatType.request) return false;
      final matchesType = typeFilter == null || t.type == typeFilter;
      final matchesQuery = _query.isEmpty ||
          t.name.toLowerCase().contains(_query.toLowerCase()) ||
          t.lastMessage.toLowerCase().contains(_query.toLowerCase());
      return matchesType && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allCount = _threads.where((t) => t.type != _ChatType.request).length;
    final directCount = _threads.where((t) => t.type == _ChatType.direct).length;
    final groupCount = _threads.where((t) => t.type == _ChatType.group).length;
    final requestCount = _threads.where((t) => t.type == _ChatType.request).length;

    return AppScaffold(
      body: Column(
          children: [
          // ── App Bar ──────────────────────────────────────────────────────
          CustomAppBar(
            title: 'Messages',
            actions: [
              Stack(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    ),
                    icon: Icon(Icons.notifications_outlined, color: theme.colorScheme.onSurface, size: 26),
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_loading) 
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else ...[
            // ── Active Connections ───────────────────────────────────────────
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _connections.length,
                itemBuilder: (context, index) {
                  final conn = _connections[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: GestureDetector(
                      onTap: () => _startDirectChat(conn),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: conn.fallbackColor.withValues(alpha: 0.2),
                                child: Text(
                                  conn.name[0],
                                  style: TextStyle(
                                    color: conn.fallbackColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              if (conn.isOnline)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4CAF50),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: theme.scaffoldBackgroundColor,
                                        width: 2.5,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            conn.name,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Search Bar ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search messages...',
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
                    size: 20,
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                          child: Icon(Icons.close, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                        )
                      : null,
                  filled: true,
                  fillColor: theme.colorScheme.surfaceVariant.withValues(alpha: 0.45),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // ── Connection Search Results ─────────────────────────────────────
            if (_query.isNotEmpty) ...[
              Builder(builder: (context) {
                final matchedConns = _connections
                    .where((c) => c.name.toLowerCase().contains(_query.toLowerCase()))
                    .toList();
                if (matchedConns.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                      child: Text(
                        'Contacts',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    ...matchedConns.map((conn) => ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      leading: CircleAvatar(
                        backgroundColor: conn.fallbackColor.withValues(alpha: 0.2),
                        child: Text(
                          conn.name[0],
                          style: TextStyle(color: conn.fallbackColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(conn.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      subtitle: Text('Tap to message', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                      trailing: Icon(Icons.chat_bubble_outline_rounded, color: theme.colorScheme.primary, size: 18),
                      onTap: () => _startDirectChat(conn),
                    )),
                    Divider(height: 1, color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                    const SizedBox(height: 8),
                  ],
                );
              }),
            ],

            // ── Tab Bar ──────────────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabCtrl,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicator: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: [
                  Tab(text: 'All ($allCount)'),
                  Tab(text: 'Direct ($directCount)'),
                  Tab(text: 'Groups ($groupCount)'),
                  Tab(text: 'Requests ($requestCount)'),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Tab Views ────────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _ThreadList(threads: _filtered(null)),
                  _ThreadList(threads: _filtered(_ChatType.direct)),
                  _ThreadList(threads: _filtered(_ChatType.group)),
                  _ThreadList(threads: _filtered(_ChatType.request)),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  THREAD LIST
// ─────────────────────────────────────────────────────────────────────────────
class _ThreadList extends StatelessWidget {
  final List<_ChatThread> threads;
  const _ThreadList({required this.threads});

  @override
  Widget build(BuildContext context) {
    if (threads.isEmpty) {
      return Center(
        child: Text(
          'No conversations yet',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
      itemCount: threads.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        indent: 76,
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.08),
      ),
      itemBuilder: (ctx, i) => _ThreadTile(thread: threads[i]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  THREAD TILE
// ─────────────────────────────────────────────────────────────────────────────
class _ThreadTile extends StatelessWidget {
  final _ChatThread thread;
  const _ThreadTile({required this.thread});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGroup = thread.type == _ChatType.group;
    final isUnread = thread.unreadCount > 0;

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => _ChatDetailScreen(thread: thread)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar ────────────────────────────────────────────────────
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: thread.avatarColor.withValues(alpha: 0.2),
                  child: isGroup
                      ? Icon(Icons.group, color: thread.avatarColor, size: 24)
                      : Text(
                          thread.avatarLabel,
                          style: TextStyle(color: thread.avatarColor, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                ),
                if (!isGroup && thread.isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // ── Content ───────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                thread.name,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: isUnread ? FontWeight.w900 : FontWeight.w700,
                                  color: isUnread ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (thread.isVerified) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified, size: 10, color: theme.colorScheme.primary),
                                    const SizedBox(width: 2),
                                    Text('Verified', style: TextStyle(color: theme.colorScheme.primary, fontSize: 9, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ],
                            if (thread.isPinged) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF7043).withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('Active', style: TextStyle(color: Color(0xFFFF7043), fontSize: 9, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 65,
                        child: Text(
                          thread.time,
                          textAlign: TextAlign.right,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isUnread ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.45),
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (thread.eventTag != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      thread.eventTag!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          thread.lastMessage,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isUnread ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withValues(alpha: 0.55),
                            fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            thread.unreadCount > 99 ? '99+' : '${thread.unreadCount}',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CHAT DETAIL SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class _ChatDetailScreen extends StatefulWidget {
  final _ChatThread thread;
  const _ChatDetailScreen({required this.thread});

  @override
  State<_ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<_ChatDetailScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  List<_Bubble> _bubbles = [];
  bool _loading = true;
  bool _isOnline = false;
  int? _replyToIndex;
  bool _showEmojiPicker = false;
  final Set<int> _selectedIndices = {};
  bool get _isSelecting => _selectedIndices.isNotEmpty;

  void _toggleSelect(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _clearSelection() => setState(() => _selectedIndices.clear());

  @override
  void initState() {
    super.initState();
    _isOnline = widget.thread.isOnline;
    _fetchMessages();
    // Start WS listener for native real-time
    _setupWSListener();

    _timeUpdateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _setupWSListener() {
    final auth = context.read<AuthProvider>();
    final userId = auth.userId;
    final msgProvider = context.read<MessageProvider>();
    _wsSub?.cancel();
    _wsSub = msgProvider.messageStream.listen((data) {
      final type = data['type'];
      if (type == 'new_message') {
        final msg = data['payload'] as Map<String, dynamic>;
        if (msg['thread_id'] == widget.thread.id && mounted) {
          setState(() {
            _bubbles.add(_Bubble(
              id: msg['id'] ?? '',
              text: msg['content'] ?? '',
              isMe: msg['sender_id'] == userId,
              isoTime: msg['created_at'] ?? '',
              senderName: msg['sender_name'] ?? '',
              replyToText: msg['reply_to_content'],
              replyToSender: msg['reply_to_sender'],
              isForwarded: msg['is_forwarded'] == true,
            ));
          });
          _scrollToBottom();
        }
      } else if (type == 'message_sent') {
        final payload = data['payload'] as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            final idx = _bubbles.indexWhere((b) => b.id.startsWith('temp_'));
            if (idx != -1) {
              _bubbles[idx] = _Bubble(
                id: payload['message_id'] ?? '',
                text: _bubbles[idx].text,
                isMe: true,
                isoTime: payload['created_at'] ?? _bubbles[idx].isoTime,
                senderName: _bubbles[idx].senderName,
                replyToText: _bubbles[idx].replyToText,
                replyToSender: _bubbles[idx].replyToSender,
                isForwarded: _bubbles[idx].isForwarded,
              );
            }
          });
        }
      } else if (type == 'message_deleted') {
        final payload = data['payload'] as Map<String, dynamic>;
        if (payload['thread_id'] == widget.thread.id && mounted) {
          setState(() {
            _bubbles.removeWhere((b) => b.id == payload['message_id']);
          });
        }
      } else if (type == 'presence_update') {
        final payload = data['payload'] as Map<String, dynamic>;
        if (widget.thread.otherUserId == payload['user_id'] && mounted) {
          setState(() {
            _isOnline = payload['is_online'] == true;
          });
        }
      }
    });
  }

  StreamSubscription? _wsSub;
  Timer? _pollTimer;
  Timer? _timeUpdateTimer;

  @override
  void dispose() {
    _wsSub?.cancel();
    _pollTimer?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages({bool silent = false}) async {
    final auth = context.read<AuthProvider>();
    final token = auth.accessToken;
    final userId = auth.userId;
    if (token == null) {
      _loadMock();
      return;
    }

    try {
      final res = await ApiService.getMessages(token, widget.thread.id);
      if (!mounted) return;
      
      // Async fire-and-forget: mark the chat as read
      ApiService.markAsRead(token, widget.thread.id);

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        final incoming = data.reversed.map((m) => _Bubble(
          id: m['id'] ?? '',
          text: m['content'] ?? '',
          isMe: m['sender_id'] == userId,
          isoTime: m['created_at'] ?? '',
          senderName: m['sender_name'] ?? '',
          replyToText: m['reply_to_content'],
          replyToSender: m['reply_to_sender'],
          isForwarded: m['is_forwarded'] == true,
        )).toList();

        if (silent) {
          // Merge: find any new messages not already in the list
          final existingIds = _bubbles.map((b) => b.id).toSet();
          final newOnes = incoming.where((b) => b.id.isNotEmpty && !existingIds.contains(b.id)).toList();
          if (newOnes.isNotEmpty && mounted) {
            setState(() => _bubbles.addAll(newOnes));
            _scrollToBottom();
          }
        } else {
          setState(() {
            _bubbles = incoming;
            _loading = false;
          });
          // Always start polling for new messages (ONLY if disconnected)
          _pollTimer?.cancel();
          _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
            final isConnected = context.read<MessageProvider>().isConnected;
            if (!isConnected) {
              _fetchMessages(silent: true);
            }
          });
        }

        _scrollToBottom();
      } else {
        _loadMock();
      }
    } catch (e) {
      debugPrint('[ChatDetail] fetch error: $e');
      _loadMock();
    }
  }

  void _loadMock() {
    if (!mounted) return;
    setState(() {
      final dummyNow = DateTime.now().toIso8601String();
      _bubbles = [
        _Bubble(text: 'Hey! Are you going to the hackathon?', isMe: false, isoTime: dummyNow),
        _Bubble(text: 'Yes! Super excited. Did you register?', isMe: true, isoTime: dummyNow),
        _Bubble(text: 'Not yet. Team of 3 or 4?', isMe: false, isoTime: dummyNow),
        _Bubble(text: 'Open to 4. We have AI and backend covered 🚀', isMe: true, isoTime: dummyNow),
        _Bubble(text: 'Nice! I can do frontend + design', isMe: false, isoTime: dummyNow),
        _Bubble(text: 'Perfect! Shall we book travel together?', isMe: true, isoTime: dummyNow),
        _Bubble(text: 'Sounds good! See you at the airport 🛫', isMe: false, isoTime: dummyNow),
      ];
      _loading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final replyIndex = _replyToIndex;
    final replyBubble = replyIndex != null ? _bubbles[replyIndex] : null;

    setState(() {
      _bubbles.add(_Bubble(
        id: tempId, 
        text: text, 
        isMe: true, 
        isoTime: DateTime.now().toIso8601String(),
        replyToText: replyBubble?.text,
        replyToSender: replyBubble?.isMe == true ? 'You' : replyBubble?.senderName,
      ));
      _msgCtrl.clear();
      _replyToIndex = null;
    });
    _scrollToBottom();

    // Send via MessageProvider (WebSocket primary, HTTP fallback returns the real ID)
    final msgProvider = context.read<MessageProvider>();
    final realId = await msgProvider.sendMessage(
      widget.thread.id, 
      text,
      replyToId: replyBubble?.id,
    );
    
    // If HTTP fallback succeeded, it returns the real ID. Replace the temp ID so polling doesn't duplicate it.
    if (realId != null && mounted) {
      setState(() {
        final idx = _bubbles.indexWhere((b) => b.id == tempId);
        if (idx != -1) {
          _bubbles[idx] = _Bubble(
            id: realId,
            text: _bubbles[idx].text,
            isMe: true,
            isoTime: _bubbles[idx].isoTime,
            senderName: _bubbles[idx].senderName,
            replyToText: _bubbles[idx].replyToText,
            replyToSender: _bubbles[idx].replyToSender,
            isForwarded: _bubbles[idx].isForwarded,
          );
        }
      });
    }
  }

  void _showMessageActions(int index) {
    final bubble = _bubbles[index];
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Drag Handle ──
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // ── Preview of bubble text ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    bubble.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                // ── Action Buttons ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMsgAction(ctx, Icons.reply_rounded, 'Reply', const Color(0xFF5C6BC0), () {
                      Navigator.pop(ctx);
                      setState(() => _replyToIndex = index);
                      _msgCtrl.clear();
                      FocusScope.of(context).requestFocus(FocusNode()); // trigger keyboard
                    }),
                    _buildMsgAction(ctx, Icons.copy_rounded, 'Copy', const Color(0xFF26A69A), () {
                      Clipboard.setData(ClipboardData(text: bubble.text));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Message copied'), duration: Duration(seconds: 2)),
                      );
                    }),
                    _buildMsgAction(ctx, Icons.shortcut_rounded, 'Forward', const Color(0xFFFF7043), () {
                      Navigator.pop(ctx);
                      _showForwardDialog(bubble.text);
                    }),
                    _buildMsgAction(ctx, Icons.check_circle_outline, 'Select', const Color(0xFF42A5F5), () {
                      Navigator.pop(ctx);
                      _toggleSelect(index);
                    }),
                    if (bubble.isMe)
                      _buildMsgAction(ctx, Icons.delete_outline_rounded, 'Delete', const Color(0xFFEF5350), () {
                        Navigator.pop(ctx);
                        if (bubble.id.isNotEmpty && !bubble.id.startsWith('temp_')) {
                          context.read<MessageProvider>().deleteMessage(bubble.id);
                        }
                        setState(() => _bubbles.removeAt(index));
                      }),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMsgAction(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }

  void _showForwardDialog(String forwardText) async {
    final auth = context.read<AuthProvider>();
    final token = auth.accessToken;
    if (token == null) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            String searchQuery = '';
            return Dialog(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: FutureBuilder(
                future: ApiService.getConnections(token),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const SizedBox(height: 200, child: Center(child: Text('Failed to load connections')));
                  }
                  
                  final connRes = snapshot.data as http.Response;
                  if (connRes.statusCode != 200) {
                    return const SizedBox(height: 200, child: Center(child: Text('Failed to load connections')));
                  }

                  final List<dynamic> data = jsonDecode(connRes.body);
                  final filteredData = data.where((c) {
                    final name = c['full_name'] ?? c['email'] ?? '';
                    return name.toString().toLowerCase().contains(searchQuery.toLowerCase());
                  }).toList();

                  return Container(
                    height: MediaQuery.of(context).size.height * 0.6,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Forward to...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 12),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Search connections...',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.5),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                          ),
                          onChanged: (val) {
                            setDialogState(() => searchQuery = val);
                          },
                        ),
                        const SizedBox(height: 12),
                        if (filteredData.isEmpty)
                          const Expanded(child: Center(child: Text('No matching connections')))
                        else
                          Expanded(
                            child: ListView.builder(
                              itemCount: filteredData.length,
                              itemBuilder: (context, i) {
                                final c = filteredData[i];
                                final name = c['full_name'] ?? c['email'] ?? 'User';
                                final targetUserId = c['user_id'] ?? '';
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                    child: Text(name[0].toUpperCase(), style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                                  ),
                                  title: Text(name),
                                  onTap: () async {
                                    Navigator.pop(ctx);
                                    final msgProvider = context.read<MessageProvider>();
                                    // Get or create thread
                                    final threadId = await msgProvider.getOrCreateDirectThread(targetUserId);
                                    if (threadId != null) {
                                      await msgProvider.sendMessage(threadId, forwardText, isForwarded: true);
                                      if (threadId == widget.thread.id) {
                                        setState(() {
                                          _bubbles.add(_Bubble(
                                            id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
                                            text: forwardText,
                                            isMe: true,
                                            isoTime: DateTime.now().toIso8601String(),
                                            isForwarded: true,
                                          ));
                                        });
                                        _scrollToBottom();
                                      }
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Forwarded to $name')));
                                      }
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showProfileSheet() {
    final t = widget.thread;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: PublicProfileScreen(userId: widget.thread.id),
              ),
            ],
          ),
        );
      },
    );
  }



  @override

  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = widget.thread;
    final isGroup = t.type == _ChatType.group;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0.5,
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: GestureDetector(
          onTap: _showProfileSheet,
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: t.avatarColor.withValues(alpha: 0.18),
                child: isGroup
                    ? Icon(Icons.group, color: t.avatarColor, size: 18)
                    : Text(t.avatarLabel, style: TextStyle(color: t.avatarColor, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  if (t.eventTag != null)
                    Text(t.eventTag!, style: TextStyle(fontSize: 10, color: theme.colorScheme.primary.withValues(alpha: 0.7), fontWeight: FontWeight.w600))
                  else if (_isOnline)
                    const Text('Online', style: TextStyle(fontSize: 10, color: Color(0xFF4CAF50), fontWeight: FontWeight.w600))
                  else
                    Text('Offline', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          if (_isSelecting) ...[
            IconButton(
              onPressed: () {
                final texts = _selectedIndices.toList()
                  ..sort();
                final copied = texts.map((i) => _bubbles[i].text).join('\n');
                Clipboard.setData(ClipboardData(text: copied));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${texts.length} message(s) copied'), duration: const Duration(seconds: 2)),
                );
                _clearSelection();
              },
              icon: Icon(Icons.copy, color: theme.colorScheme.onSurface.withValues(alpha: 0.7), size: 22),
            ),
            if (!_selectedIndices.any((i) => !_bubbles[i].isMe))
              IconButton(
                onPressed: () {
                  final count = _selectedIndices.length;
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text('Delete Messages'),
                      content: Text('Delete $count selected message(s)?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            final msgProvider = context.read<MessageProvider>();
                            setState(() {
                              final sorted = _selectedIndices.toList()..sort((a, b) => b.compareTo(a));
                              for (final i in sorted) {
                                final b = _bubbles[i];
                                if (b.id.isNotEmpty && !b.id.startsWith('temp_')) {
                                  msgProvider.deleteMessage(b.id);
                                }
                                _bubbles.removeAt(i);
                              }
                              _selectedIndices.clear();
                            });
                          },
                          child: Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
                        ),
                      ],
                    ),
                  );
                },
                icon: Icon(Icons.delete_outline, color: theme.colorScheme.error, size: 22),
              ),
            IconButton(
              onPressed: _clearSelection,
              icon: Icon(Icons.close, color: theme.colorScheme.onSurface.withValues(alpha: 0.7), size: 22),
            ),
          ] else
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 8,
              offset: const Offset(0, 48),
              onSelected: (value) {
                switch (value) {
                  case 'profile':
                    _showProfileSheet();
                    break;
                  case 'search':
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Search coming soon'), duration: Duration(seconds: 2)),
                    );
                    break;
                  case 'mute':
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notifications muted'), duration: Duration(seconds: 2)),
                    );
                    break;
                  case 'clear':
                    final msgProv = context.read<MessageProvider>();
                    msgProv.clearThread(widget.thread.id);
                    setState(() => _bubbles.clear());
                    break;
                  case 'block':
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Text('Block User'),
                        content: Text('Are you sure you want to block ${widget.thread.name}?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              
                              final otherId = widget.thread.otherUserId;
                              if (otherId == null || otherId.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Cannot block this chat')),
                                );
                                return;
                              }
                              
                              final token = context.read<AuthProvider>().accessToken;
                              if (token == null) return;
                              
                              try {
                                final res = await ApiService.blockUser(token, otherId);
                                if (!mounted) return;
                                if (res.statusCode == 200) {
                                  Navigator.pop(context); // Close chat thread
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${widget.thread.name} has been blocked')),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Failed to block user')),
                                  );
                                }
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Connection failed')),
                                );
                              }
                            },
                            child: Text('Block', style: TextStyle(color: theme.colorScheme.error)),
                          ),
                        ],
                      ),
                    );
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(isGroup ? Icons.group_outlined : Icons.person_outline, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                      const SizedBox(width: 12),
                      Text(isGroup ? 'Group Info' : 'View Profile'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'search',
                  child: Row(
                    children: [
                      Icon(Icons.search, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                      const SizedBox(width: 12),
                      const Text('Search in Chat'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'mute',
                  child: Row(
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                      const SizedBox(width: 12),
                      const Text('Mute Notifications'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.cleaning_services_outlined, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                      const SizedBox(width: 12),
                      const Text('Clear Chat'),
                    ],
                  ),
                ),
                if (!isGroup)
                  PopupMenuItem(
                    value: 'block',
                    child: Row(
                      children: [
                        Icon(Icons.block, size: 20, color: theme.colorScheme.error),
                        const SizedBox(width: 12),
                        Text('Block User', style: TextStyle(color: theme.colorScheme.error)),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Messages ──────────────────────────────────────────────────
          Expanded(
            child: _loading 
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _bubbles.length,
              itemBuilder: (_, i) => _BubbleWidget(
                bubble: _bubbles[i],
                thread: t,
                isSelected: _selectedIndices.contains(i),
                isSelecting: _isSelecting,
                onLongPress: () => _showMessageActions(i),
                onTapInSelectMode: () => _toggleSelect(i),
              ),
            ),
          ),
          // ── Input Bar ─────────────────────────────────────────────────
          if (_replyToIndex != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: theme.colorScheme.surface,
              child: Row(
                children: [
                  Icon(Icons.reply_rounded, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _bubbles[_replyToIndex!].isMe ? 'Replying to yourself' : 'Replying to ${_bubbles[_replyToIndex!].senderName}',
                          style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        Text(
                          _bubbles[_replyToIndex!].text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                    onPressed: () => setState(() => _replyToIndex = null),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          Container(
            color: theme.colorScheme.surface,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(_showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                    onPressed: () {
                      FocusScope.of(context).unfocus(); // Close keyboard
                      setState(() => _showEmojiPicker = !_showEmojiPicker);
                    },
                    padding: const EdgeInsets.only(right: 8),
                    constraints: const BoxConstraints(),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      focusNode: FocusNode()..addListener(() {
                        if (mounted) setState(() => _showEmojiPicker = false);
                      }),
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 14),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceVariant.withValues(alpha: 0.4),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showEmojiPicker)
            SizedBox(
              height: 250,
              child: EmojiPicker(
                textEditingController: _msgCtrl,
                config: Config(
                  emojiViewConfig: EmojiViewConfig(
                    backgroundColor: theme.scaffoldBackgroundColor,
                    columns: 7,
                    emojiSizeMax: 32,
                  ),
                  bottomActionBarConfig: BottomActionBarConfig(
                    backgroundColor: theme.scaffoldBackgroundColor,
                    buttonColor: theme.scaffoldBackgroundColor,
                    buttonIconColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  BUBBLE
// ─────────────────────────────────────────────────────────────────────────────
class _Bubble {
  final String id;
  final String text;
  final bool isMe;
  final String isoTime;
  final String senderName;
  final String? replyToText;
  final String? replyToSender;
  final bool isForwarded;

  String get time => _MessagesScreenState._formatTime(isoTime);

  const _Bubble({
    this.id = '', 
    required this.text, 
    required this.isMe, 
    required this.isoTime, 
    this.senderName = '',
    this.replyToText,
    this.replyToSender,
    this.isForwarded = false,
  });
}

class _BubbleWidget extends StatelessWidget {
  final _Bubble bubble;
  final _ChatThread thread;
  final bool isSelected;
  final bool isSelecting;
  final VoidCallback onLongPress;
  final VoidCallback onTapInSelectMode;

  const _BubbleWidget({
    required this.bubble,
    required this.thread,
    required this.isSelected,
    required this.isSelecting,
    required this.onLongPress,
    required this.onTapInSelectMode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMe = bubble.isMe;

    return GestureDetector(
      onLongPress: onLongPress,
      onTap: isSelecting ? onTapInSelectMode : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: isSelected
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isSelecting)
              Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 8),
                child: Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  size: 22,
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
            if (!isMe && !isSelecting) ...[
              CircleAvatar(
                radius: 14,
                backgroundColor: thread.avatarColor.withValues(alpha: 0.15),
                child: Text(
                  thread.avatarLabel,
                  style: TextStyle(color: thread.avatarColor, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? theme.colorScheme.primary : theme.colorScheme.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMe ? 18 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 18),
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (bubble.isForwarded)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.shortcut_rounded, size: 12, color: isMe ? Colors.white70 : theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                                const SizedBox(width: 4),
                                Text('Forwarded', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 10, color: isMe ? Colors.white70 : theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                              ],
                            ),
                          ),
                        if (bubble.replyToText != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.white.withValues(alpha: 0.15) : theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bubble.replyToSender ?? '',
                                  style: TextStyle(
                                    color: isMe ? Colors.white70 : theme.colorScheme.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  bubble.replyToText!,
                                  style: TextStyle(
                                    color: isMe ? Colors.white.withValues(alpha: 0.85) : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                    fontSize: 12,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                        Text(
                          bubble.text,
                          style: TextStyle(color: isMe ? Colors.white : theme.colorScheme.onSurface, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    bubble.time,
                    style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 10),
                  ),
                ],
              ),
            ),
            if (isMe && !isSelecting) const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
