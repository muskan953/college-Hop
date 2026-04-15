import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:college_hop/providers/auth_provider.dart';
import 'package:college_hop/services/api_service.dart';
import 'package:college_hop/theme/app_scaffold.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  List<Map<String, dynamic>> _blockedUsers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchBlockedUsers();
  }

  Future<void> _fetchBlockedUsers() async {
    final token = context.read<AuthProvider>().accessToken;
    if (token == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await ApiService.getBlockedUsers(token);
      if (!mounted) return;

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          _blockedUsers = data.cast<Map<String, dynamic>>();
          _loading = false;
        });
      } else {
        setState(() {
          _error = "Failed to load blocked users";
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Connection failed";
        _loading = false;
      });
    }
  }

  Future<void> _unblockUser(String userId, String name) async {
    final token = context.read<AuthProvider>().accessToken;
    if (token == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Unblock User'),
        content: Text('Are you sure you want to unblock $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Unblock',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final res = await ApiService.unblockUser(token, userId);
      if (!mounted) return;

      if (res.statusCode == 200) {
        setState(() {
          _blockedUsers.removeWhere((u) => u['user_id'] == userId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name has been unblocked')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to unblock user')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        "Blocked Users",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 48,
                                  color: theme.colorScheme.error),
                              const SizedBox(height: 12),
                              Text(_error!,
                                  style: theme.textTheme.bodyLarge),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: _fetchBlockedUsers,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _blockedUsers.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_outline,
                                      size: 64,
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.5)),
                                  const SizedBox(height: 16),
                                  Text(
                                    "No blocked users",
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Users you block will appear here",
                                    style:
                                        theme.textTheme.bodyMedium?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              itemCount: _blockedUsers.length,
                              itemBuilder: (context, index) {
                                final user = _blockedUsers[index];
                                final name = (user['full_name'] as String?)
                                            ?.isNotEmpty ==
                                        true
                                    ? user['full_name']
                                    : user['email'] ?? 'Unknown';
                                final photoUrl =
                                    user['profile_photo_url'] as String? ??
                                        '';
                                final userId =
                                    user['user_id'] as String? ?? '';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: theme.colorScheme.outline
                                          .withValues(alpha: 0.15),
                                    ),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: theme
                                          .colorScheme.error
                                          .withValues(alpha: 0.1),
                                      backgroundImage:
                                          photoUrl.isNotEmpty
                                              ? NetworkImage(photoUrl)
                                              : null,
                                      child: photoUrl.isEmpty
                                          ? Icon(Icons.person,
                                              color:
                                                  theme.colorScheme.error)
                                          : null,
                                    ),
                                    title: Text(
                                      name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: user['email'] != null
                                        ? Text(
                                            user['email'],
                                            style: TextStyle(
                                              color: theme.colorScheme
                                                  .onSurfaceVariant,
                                              fontSize: 12,
                                            ),
                                          )
                                        : null,
                                    trailing: TextButton(
                                      onPressed: () =>
                                          _unblockUser(userId, name),
                                      style: TextButton.styleFrom(
                                        foregroundColor:
                                            theme.colorScheme.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          side: BorderSide(
                                            color: theme.colorScheme.primary
                                                .withValues(alpha: 0.3),
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 6),
                                      ),
                                      child: const Text(
                                        'Unblock',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
