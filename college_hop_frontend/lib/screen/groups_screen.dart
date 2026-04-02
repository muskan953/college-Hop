import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:college_hop/theme/app_scaffold.dart';
import 'package:college_hop/providers/auth_provider.dart';
import 'package:college_hop/services/api_service.dart';
import 'package:college_hop/screen/group_details_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  GROUPS SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _groups = [];
  bool _isCooldown = false;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchGroups() async {
    // 1) Implement 30s cooldown
    if (_isCooldown) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Text(
                'Please wait 30 seconds between refreshes',
                style: TextStyle(color: Colors.black87),
              ),
              backgroundColor: const Color(0xFFE0E0E0),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              elevation: 0,
            ),
          );
      }
      return;
    }

    setState(() {
      _isCooldown = true;
      _loading = true;
      _error = null;
    });

    _cooldownTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) {
        setState(() {
          _isCooldown = false;
        });
      }
    });



    final token = context.read<AuthProvider>().accessToken;
    if (token == null) {
      setState(() {
        _loading = false;
        _error = 'Please log in first.';
      });
      return;
    }

    try {
      // 2) Only the groups I am part of
      final res = await ApiService.getUserGroups(token)
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          _groups = data.cast<Map<String, dynamic>>();
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _error = 'Failed to load groups.';
        });
      }
    } on TimeoutException {
      if (mounted) setState(() { _loading = false; _error = 'Request timed out.'; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'Could not connect to server.'; });
    }
  }

  List<Map<String, dynamic>> get _filteredGroups {
    if (_query.isEmpty) return _groups;
    final q = _query.toLowerCase();
    return _groups.where((g) {
      final name = (g['name'] as String? ?? '').toLowerCase();
      final location = (g['meeting_point'] as String? ?? '').toLowerCase();
      final desc = (g['description'] as String? ?? '').toLowerCase();
      return name.contains(q) || location.contains(q) || desc.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Avatar placeholder
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.colorScheme.primary,
                    child: Icon(Icons.person, color: Colors.white, size: 18),
                  ),

                  // Title
                  Expanded(
                    child: Center(
                      child: Text(
                        'Travel Groups',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Refresh icon
                  IconButton(
                    onPressed: _fetchGroups,
                    icon: Icon(
                      Icons.refresh, 
                      color: _isCooldown 
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.2)
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            // ── Search & Filter ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                height: 44,
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search by name, location, or description...',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
                      fontSize: 13,
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
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                          )
                        : null,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Body ─────────────────────────────────────────────────────────
            Expanded(child: _buildBody(theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_outlined, size: 48,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchGroups,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _filteredGroups;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.group_off_outlined, size: 52,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Text(
              _query.isEmpty ? 'No travel groups yet.' : 'No groups match your search.',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45)),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _GroupCard(group: filtered[index], onRefresh: _fetchGroups);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  GROUP CARD
// ─────────────────────────────────────────────────────────────────────────────
class _GroupCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final VoidCallback onRefresh;

  const _GroupCard({required this.group, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final String groupId = group['id'] as String? ?? '';
    final String name = group['name'] as String? ?? 'Travel Group';
    final String location = group['meeting_point'] as String? ?? '';
    final String description = group['description'] as String? ?? '';
    final int memberCount = group['member_count'] as int? ?? 0;
    final int maxMembers = group['max_members'] as int? ?? 4;
    final bool isJoined = group['is_joined'] as bool? ?? false;
    final int spotsLeft = maxMembers - memberCount;

    // Departure date — format if present
    final dynamic rawDate = group['departure_date'];
    String dateStr = '';
    if (rawDate != null && rawDate is String) {
      try {
        final dt = DateTime.parse(rawDate);
        dateStr = '${_monthName(dt.month)} ${dt.day}, ${dt.year}';
      } catch (_) {
        dateStr = rawDate;
      }
    }

    return InkWell(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GroupDetailsScreen(groupId: groupId),
          ),
        );
        // Refresh list when returning from details (user may have joined)
        onRefresh();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isJoined)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, size: 12, color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Joined',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Location (meeting point)
            if (location.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      location,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Departure date
            if (dateStr.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    dateStr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ] else
              const SizedBox(height: 8),

            // Member count row
            Row(
              children: [
                Icon(Icons.group_outlined, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '$memberCount of $maxMembers members',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  spotsLeft > 0 ? '$spotsLeft spot${spotsLeft == 1 ? '' : 's'} left' : 'Full',
                  style: TextStyle(
                    color: spotsLeft > 0 ? theme.colorScheme.primary : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            // Description
            if (description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _monthName(int month) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month];
  }
}
