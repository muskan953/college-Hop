import 'package:flutter/material.dart';
import 'package:college_hop/theme/app_scaffold.dart';
import 'package:college_hop/screen/notification_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────
enum _ChatType { direct, group }

class _ChatThread {
  final String id;
  final String name;
  final String lastMessage;
  final String time;
  final Color avatarColor;
  final String avatarLabel;
  final bool isVerified;
  final bool isPinged;      // active mention
  final int unreadCount;
  final _ChatType type;
  final String? eventTag;   // group: event name sub-label

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
  });
}

const _mockThreads = <_ChatThread>[
  _ChatThread(
    id: '1',
    name: 'Sarah Chen',
    lastMessage: 'Sounds good! See you at the airport 🛫',
    time: '2m ago',
    avatarColor: Color(0xFF5C6BC0),
    avatarLabel: 'S',
    isVerified: true,
    type: _ChatType.direct,
  ),
  _ChatThread(
    id: '2',
    name: 'Michael Kim',
    lastMessage: 'Did you book the hotel yet?',
    time: '15m ago',
    unreadCount: 3,
    avatarColor: Color(0xFFEC407A),
    avatarLabel: 'M',
    isVerified: true,
    type: _ChatType.direct,
  ),
  _ChatThread(
    id: '3',
    name: 'Hackathon @ IIT Deli',
    lastMessage: 'Alex: Can we split an Uber from the airport?',
    time: '1h ago',
    unreadCount: 5,
    avatarColor: Color(0xFF26A69A),
    avatarLabel: 'H',
    type: _ChatType.group,
    eventTag: 'IIT Delhi',
  ),
  _ChatThread(
    id: '4',
    name: 'Emma Wilson',
    lastMessage: 'Great connecting with you at the event!',
    time: '3h ago',
    avatarColor: Color(0xFFFF7043),
    avatarLabel: 'E',
    isPinged: true,
    type: _ChatType.direct,
  ),
  _ChatThread(
    id: '5',
    name: 'AWS Summit Trave...',
    lastMessage: 'Nina: Train leaves at 8 AM sharp',
    time: '5h ago',
    avatarColor: Color(0xFF42A5F5),
    avatarLabel: 'A',
    type: _ChatType.group,
    eventTag: 'AWS Summit',
  ),
  _ChatThread(
    id: '6',
    name: 'Jessica Lee',
    lastMessage: 'Looking forward to the hackathon!',
    time: 'Yesterday',
    avatarColor: Color(0xFFAB47BC),
    avatarLabel: 'J',
    isVerified: true,
    type: _ChatType.direct,
  ),
  _ChatThread(
    id: '7',
    name: 'TechFest Travel Group',
    lastMessage: 'You: See everyone there 🎉',
    time: 'Yesterday',
    avatarColor: Color(0xFF66BB6A),
    avatarLabel: 'T',
    type: _ChatType.group,
    eventTag: 'NIT Trichy',
  ),
  _ChatThread(
    id: '8',
    name: 'Ravi Sharma',
    lastMessage: 'Can you share your notes from the talk?',
    time: '2d ago',
    avatarColor: Color(0xFFFFCA28),
    avatarLabel: 'R',
    type: _ChatType.direct,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
//  MESSAGES SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final TextEditingController _searchCtrl = TextEditingController();
  
  late List<_ChatThread> _threads;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _threads = [
      _ChatThread(
        id: '1',
        name: 'Sarah Chen',
        lastMessage: 'Sounds good! See you at the airport 🛫',
        time: '2m ago',
        avatarColor: const Color(0xFF5C6BC0),
        avatarLabel: 'S',
        isVerified: true,
        type: _ChatType.direct,
      ),
      _ChatThread(
        id: '2',
        name: 'Michael Kim',
        lastMessage: 'Did you book the hotel yet?',
        time: '15m ago',
        avatarColor: const Color(0xFFEC407A),
        avatarLabel: 'M',
        isVerified: true,
        type: _ChatType.direct,
      ),
      _ChatThread(
        id: '3',
        name: 'Hackathon @ IIT Deli',
        lastMessage: 'Alex: Can we split an Uber from the airport?',
        time: '1h ago',
        avatarColor: const Color(0xFF26A69A),
        avatarLabel: 'H',
        type: _ChatType.group,
        eventTag: 'IIT Delhi',
      ),
      _ChatThread(
        id: '4',
        name: 'Emma Wilson',
        lastMessage: 'Great connecting with you at the event!',
        time: '3h ago',
        avatarColor: const Color(0xFFFF7043),
        avatarLabel: 'E',
        isPinged: true,
        type: _ChatType.direct,
      ),
      _ChatThread(
        id: '5',
        name: 'AWS Summit Trave...',
        lastMessage: 'Nina: Train leaves at 8 AM sharp',
        time: '5h ago',
        avatarColor: const Color(0xFF42A5F5),
        avatarLabel: 'A',
        type: _ChatType.group,
        eventTag: 'AWS Summit',
      ),
      _ChatThread(
        id: '6',
        name: 'Jessica Lee',
        lastMessage: 'Looking forward to the hackathon!',
        time: 'Yesterday',
        avatarColor: const Color(0xFFAB47BC),
        avatarLabel: 'J',
        isVerified: true,
        type: _ChatType.direct,
      ),
      _ChatThread(
        id: '7',
        name: 'TechFest Travel Group',
        lastMessage: 'You: See everyone there 🎉',
        time: 'Yesterday',
        avatarColor: const Color(0xFF66BB6A),
        avatarLabel: 'T',
        type: _ChatType.group,
        eventTag: 'NIT Trichy',
      ),
      _ChatThread(
        id: '8',
        name: 'Ravi Sharma',
        lastMessage: 'Can you share your notes from the talk?',
        time: '2d ago',
        avatarColor: const Color(0xFFFFCA28),
        avatarLabel: 'R',
        type: _ChatType.direct,
      ),
    ];
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_ChatThread> _filtered(_ChatType? typeFilter) {
    return _threads.where((t) {
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
    final allCount = _threads.length;
    final directCount =
        _threads.where((t) => t.type == _ChatType.direct).length;
    final groupCount =
        _threads.where((t) => t.type == _ChatType.group).length;

    return AppScaffold(
      body: Column(
        children: [
          // ── App Bar ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Row(
              children: [
                // Left balanced space
                const SizedBox(width: 48), // Match width of IconButton
                
                // Title (Centered)
                Expanded(
                  child: Center(
                    child: Text(
                      'Messages',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                // Notification (Right aligned)
                Stack(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const NotificationsScreen()),
                      ),
                      icon: Icon(
                        Icons.notifications_outlined,
                        color: theme.colorScheme.onSurface,
                        size: 26,
                      ),
                    ),
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
                        child: Icon(Icons.close,
                            size: 18,
                            color:
                                theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                      )
                    : null,
                filled: true,
                fillColor:
                    theme.colorScheme.surfaceVariant.withValues(alpha: 0.45),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

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
              indicator: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor:
                  theme.colorScheme.onSurface.withValues(alpha: 0.6),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              tabs: [
                Tab(text: 'All ($allCount)'),
                Tab(text: 'Direct ($directCount)'),
                Tab(text: 'Groups ($groupCount)'),
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
              ],
            ),
          ),
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
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
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
        MaterialPageRoute(
          builder: (_) => _ChatDetailScreen(thread: thread),
        ),
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
                          style: TextStyle(
                            color: thread.avatarColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                ),
                // online indicator for direct
                if (!isGroup)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.scaffoldBackgroundColor,
                          width: 2,
                        ),
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
                  // name row
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified,
                                        size: 10,
                                        color: theme.colorScheme.primary),
                                    const SizedBox(width: 2),
                                    Text(
                                      'Verified',
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (thread.isPinged) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF7043).withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Active',
                                  style: TextStyle(
                                    color: Color(0xFFFF7043),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
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
                            color: isUnread
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withValues(alpha: 0.45),
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // event tag for groups
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

                  // last message
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          thread.lastMessage,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isUnread
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurface.withValues(alpha: 0.55),
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
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

  final List<_Bubble> _bubbles = [
    _Bubble(text: 'Hey! Are you going to the hackathon?', isMe: false, time: '10:15 AM'),
    _Bubble(text: 'Yes! Super excited. Did you register?', isMe: true, time: '10:16 AM'),
    _Bubble(text: 'Not yet. Team of 3 or 4?', isMe: false, time: '10:17 AM'),
    _Bubble(text: 'Open to 4. We have AI and backend covered 🚀', isMe: true, time: '10:18 AM'),
    _Bubble(text: 'Nice! I can do frontend + design', isMe: false, time: '10:19 AM'),
    _Bubble(text: 'Perfect! Shall we book travel together?', isMe: true, time: '10:20 AM'),
    _Bubble(text: 'Sounds good! See you at the airport 🛫', isMe: false, time: '10:21 AM'),
  ];

  void _send() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _bubbles.add(_Bubble(text: text, isMe: true, time: 'Now'));
    });
    _msgCtrl.clear();
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

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
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
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: t.avatarColor.withValues(alpha: 0.18),
              child: isGroup
                  ? Icon(Icons.group, color: t.avatarColor, size: 18)
                  : Text(
                      t.avatarLabel,
                      style: TextStyle(
                        color: t.avatarColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.name,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (t.eventTag != null)
                  Text(
                    t.eventTag!,
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.primary.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  Text(
                    'Online',
                    style: TextStyle(
                      fontSize: 10,
                      color: const Color(0xFF4CAF50),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.more_vert,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Messages ──────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _bubbles.length,
              itemBuilder: (_, i) =>
                  _BubbleWidget(bubble: _bubbles[i], thread: t),
            ),
          ),
          // ── Input Bar ─────────────────────────────────────────────────
          Container(
            color: theme.colorScheme.surface,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceVariant
                            .withValues(alpha: 0.4),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
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
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
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
  final String text;
  final bool isMe;
  final String time;
  const _Bubble({required this.text, required this.isMe, required this.time});
}

class _BubbleWidget extends StatelessWidget {
  final _Bubble bubble;
  final _ChatThread thread;
  const _BubbleWidget({required this.bubble, required this.thread});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMe = bubble.isMe;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: thread.avatarColor.withValues(alpha: 0.15),
              child: Text(
                thread.avatarLabel,
                style: TextStyle(
                  color: thread.avatarColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    bubble.text,
                    style: TextStyle(
                      color: isMe
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  bubble.time,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }
}
