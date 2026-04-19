import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:college_hop/providers/auth_provider.dart';
import 'package:college_hop/providers/profile_provider.dart';
import 'package:college_hop/providers/message_provider.dart';
import 'package:college_hop/screen/notification_screen.dart';

/// A unified app bar used across all main screens.
/// Title is center-aligned. Avatar on the left, actions on the right.
class CustomAppBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileData = context.watch<ProfileProvider>().profileData;
    final msgProvider = context.watch<MessageProvider>();
    final hasUnread = msgProvider.hasPendingRequests;

    // Lazily load threads so the red dot works on all screens (MyEvent, Groups),
    // not just Messages which is the only screen calling init().
    final token = context.read<AuthProvider>().accessToken;
    if (token != null) {
      Future.microtask(() => msgProvider.loadThreadsIfNeeded(token));
    }

    final String? photoUrl = profileData != null
        ? profileData['profile_photo_url'] as String?
        : null;
    final initial = (profileData != null &&
            profileData['name'] != null &&
            (profileData['name'] as String).isNotEmpty)
        ? (profileData['name'] as String)[0].toUpperCase()
        : 'U';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.primary,
            backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                ? NetworkImage(photoUrl)
                : null,
            child: (photoUrl == null || photoUrl.isEmpty)
                ? Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  )
                : null,
          ),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (actions != null) ...actions!,
          Stack(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                ),
                icon: Icon(Icons.notifications_outlined, color: theme.colorScheme.onSurface, size: 26),
              ),
              if (hasUnread)
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
    );
  }
}
