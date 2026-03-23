import 'package:flutter/material.dart';

class GroupDetailsScreen extends StatelessWidget {
  final String groupName;

  const GroupDetailsScreen({super.key, required this.groupName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Group Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
       
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // ── Header ─────────────────────────────────────────────────
                Text(
                  groupName,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                    const SizedBox(width: 4),
                    Text(
                      'New Delhi, India',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                    const SizedBox(width: 4),
                    Text(
                      'March 12-14, 2026',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.check, size: 16, color: primary),
                      label: const Text("You're in this group"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primary,
                        side: BorderSide(color: primary.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '2 spots left',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                Divider(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                const SizedBox(height: 24),

                // ── Travel Details ─────────────────────────────────────────
                Text('Travel Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildTravelDetailItem(theme, Icons.flight_takeoff, 'Departing From', 'San Francisco'),
                _buildTravelDetailItem(theme, Icons.calendar_today, 'Departure Date', 'March 10, 2026'),
                _buildTravelDetailItem(theme, Icons.event, 'Return Date', 'March 15, 2026'),
                _buildTravelDetailItem(theme, Icons.flight, 'Travel Method', 'Flight'),

                const SizedBox(height: 24),
                Divider(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                const SizedBox(height: 24),

                // ── About This Group ───────────────────────────────────────
                Text('About This Group', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(
                  'Looking for fellow Bay Area students to travel together to IT Delhi hackathon! Planning to share accommodation and explore Delhi.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 24),
                Divider(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                const SizedBox(height: 24),

                // ── Organizer ──────────────────────────────────────────────
                Text('Organizer', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildMemberTile(theme, 'S', 'Sarah Chen', true, 'Stanford University', Colors.blue.shade100, Colors.blue),

                const SizedBox(height: 24),
                Divider(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                const SizedBox(height: 24),

                // ── Members ────────────────────────────────────────────────
                Text('Members (3/5)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildMemberTile(theme, 'S', 'Sarah Chen', true, 'Stanford University', Colors.blue.shade100, Colors.blue, showChat: true),
                _buildMemberTile(theme, 'S', 'Sarah Chen', true, 'Stanford University', Colors.blue.shade100, Colors.blue, showChat: true),
                _buildMemberTile(theme, 'M', 'Michael Kim', true, 'UC Berkeley', Colors.pink.shade100, Colors.pink, showChat: true),
              ],
            ),
          ),

          // ── Bottom CTA ───────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), offset: const Offset(0, -4), blurRadius: 10),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chat_bubble_outline, size: 20),
                  label: const Text('Group Chat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTravelDetailItem(ThemeData theme, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMemberTile(ThemeData theme, String initial, String name, bool isVerified, String uni, Color bg, Color fg, {bool showChat = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: bg,
            child: Text(initial, style: TextStyle(color: fg, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (isVerified) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.verified, size: 14, color: theme.colorScheme.primary),
                    ]
                  ],
                ),
                Text(uni, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
              ],
            ),
          ),
          if (showChat)
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.chat_bubble_outline, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
            )
        ],
      ),
    );
  }
}
