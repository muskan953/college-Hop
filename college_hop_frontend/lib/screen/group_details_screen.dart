import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:college_hop/providers/auth_provider.dart';
import 'package:college_hop/providers/profile_provider.dart';
import 'package:college_hop/services/api_service.dart';

class GroupDetailsScreen extends StatefulWidget {
  final String groupId;
  final double? matchScore; // passed from the dashboard card
  final List<String> sharedInterests;

  const GroupDetailsScreen({
    super.key,
    required this.groupId,
    this.matchScore,
    this.sharedInterests = const [],
  });

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  bool _loading = true;
  bool _isJoining = false;
  String? _error;
  Map<String, dynamic>? _groupData;

  @override
  void initState() {
    super.initState();
    _fetchGroupDetails();
  }

  Future<void> _fetchGroupDetails() async {
    setState(() {
      _loading = true;
      _error = null;
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
      final res = await ApiService.getGroupDetails(token, widget.groupId)
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (res.statusCode == 200) {
        setState(() {
          _groupData = jsonDecode(res.body) as Map<String, dynamic>;
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _error = 'Failed to load group details.';
        });
      }
    } on TimeoutException {
      if (mounted) setState(() { _loading = false; _error = 'Request timed out.'; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'Could not connect to server.'; });
    }
  }

  Future<void> _joinGroup() async {
    if (_isJoining) return;
    setState(() => _isJoining = true);

    final token = context.read<AuthProvider>().accessToken;
    if (token == null) {
      setState(() => _isJoining = false);
      return;
    }

    try {
      final res = await ApiService.joinGroup(token, widget.groupId)
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);

      if (res.statusCode == 200) {
        setState(() { _isJoining = false; });
        await _showSuccessOverlay();
        await _fetchGroupDetails();
      } else {
        setState(() => _isJoining = false);
        final msg = res.body.trim().isNotEmpty ? res.body.trim() : 'Could not join group.';
        messenger.showSnackBar(SnackBar(content: Text(msg)));
      }
    } on TimeoutException {
      if (mounted) {
        setState(() => _isJoining = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request timed out.')));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isJoining = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not connect to server.')));
      }
    }
  }

  Future<void> _showSuccessOverlay() async {
    if (!mounted) return;
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, __) {
        return FadeTransition(
          opacity: anim,
          child: Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 24)],
              ),
              child: const Icon(Icons.check_rounded, color: Color(0xFF2ECC71), size: 42),
            ),
          ),
        );
      },
    );
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Travel Group',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        elevation: 0.5,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : _error != null
              ? _buildError(theme)
              : _buildBody(theme),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_outlined, size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchGroupDetails,
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

  Widget _buildBody(ThemeData theme) {
    final data = _groupData!;
    final groupName = data['name'] as String? ?? 'Travel Group';
    final description = data['description'] as String? ?? '';
    final memberCount = data['member_count'] as int? ?? 0;
    final maxMembers = data['max_members'] as int? ?? 4;
    final members = (data['members'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    final interests = widget.sharedInterests.isNotEmpty 
        ? widget.sharedInterests 
        : ((data['interests'] as List<dynamic>?)?.cast<String>() ?? []);
    final departureDate = data['departure_date'] as String?;
    final meetingPoint = data['meeting_point'] as String?;

    // Determine match %
    final matchScore = widget.matchScore ?? 0.0;
    final matchPercent = (matchScore * 100).round();

    // Determine current user — backend tells us authoritatively
    final myUserId = data['current_user_id'] as String?;
    final isMember = members.any((m) => m['user_id'] == myUserId);

    // Hoist current user to the top of the list
    members.sort((a, b) {
      if (a['user_id'] == myUserId) return -1;
      if (b['user_id'] == myUserId) return 1;
      return 0;
    });

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // ── Avatar + match badge ──────────────────────────────────────
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                      child: Icon(Icons.people_outline,
                          size: 40, color: theme.colorScheme.primary),
                    ),
                    if (matchPercent > 0)
                      Positioned(
                        bottom: -10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A9D8F),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$matchPercent% Match',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Group name & student count ────────────────────────────────
              Text(
                groupName,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                '$memberCount student${memberCount == 1 ? '' : 's'} in this group',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),
              Divider(color: theme.colorScheme.outline.withValues(alpha: 0.12)),
              const SizedBox(height: 20),

              // ── About ─────────────────────────────────────────────────────
              if (description.isNotEmpty) ...[
                Text('About This Group',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 20),
                Divider(color: theme.colorScheme.outline.withValues(alpha: 0.12)),
                const SizedBox(height: 20),
              ],

              // ── Travel Details ─────────────────────────────────────────────
              if (departureDate != null || meetingPoint != null) ...[
                Text('Travel Details',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (departureDate != null)
                  _buildTravelItem(theme, Icons.calendar_today_outlined, _formatDate(departureDate), 'Departure Date'),
                if (meetingPoint != null && meetingPoint.isNotEmpty)
                  _buildTravelItem(theme, Icons.location_on_outlined, meetingPoint, 'Meeting Point'),
                const SizedBox(height: 4),
                Divider(color: theme.colorScheme.outline.withValues(alpha: 0.12)),
                const SizedBox(height: 20),
              ],

              // ── Shared Interests ───────────────────────────────────────────
              if (interests.isNotEmpty) ...[
                Text('Shared Interests',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: interests.map((i) => _buildInterestChip(theme, i)).toList(),
                ),
                const SizedBox(height: 20),
                Divider(color: theme.colorScheme.outline.withValues(alpha: 0.12)),
                const SizedBox(height: 20),
              ],

              // ── Members ────────────────────────────────────────────────────
              Text('Members ($memberCount)',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...members.map((m) => _buildMemberTile(theme, m, myUserId)),
            ],
          ),
        ),

        // ── Bottom CTA ──────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  offset: const Offset(0, -4),
                  blurRadius: 12)
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: isMember
                  ? ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Navigate to chat screen when implemented
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Chat coming soon!')));
                      },
                      icon: const Icon(Icons.chat_bubble_outline, size: 20),
                      label: const Text(
                        'Message Group',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        foregroundColor: theme.colorScheme.onSurface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: _isJoining ? null : _joinGroup,
                      icon: _isJoining
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.group_add_outlined, size: 20),
                      label: Text(
                        _isJoining ? 'Joining...' : 'Join Group',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: theme.colorScheme.primary.withValues(alpha: 0.6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildTravelItem(ThemeData theme, IconData icon, String value, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 17, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(label,
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInterestChip(ThemeData theme, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 13, color: theme.colorScheme.primary),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              )),
        ],
      ),
    );
  }

  Widget _buildMemberTile(ThemeData theme, Map<String, dynamic> member,
      String? myUserId) {
    final name = member['full_name'] as String? ?? 'Unknown';
    final college = member['college_name'] as String? ?? '';
    final isMe = member['user_id'] == myUserId;
    final displayName = isMe ? '$name (You)' : name;

    final hue = (name.hashCode % 360).abs().toDouble();
    final avatarColor = HSLColor.fromAHSL(1.0, hue, 0.55, 0.45).toColor();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: avatarColor.withValues(alpha: 0.18),
              child: Text(
                initial,
                style: TextStyle(
                  color: avatarColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold)),
                  if (college.isNotEmpty)
                    Text(college,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.55))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('MMMM d, yyyy').format(dt);
    } catch (_) {
      return iso;
    }
  }
}
