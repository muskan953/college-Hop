import 'package:college_hop/screen/new_event_submission.dart';
import 'package:college_hop/screen/notification_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:college_hop/providers/auth_provider.dart';
import 'package:college_hop/providers/event_provider.dart';
import 'package:college_hop/theme/app_scaffold.dart';
import 'package:college_hop/screen/welcome_screen.dart';
import 'package:college_hop/screen/connect_profile_screen.dart';


class MyEvent extends StatefulWidget {
  const MyEvent({super.key});

  @override
  State<MyEvent> createState() => _MyEventState();
}

class _MyEventState extends State<MyEvent> {
  int _currentIndex = 0;
 
  // Mock data
  late String _selectedEvent;
  late String _selectedEventDate;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = context.read<EventProvider>().activeEvent;
    if (active != null) {
      _selectedEvent = active.name;
      _selectedEventDate = DateFormat('MMM d').format(active.startDate);
    } else {
      _selectedEvent = 'No event selected';
      _selectedEventDate = '';
    }
  }

  final List<Map<String, dynamic>> _travelGroups = [
    {
      "students": 3,
      "match": 92,
      "event": "Hackathon @ IIT Delhi",
      "interests": ["AI", "Startups", "Python"],
    },
    {
      "students": 4,
      "match": 85,
      "event": "Hackathon @ IIT Bombay",
      "interests": ["Machine Learning", "Web Dev"],
    },
    {
      "students": 2,
      "match": 78,
      "event": "TechFest @ NIT Trichy",
      "interests": ["DSA", "Cloud", "DevOps"],
    },
  ];

  final List<Map<String, dynamic>> _bestMatches = [
    {
      "name": "Priya Sharma",
      "college": "MIT",
      "commonInterests": 2,
      "interests": ["AI", "Startups"],
      "color": Colors.blue,
    },
    {
      "name": "Rahul Patel",
      "college": "Stanford",
      "commonInterests": 2,
      "interests": ["Python", "Machine Learning"],
      "color": Colors.red,
    },
    {
      "name": "Ananya Singh",
      "college": "Berkeley",
      "commonInterests": 1,
      "interests": ["Startups"],
      "color": Colors.amber,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: "my_event_fab",
        onPressed: () {
          print("FAB Clicked!");
           Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const SubmitEventScreen(),
                                ),
                              );
        },
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverToBoxAdapter(child: _buildAppBar(theme)),
            // Event Card
            SliverToBoxAdapter(child: _buildEventCard(theme)),
            // Suggested Travel Groups
            SliverToBoxAdapter(child: _buildTravelGroupsSection(theme)),
            // Best Matches
            SliverToBoxAdapter(child: _buildBestMatchesHeader(theme)),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildMatchCard(theme, _bestMatches[index]),
                childCount: _bestMatches.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  // ==========  APP BAR  ==========
  Widget _buildAppBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.primary,
            child: const Text(
              "S",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Title
          Expanded(
            child: Text(
              "Find Travel Buddies",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          // Notification bell
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

  // ==========  SELECTED EVENT CARD  ==========
  Widget _buildEventCard(ThemeData theme) {
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
            // Label
            Text(
              "SELECTED EVENT",
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            // Event name + Change button
            Row(
              children: [
                Expanded(
                  child: Text(
                    "$_selectedEvent — $_selectedEventDate",
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _showSelectEventSheet(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
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
            // Add new event
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
        // Section header
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
        // Horizontal scrollable cards
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _travelGroups.length,
            itemBuilder: (context, index) {
              return _buildGroupCard(theme, _travelGroups[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGroupCard(ThemeData theme, Map<String, dynamic> group) {
    return Container(
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
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Text(
                "${group['students']} students",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A9D8F).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${group['match']}% match",
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
          // Event name
          Text(
            group['event'],
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
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              letterSpacing: 0.6,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 6),
          // Interest chips
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: (group['interests'] as List<String>).map((interest) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.25),
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
          // Join Group button
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton(
              onPressed: () {
                
              },
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
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
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

  Widget _buildMatchCard(ThemeData theme, Map<String, dynamic> match) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (match['name'] == 'Priya Sharma') {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ConnectProfileScreen(),
              ),
            );
          }
        },
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: (match['color'] as Color).withValues(alpha: 0.15),
              child: Text(
                match['name'].substring(0, 1),
                style: TextStyle(
                  color: match['color'],
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    match['name'],
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    match['college'],
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Common interests badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${match['commonInterests']} interests in common",
                      style: const TextStyle(
                        color: Color(0xFFE65100),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Interest chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: (match['interests'] as List<String>).map((interest) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.outline.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          interest,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
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
                if (match['name'] == 'Priya Sharma') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ConnectProfileScreen(),
                    ),
                  );
                }
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
    ),);
  }
  // ==========  SELECT EVENT BOTTOM SHEET  ==========
  void _showSelectEventSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SelectEventSheet(
        onEventSelected: (name, date) {
          setState(() {
            _selectedEvent = name;
            _selectedEventDate = date;
          });
        },
      ),
    );
  }
}

// ============================================================
//  SELECT EVENT SHEET  (separate StatefulWidget)
// ============================================================
class _SelectEventSheet extends StatefulWidget {
  final void Function(String name, String date) onEventSelected;
  const _SelectEventSheet({required this.onEventSelected});

  @override
  State<_SelectEventSheet> createState() => _SelectEventSheetState();
}

class _SelectEventSheetState extends State<_SelectEventSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedDate = 'Any Time';
  String _query = '';

  final List<String> _categories = [
    'All', 'Music Festival', 'Sports', 'Tech', 'Culture',
  ];

  final List<String> _dateFilters = [
    'Any Time', 'This Week', 'This Month', 'Next Month',
  ];

  final List<Map<String, String>> _allEvents = [
    {'name': 'Hackathon @ IIT Delhi', 'date': 'March 12', 'category': 'Tech'},
    {'name': 'TechCrunch Disrupt', 'date': 'March 20', 'category': 'Tech'},
    {'name': 'Coachella Music Festival', 'date': 'April 15', 'category': 'Music Festival'},
    {'name': 'NCAA Finals @ Miami', 'date': 'April 8', 'category': 'Sports'},
    {'name': 'Cultural Fest @ JNU', 'date': 'April 22', 'category': 'Culture'},
    {'name': 'Hackathon @ IIT Bombay', 'date': 'May 3', 'category': 'Tech'},
    {'name': 'Open Mic Night', 'date': 'March 30', 'category': 'Music Festival'},
  ];

  List<Map<String, String>> get _filtered {
    return _allEvents.where((e) {
      final matchQuery = _query.isEmpty ||
          e['name']!.toLowerCase().contains(_query.toLowerCase());
      final matchCat = _selectedCategory == 'All' || e['category'] == _selectedCategory;
      return matchQuery && matchCat;
    }).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);

    return Container(
      height: mq.size.height * 0.82,
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------- drag handle ----------
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // ---------- header ----------
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
            child: Row(
              children: [
                Text(
                  'Select Event',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          // ---------- search bar ----------
          Padding(
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
                suffixIcon: Icon(
                  Icons.tune,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  size: 20,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withValues(alpha: 0.5),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // ---------- CATEGORY label ----------
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
            child: Text(
              'CATEGORY',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          // ---------- category chips ----------
          SizedBox(
            height: 36,
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceVariant.withValues(alpha: 0.5),
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
          ),
          const SizedBox(height: 12),
          // ---------- DATE label ----------
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Text(
              'DATE',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          // ---------- date chips ----------
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _dateFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final d = _dateFilters[i];
                final selected = d == _selectedDate;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = d),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceVariant.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      d,
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
          ),
          const SizedBox(height: 14),
          // ---------- event list ----------
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text(
                      'No events found',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: theme.colorScheme.outline.withValues(alpha: 0.1),
                    ),
                    itemBuilder: (_, i) {
                      final event = _filtered[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 6),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.event_outlined,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          event['name']!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          event['date']!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        onTap: () {
                          widget.onEventSelected(
                              event['name']!, event['date']!);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

