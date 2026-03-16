import 'package:flutter/material.dart';
import 'package:college_hop/theme/app_scaffold.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _notifications = [
    {
      "title": "New Match Found!",
      "message":
          "Ananya Singh is also going to Hackathon @ IIT Delhi. She shares 2 interests with you!",
      "time": "2m ago",
      "type": NotificationType.match,
      "isUnread": true,
    },
    {
      "title": "Travel Group Invite",
      "message": "Rahul Patel invited you to join IIT Delhi Carpool.",
      "time": "15m ago",
      "type": NotificationType.invite,
      "isUnread": true,
    },
    {
      "title": "Message from Priya",
      "message": "Hey! Are you still looking for a ride to the venue?",
      "time": "1h ago",
      "type": NotificationType.message,
      "isUnread": false,
    },
    {
      "title": "New Event Suggestion",
      "message": "AI Conference @ IIT Madras matches your interests.",
      "time": "3h ago",
      "type": NotificationType.match,
      "isUnread": true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme),
            _buildTabBar(theme),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildNotificationList(theme, _notifications),
                  _buildNotificationList(
                    theme,
                    _notifications.where((n) => n["isUnread"] == true).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 6),
      child: Row(
        children: [
          IconButton(
            icon: 
             Icon(Icons.arrow_back,
                color: theme.colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              "Notifications",
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                for (var n in _notifications) {
                  n["isUnread"] = false;
                }
              });
            },
            child: Text(
              "Mark all as read",
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        height: 45,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          labelColor: colors.primary,
          unselectedLabelColor: colors.onSurface.withValues(alpha: 0.5),
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: "All"),
            Tab(text: "Unread"),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList(
      ThemeData theme, List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return _buildEmptyState(theme);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final n = list[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _NotificationCard(
            theme: theme,
            title: n["title"],
            message: n["message"],
            time: n["time"],
            type: n["type"],
            isUnread: n["isUnread"],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none,
              size: 60, color: theme.colorScheme.primary.withValues(alpha: 0.2)),
          const SizedBox(height: 10),
          const Text("All caught up!",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const Text("No unread notifications"),
        ],
      ),
    );
  }
}

enum NotificationType { match, invite, message }

class _NotificationCard extends StatelessWidget {
  final ThemeData theme;
  final String title;
  final String message;
  final String time;
  final NotificationType type;
  final bool isUnread;

  const _NotificationCard({
    required this.theme,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    required this.isUnread,
  });

  @override
  Widget build(BuildContext context) {
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                                color: colors.primary,
                                shape: BoxShape.circle),
                          )
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(height: 6),
                    Text(time,
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.4))),
                  ],
                ),
              ),
            ],
          ),
          if (type == NotificationType.match ||
              type == NotificationType.invite) ...[
            const SizedBox(height: 12),
            if (type == NotificationType.match)
              _primaryButton("View Profile", colors)
            else
              Row(
                children: [
                  Expanded(child: _primaryButton("Accept", colors)),
                  const SizedBox(width: 10),
                  Expanded(child: _secondaryButton("Decline", colors)),
                ],
              )
          ]
        ],
      ),
    );
  }

  Widget _buildIcon() {
    IconData icon;
    Color color;

    if (type == NotificationType.match) {
      icon = Icons.auto_awesome;
      color = Colors.orange;
    } else if (type == NotificationType.invite) {
      icon = Icons.group_add;
      color = theme.colorScheme.primary;
    } else {
      icon = Icons.chat_bubble_outline;
      color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration:
          BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 18),
    );
  }

  Widget _primaryButton(String text, ColorScheme colors) {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }

  Widget _secondaryButton(String text, ColorScheme colors) {
    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colors.outline.withValues(alpha: 0.3)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }
}
