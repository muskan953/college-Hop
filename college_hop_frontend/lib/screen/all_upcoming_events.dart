import 'package:flutter/material.dart';
import 'package:college_hop/theme/app_scaffold.dart';

class AllUpcomingEventsScreen extends StatefulWidget {
  const AllUpcomingEventsScreen({super.key});

  @override
  State<AllUpcomingEventsScreen> createState() => _AllUpcomingEventsScreenState();
}

class _AllUpcomingEventsScreenState extends State<AllUpcomingEventsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  final List<Map<String, dynamic>> _allEvents = [
    // March 2026
    {'name': 'Hackathon @ IIT Delhi', 'month': 'MAR', 'day': '12', 'year': '2026', 'category': 'Tech', 'attendees': '2k+ going', 'days_left': '2 days left'},
    {'name': 'TechCrunch Disrupt', 'month': 'MAR', 'day': '20', 'year': '2026', 'category': 'Tech', 'attendees': '5k+ going', 'days_left': '10 days left'},
    // April 2026
    {'name': 'NCAA Finals @ Miami', 'month': 'APR', 'day': '08', 'year': '2026', 'category': 'Sports', 'attendees': '20k+ going', 'days_left': '29 days left'},
    {'name': 'Coachella Music Festival', 'month': 'APR', 'day': '15', 'year': '2026', 'category': 'Music Festival', 'attendees': '100k+ going', 'days_left': '36 days left'},
    {'name': 'Google I/O Conference', 'month': 'APR', 'day': '18', 'year': '2026', 'category': 'Tech', 'attendees': '15k+ going', 'days_left': '39 days left'},
    {'name': 'Boston Marathon', 'month': 'APR', 'day': '21', 'year': '2026', 'category': 'Sports', 'attendees': '30k+ going', 'days_left': '42 days left'},
    {'name': 'South by Southwest', 'month': 'APR', 'day': '28', 'year': '2026', 'category': 'Music Festival', 'attendees': '80k+ going', 'days_left': '49 days left'},
    // May 2026
    {'name': 'MLH Hackathon @ Stanford', 'month': 'MAY', 'day': '02', 'year': '2026', 'category': 'Tech', 'attendees': '3k+ going', 'days_left': '53 days left'},
    {'name': 'NBA Finals Game', 'month': 'MAY', 'day': '10', 'year': '2026', 'category': 'Sports', 'attendees': '18k+ going', 'days_left': '61 days left'},
    {'name': 'Startup Grind Global', 'month': 'MAY', 'day': '15', 'year': '2026', 'category': 'Tech', 'attendees': '4k+ going', 'days_left': '66 days left'},
    {'name': 'Ultra Music Festival', 'month': 'MAY', 'day': '25', 'year': '2026', 'category': 'Music Festival', 'attendees': '150k+ going', 'days_left': '76 days left'},
  ];

  Map<String, List<Map<String, dynamic>>> get _groupedEvents {
    final filtered = _allEvents.where((e) =>
        e['name']!.toLowerCase().contains(_query.toLowerCase())).toList();
    
    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (var e in filtered) {
      final month = _getMonthFull(e['month']);
      final key = "$month ${e['year']}";
      if (!groups.containsKey(key)) groups[key] = [];
      groups[key]!.add(e);
    }
    return groups;
  }

  String _getMonthFull(String short) {
    switch (short) {
      case 'MAR': return 'March';
      case 'APR': return 'April';
      case 'MAY': return 'May';
      case 'JUN': return 'June';
      default: return short;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups = _groupedEvents;

    return AppScaffold(
      body: Column(
        children: [
          // ── App Bar ──────────────────────────────────────────────────────
          _buildAppBar(context, theme),
          
          // ── Search Bar ───────────────────────────────────────────────────
          _buildSearchBar(theme),
          
          // ── Grouped List ─────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final key = groups.keys.elementAt(index);
                final events = groups[key]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        key,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ),
                    ...events.map((e) => _buildEventTile(theme, e)).toList(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            color: theme.colorScheme.onSurface,
          ),
          const Expanded(
            child: Text(
              'All Upcoming Events',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 48), // Balancing back button
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _query = v),
        decoration: InputDecoration(
          hintText: 'Search events...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: const Icon(Icons.tune, size: 20),
          filled: true,
          fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.4),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildEventTile(ThemeData theme, Map<String, dynamic> event) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    event['month'],
                    style: TextStyle(color: theme.colorScheme.primary, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    event['day'],
                    style: TextStyle(color: theme.colorScheme.primary, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['category'].toUpperCase(),
                    style: TextStyle(color: theme.colorScheme.primary, fontSize: 9, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event['name'],
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.people_outline, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                      const SizedBox(width: 4),
                      Text(
                        "${event['attendees']} • ${event['days_left']}",
                        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.4)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withOpacity(0.2)),
          ],
        ),
      ),
    );
  }
}
