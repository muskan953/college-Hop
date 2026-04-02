import 'package:flutter/material.dart';
import 'package:college_hop/theme/app_scaffold.dart';
import 'package:college_hop/screen/group_details_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  MOCK DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────
class _GroupModel {
  final String id;
  final String eventName;
  final bool isJoined;
  final String location;
  final String date;
  final String travelMethod;
  final int currentMembers;
  final int maxMembers;
  final String organizerName;
  final String description;
  final int spotsLeft;

  const _GroupModel({
    required this.id,
    required this.eventName,
    required this.isJoined,
    required this.location,
    required this.date,
    required this.travelMethod,
    required this.currentMembers,
    required this.maxMembers,
    required this.organizerName,
    required this.description,
    required this.spotsLeft,
  });
}

const _mockGroups = <_GroupModel>[
  _GroupModel(
    id: '1',
    eventName: 'Hackathon @ IIT Delhi',
    isJoined: true,
    location: 'San Francisco -> New Delhi, India',
    date: 'March 10, 2026',
    travelMethod: 'Flight',
    currentMembers: 3,
    maxMembers: 5,
    organizerName: 'Sarah Chen',
    description: 'Looking for fellow Bay Area students to travel together to IT Delhi hackathon!',
    spotsLeft: 2,
  ),
  _GroupModel(
    id: '2',
    eventName: 'AWS Summit',
    isJoined: true,
    location: 'Portland -> Seattle, WA',
    date: 'March 24, 2026',
    travelMethod: 'Train',
    currentMembers: 15,
    maxMembers: 15,
    organizerName: 'Nina Patel',
    description: 'Taking the train from Portland to Seattle for AWS Summit. Looking for travel buddies.',
    spotsLeft: 0,
  ),
];

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

  List<_GroupModel> get _filteredGroups {
    if (_query.isEmpty) return _mockGroups;
    return _mockGroups
        .where((g) => g.eventName.toLowerCase().contains(_query.toLowerCase()) || 
                      g.location.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
                  // Avatar
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.colorScheme.primary,
                    child: const Text('S', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

                  // Add icon
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.add, color: theme.colorScheme.onSurface),
                  ),
                ],
              ),
            ),

            // ── Search & Filter ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _query = v),
                        decoration: InputDecoration(
                          hintText: 'Search by event, city, or location...',
                          hintStyle: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
                            fontSize: 13,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
                            size: 20,
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceVariant.withValues(alpha: 0.45),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.filter_list, color: theme.colorScheme.onSurface, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── List ─────────────────────────────────────────────────────────
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _filteredGroups.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return _GroupCard(group: _filteredGroups[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  GROUP CARD
// ─────────────────────────────────────────────────────────────────────────────
class _GroupCard extends StatelessWidget {
  final _GroupModel group;

  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GroupDetailsScreen(groupId: group.id),
          ),
        );
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
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    group.eventName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (group.isJoined)
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

            // Location
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group.location,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Date & Travel Method
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${group.date} • ${group.travelMethod}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Members
            Row(
              children: [
                // Overlapping Avatars
                SizedBox(
                  width: 60,
                  height: 32,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.blue.shade100,
                          child: const Text('S', style: TextStyle(fontSize: 12, color: Colors.blue)),
                        ),
                      ),
                      if (group.currentMembers > 1)
                        Positioned(
                          left: 14,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.colorScheme.surface, width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.pink.shade100,
                              child: const Text('M', style: TextStyle(fontSize: 10, color: Colors.pink)),
                            ),
                          ),
                        ),
                      if (group.currentMembers > 2)
                        Positioned(
                          left: 28,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.colorScheme.surface, width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: theme.colorScheme.surfaceVariant,
                              child: Text('+${group.currentMembers - 2}', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Organized By Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${group.currentMembers} of ${group.maxMembers} members',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Organized by ${group.organizerName}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              group.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // Spots left
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${group.spotsLeft} spots left',
                style: TextStyle(
                  color: group.spotsLeft > 0 ? Colors.blue : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
