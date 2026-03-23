import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:college_hop/theme/app_scaffold.dart';
import 'package:college_hop/models/event_model.dart';
import 'package:college_hop/services/api_service.dart';
import 'package:college_hop/screen/event_detail_screen.dart';

class AllUpcomingEventsScreen extends StatefulWidget {
  const AllUpcomingEventsScreen({super.key});

  @override
  State<AllUpcomingEventsScreen> createState() =>
      _AllUpcomingEventsScreenState();
}

class _AllUpcomingEventsScreenState extends State<AllUpcomingEventsScreen> {
  String _selectedCategory = 'All Events';
  String _query = '';
  final TextEditingController _searchCtrl = TextEditingController();

  // Fetch state
  List<EventModel> _events = [];
  bool _loading = true;
  String? _error;

  // Cooldown — prevents spam refreshes (30 s)
  static const _cooldownSeconds = 30;
  DateTime? _lastFetchTime;
  Timer? _cooldownTimer;
  bool _isCoolingDown = false;

  final List<String> _categories = [
    'All Events',
    'Music Festival',
    'Sports',
    'Tech',
    'Culture',
    'Hackathon',
    'Conference',
  ];

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  // ── Data Fetching ─────────────────────────────────────────────────────────

  Future<void> _fetchEvents() async {
    // Enforce cooldown
    if (_isCoolingDown) return;

    setState(() {
      _loading = true;
      _error = null;
      _isCoolingDown = true;
    });

    _lastFetchTime = DateTime.now();
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(const Duration(seconds: _cooldownSeconds), () {
      if (mounted) setState(() => _isCoolingDown = false);
    });

    try {
      final response = await ApiService.getEvents();
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body) as List;
        final events = jsonList
            .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
            .where((e) => e.startDate.isAfter(DateTime.now()))
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
        _error = 'Could not connect to server. Please try again.';
        _loading = false;
      });
    }
  }

  // ── Filtering ─────────────────────────────────────────────────────────────

  List<EventModel> get _filteredEvents {
    return _events.where((e) {
      final matchQuery = _query.isEmpty ||
          e.name.toLowerCase().contains(_query.toLowerCase());
      final matchCat = _selectedCategory == 'All Events' ||
          e.category.toLowerCase() == _selectedCategory.toLowerCase();
      return matchQuery && matchCat;
    }).toList();
  }

  Map<String, List<EventModel>> get _groupedEvents {
    final Map<String, List<EventModel>> groups = {};
    for (final e in _filteredEvents) {
      groups.putIfAbsent(e.groupKey, () => []).add(e);
    }
    return groups;
  }

  // ── Category icon ─────────────────────────────────────────────────────────

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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAppBar(context, theme),
            _buildSearchBar(theme),
            _buildCategoryChips(theme),
            const SizedBox(height: 4),
            Expanded(child: _buildBody(theme)),
          ],
        ),
      ),
    );
  }

  // ── App Bar ───────────────────────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 16, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          ),
          Expanded(
            child: Text(
              'All Upcoming Events',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          // Refresh button — greyed out during cooldown
          IconButton(
            onPressed: _isCoolingDown ? null : _fetchEvents,
            tooltip: _isCoolingDown
                ? 'Please wait $_cooldownSeconds seconds between refreshes'
                : 'Refresh',
            icon: Icon(
              Icons.refresh,
              color: _isCoolingDown
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.2)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search Bar ────────────────────────────────────────────────────────────

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _query = v),
        decoration: InputDecoration(
          hintText: 'Search events...',
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            size: 20,
          ),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 18,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                )
              : null,
          filled: true,
          fillColor:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ── Category Chips ────────────────────────────────────────────────────────

  Widget _buildCategoryChips(ThemeData theme) {
    return SizedBox(
      height: 38,
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
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
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
          );
        },
      ),
    );
  }

  // ── Body (loading / error / list) ─────────────────────────────────────────

  Widget _buildBody(ThemeData theme) {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_outlined,
                  size: 48,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
      );
    }

    final groups = _groupedEvents;

    if (groups.isEmpty) {
      return Center(
        child: Text(
          'No events found',
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: theme.colorScheme.primary,
      onRefresh: _isCoolingDown
          ? () async {} // No-op during cooldown
          : _fetchEvents,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final key = groups.keys.elementAt(index);
          final events = groups[key]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMonthHeader(theme, key),
              ...events.map((e) => _buildEventTile(context, theme, e)),
            ],
          );
        },
      ),
    );
  }

  // ── Month Header ──────────────────────────────────────────────────────────

  Widget _buildMonthHeader(ThemeData theme, String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        label,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // ── Event Tile ────────────────────────────────────────────────────────────

  Widget _buildEventTile(
      BuildContext context, ThemeData theme, EventModel event) {
    final primary = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EventDetailScreen(event: event),
              ),
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                // ── Date Badge ─────────────────────────────────────────────
                Container(
                  width: 48,
                  height: 56,
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        event.monthAbbr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        event.dayStr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // ── Details ────────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category tag
                      if (event.category.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              _categoryIcon(event.category),
                              size: 12,
                              color: primary,
                            ),
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
                      const SizedBox(height: 3),

                      // Event name
                      Text(
                        event.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Venue (from real data)
                      if (event.venue.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.4),
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                event.venue,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.45),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 5),

                      // Days left
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_outlined,
                            size: 13,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.4),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            event.daysLeft,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.45),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Chevron ────────────────────────────────────────────────
                Icon(
                  Icons.chevron_right,
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.25),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
