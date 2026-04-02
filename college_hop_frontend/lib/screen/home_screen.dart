import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:college_hop/theme/app_scaffold.dart';
import 'package:college_hop/models/event_model.dart';
import 'package:college_hop/services/api_service.dart';
import 'package:college_hop/providers/profile_provider.dart';
import 'package:college_hop/screen/notification_screen.dart';
import 'package:college_hop/screen/new_event_submission.dart';
import 'package:college_hop/screen/all_upcoming_events.dart';
import 'package:college_hop/screen/event_detail_screen.dart';
import 'package:college_hop/widgets/select_event_sheet.dart';

class DefaultMainScreen extends StatefulWidget {
  const DefaultMainScreen({super.key});

  @override
  State<DefaultMainScreen> createState() => _DefaultMainScreenState();
}

class _DefaultMainScreenState extends State<DefaultMainScreen> {
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Music Festival',
    'Sports',
    'Tech',
    'Culture',
    'Hackathon',
  ];

  // ── Fetch state ──
  List<EventModel> _events = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await ApiService.getEvents();
      if (response.statusCode == 200) {
        final now = DateTime.now();
        final twoMonthsLater = now.add(const Duration(days: 60));
        final List<dynamic> jsonList = jsonDecode(response.body) as List;
        final events = jsonList
            .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
            .where((e) =>
                e.startDate.isAfter(now) &&
                e.startDate.isBefore(twoMonthsLater))
            .toList()
          ..sort((a, b) => a.startDate.compareTo(b.startDate));
        setState(() {
          _events = events;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load events (${response.statusCode})';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Could not connect to server.';
        _loading = false;
      });
    }
  }

  // ── Filtering (category chips only) ──
  List<EventModel> get _filteredEvents {
    return _events.where((e) {
      return _selectedCategory == 'All' ||
          e.category.toLowerCase() == _selectedCategory.toLowerCase();
    }).toList();
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'hackathon':
        return Icons.code;
      case 'conference':
        return Icons.mic_external_on_outlined;
      case 'sports':
        return Icons.sports_basketball;
      case 'music festival':
        return Icons.music_note;
      case 'culture':
        return Icons.palette_outlined;
      case 'tech':
        return Icons.memory_outlined;
      default:
        return Icons.event_outlined;
    }
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      body: RefreshIndicator(
        color: theme.colorScheme.primary,
        onRefresh: _fetchEvents,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(theme)),
            SliverToBoxAdapter(child: _buildHeroSection(theme)),
            SliverToBoxAdapter(
                child: _buildSectionHeader(theme, "Upcoming Events", "View All")),
            SliverToBoxAdapter(child: _buildCategoryChips(theme)),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            _buildEventListSliver(theme),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  // ── Header ──

  Widget _buildHeader(ThemeData theme) {
    final profileData = context.watch<ProfileProvider>().profileData;
    final initial = (profileData != null && profileData['name'] != null &&
            (profileData['name'] as String).isNotEmpty)
        ? (profileData['name'] as String)[0].toUpperCase()
        : 'U';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Text(
            "Find Travel Buddies",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
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
      ),
    );
  }

  // ── Hero Section ──

  Widget _buildHeroSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              "Select an event to find travel buddies",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => showSelectEventSheet(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Select event",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SubmitEventScreen(),
                  ),
                );
              },
              child: Text(
                "+ Add new event",
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section Header ──

  Widget _buildSectionHeader(
      ThemeData theme, String title, String actionText) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AllUpcomingEventsScreen(),
                ),
              );
            },
            child: Text(
              actionText,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Category Chips (no search bar) ──

  Widget _buildCategoryChips(ThemeData theme) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final selected = cat == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  cat,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Event List Sliver ──

  Widget _buildEventListSliver(ThemeData theme) {
    if (_loading) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child:
              CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }

    if (_error != null) {
      return SliverFillRemaining(
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
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _fetchEvents,
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
      );
    }

    final events = _filteredEvents;

    if (events.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(
            'No upcoming events in the next 2 months',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildEventTile(theme, events[index]),
          childCount: events.length,
        ),
      ),
    );
  }

  // ── Event Tile ──

  Widget _buildEventTile(ThemeData theme, EventModel event) {
    final primary = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EventDetailScreen(event: event),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color:
                      theme.colorScheme.outline.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Date Column
                Container(
                  width: 50,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        event.monthAbbr,
                        style: TextStyle(
                          color: primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        event.dayStr,
                        style: TextStyle(
                          color: primary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Event Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (event.category.isNotEmpty)
                        Row(
                          children: [
                            Icon(_categoryIcon(event.category),
                                size: 12, color: primary),
                            const SizedBox(width: 4),
                            Text(
                              event.category.toUpperCase(),
                              style: TextStyle(
                                color: primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),
                      Text(
                        event.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.people_outline,
                              size: 14,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.4)),
                          const SizedBox(width: 4),
                          Text(
                            "${event.attendees > 0 ? '${event.attendees} going' : 'Be the first!'} · ${event.daysLeft}",
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Arrow
                Icon(Icons.chevron_right,
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
