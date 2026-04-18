import 'dart:async';
import 'dart:convert';
import 'package:college_hop/screen/new_event_submission.dart';
import 'package:college_hop/screen/notification_screen.dart';
import 'package:college_hop/screen/group_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:college_hop/providers/auth_provider.dart';
import 'package:college_hop/providers/event_provider.dart';
import 'package:college_hop/providers/profile_provider.dart';
import 'package:college_hop/services/api_service.dart';
import 'package:college_hop/theme/app_scaffold.dart';
import 'package:college_hop/screen/connect_profile_screen.dart';
import 'package:college_hop/widgets/select_event_sheet.dart';
import 'package:college_hop/widgets/custom_app_bar.dart';

class MyEvent extends StatefulWidget {
  const MyEvent({super.key});

  @override
  State<MyEvent> createState() => _MyEventState();
}

class _MyEventState extends State<MyEvent> {
  // ── State ──
  String? _currentEventId;
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _suggestedGroups = [];
  List<Map<String, dynamic>> _bestMatches = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = context.watch<EventProvider>().activeEvent;
    if (active != null && active.id != _currentEventId) {
      _currentEventId = active.id;
      _fetchDashboardData(active.id);
    }
  }

  Future<void> _fetchDashboardData(String eventId) async {
    if (_loading) return; // Prevent spamming
    
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
      // Fetch matches and groups in parallel with a timeout
      final results = await Future.wait([
        ApiService.getMatches(token, eventId),
        ApiService.getSuggestedGroups(token, eventId),
      ]).timeout(const Duration(seconds: 15));

      // Also fetch the user's groups into the provider to know membership
      context.read<ProfileProvider>().fetchGroups(token);

      final matchesRes = results[0];
      final groupsRes = results[1];

      if (!mounted) return;

      List<Map<String, dynamic>> matches = [];
      List<Map<String, dynamic>> groups = [];

      if (matchesRes.statusCode == 200) {
        final List<dynamic> matchList = jsonDecode(matchesRes.body);
        matches = matchList.cast<Map<String, dynamic>>();
      }

      if (groupsRes.statusCode == 200) {
        final List<dynamic> groupList = jsonDecode(groupsRes.body);
        groups = groupList.cast<Map<String, dynamic>>();
      }

      setState(() {
        _bestMatches = matches;
        _suggestedGroups = groups;
        _loading = false;
      });
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _error = 'Request timed out. Please try again.';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not connect to server.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = context.watch<EventProvider>().activeEvent;

    final eventName = active?.name ?? 'No event selected';
    final eventDate =
        active != null ? DateFormat('MMM d').format(active.startDate) : '';

    return AppScaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: "my_event_fab",
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const SubmitEventScreen(),
            ),
          );
        },
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: RefreshIndicator(
          color: theme.colorScheme.primary,
          onRefresh: () async {
            if (_currentEventId != null) {
              await _fetchDashboardData(_currentEventId!);
            }
          },
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverToBoxAdapter(child: _buildAppBar(theme)),
              // Event Card
              SliverToBoxAdapter(
                  child: _buildEventCard(theme, eventName, eventDate)),
              // Content
              ..._buildContent(theme),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
      ),
    );
  }

  List<Widget> _buildContent(ThemeData theme) {
    if (_loading) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child:
                CircularProgressIndicator(color: theme.colorScheme.primary),
          ),
        ),
      ];
    }

    if (_error != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off_outlined,
                      size: 48,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(_error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                      )),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_currentEventId != null) {
                        _fetchDashboardData(_currentEventId!);
                      }
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    return [
      // Suggested Travel Groups
      SliverToBoxAdapter(child: _buildTravelGroupsSection(theme)),
      // Best Matches Header
      SliverToBoxAdapter(child: _buildBestMatchesHeader(theme)),
      // Best Matches List
      if (_bestMatches.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Center(
              child: Text(
                'No matches found for this event yet.\nBe the first to join!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
        )
      else
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final active = context.read<EventProvider>().activeEvent;
              final evName = active?.name ?? '';
              final evDate = active != null ? DateFormat('MMM d').format(active.startDate) : '';
              return _buildMatchCard(theme, _bestMatches[index], evName, evDate);
            },
            childCount: _bestMatches.length,
          ),
        ),
    ];
  }

  // ==========  APP BAR  ==========
  Widget _buildAppBar(ThemeData theme) {
    return CustomAppBar(
      title: "Find Travel Buddies",
      actions: [
        if (_currentEventId != null)
          IconButton(
            onPressed: () => _fetchDashboardData(_currentEventId!),
            icon: Icon(
              Icons.refresh,
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
          ),
        Stack(
          children: [
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
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
    );
  }

  // ==========  SELECTED EVENT CARD  ==========
  Widget _buildEventCard(
      ThemeData theme, String eventName, String eventDate) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "SELECTED EVENT",
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    eventDate.isNotEmpty
                        ? "$eventName — $eventDate"
                        : eventName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => showSelectEventSheet(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Change",
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SubmitEventScreen(),
                  ),
                );
              },
              child: Row(
                children: [
                  Icon(
                    Icons.add,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Add new event",
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========  TRAVEL GROUPS  ==========
  Widget _buildTravelGroupsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "Suggested travel groups",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(
                Icons.auto_awesome,
                color: theme.colorScheme.primary,
                size: 22,
              ),
            ],
          ),
        ),
        if (_suggestedGroups.isEmpty)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Center(
              child: Text(
                'No suggested groups for this event yet.',
                style: TextStyle(
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 210,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _suggestedGroups.length,
              itemBuilder: (context, index) {
                return _buildGroupCard(theme, _suggestedGroups[index]);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildGroupCard(ThemeData theme, Map<String, dynamic> group) {
    final memberCount = group['member_count'] ?? 0;
    final maxMembers = group['max_members'] ?? 4;
    final matchScore = group['match_score'] ?? 0.0;
    final matchPercent = ((matchScore as num) * 100).round();
    final groupName = group['name'] ?? 'Travel Group';
    final interests =
        (group['interests'] as List<dynamic>?)?.cast<String>() ?? [];
    final groupId = group['id'] as String? ?? '';

    final userGroups = context.watch<ProfileProvider>().userGroups ?? [];
    final isMember = userGroups.any((g) => g['id'] == groupId);

    void openDetails() {
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (context) => GroupDetailsScreen(
                groupId: groupId,
                matchScore: (matchScore as num).toDouble(),
                sharedInterests: interests,
              ),
            ),
          )
          .then((_) {
        // Refresh dashboard when returning, in case user joined
        if (_currentEventId != null) {
          _fetchDashboardData(_currentEventId!);
        }
      });
    }

    return GestureDetector(
      onTap: openDetails,
      child: Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Students count + match %
          Row(
            children: [
              Icon(
                Icons.people_outline,
                size: 18,
                color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Text(
                "$memberCount/$maxMembers",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFF2A9D8F).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "$matchPercent% match",
                  style: const TextStyle(
                    color: Color(0xFF2A9D8F),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Group name
          Text(
            groupName,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Shared interests label
          Text(
            "SHARED INTERESTS",
            style: theme.textTheme.labelSmall?.copyWith(
              color:
                  theme.colorScheme.onSurface.withValues(alpha: 0.4),
              letterSpacing: 0.6,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 6),
          // Interest chips
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: interests.take(3).map((interest) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outline
                        .withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  interest,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
          const Spacer(),
          // Join/Message Group button
          SizedBox(
            width: double.infinity,
            height: 36,
            child: isMember
                ? ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Chat coming soon!')));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      foregroundColor: theme.colorScheme.onSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      "Message Group",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: openDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      "Join Group",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    ));
  }

  // ==========  BEST MATCHES  ==========
  Widget _buildBestMatchesHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(
        "Best matches for you",
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMatchCard(ThemeData theme, Map<String, dynamic> match, String eventName, String eventDate) {
    final name = match['full_name'] ?? 'Unknown';
    final college = match['college_name'] ?? '';
    final commonInterests =
        (match['common_interests'] as List<dynamic>?)?.cast<String>() ??
            [];
    final matchScore = match['match_score'] ?? 0.0;
    final matchPercent = ((matchScore as num) * 100).round();
    final profilePhoto = match['profile_photo_url'] as String?;

    // Generate a stable color from the name
    final hue = (name.hashCode % 360).abs().toDouble();
    final avatarColor = HSLColor.fromAHSL(1.0, hue, 0.6, 0.5).toColor();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
          builder: (context) => ConnectProfileScreen(matchData: {
                ...match,
                'event_name': eventName,
                'event_date': eventDate,
              }),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  theme.colorScheme.outline.withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: avatarColor.withValues(alpha: 0.15),
                backgroundImage: profilePhoto != null &&
                        profilePhoto.isNotEmpty
                    ? NetworkImage(profilePhoto)
                    : null,
                child: (profilePhoto == null || profilePhoto.isEmpty)
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: avatarColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (college.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        college,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Match % badge + common interests count
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A9D8F)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "$matchPercent% match",
                            style: const TextStyle(
                              color: Color(0xFF2A9D8F),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (commonInterests.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "${commonInterests.length} in common",
                              style: const TextStyle(
                                color: Color(0xFFE65100),
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Interest chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children:
                          commonInterests.take(4).map((interest) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.colorScheme.outline
                                  .withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            interest,
                            style:
                                theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.65),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              // Connect button
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                            ConnectProfileScreen(matchData: {
                              ...match,
                              'event_name': eventName,
                              'event_date': eventDate,
                            }),
                    ),
                  );
                },
                icon: Icon(
                  Icons.person_add_outlined,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
