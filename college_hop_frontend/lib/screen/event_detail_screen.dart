import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:college_hop/models/event_model.dart';
import 'package:college_hop/services/api_service.dart';
import 'package:college_hop/providers/auth_provider.dart';
import 'package:college_hop/providers/event_provider.dart';
import 'package:college_hop/providers/profile_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class EventDetailScreen extends StatefulWidget {
  final EventModel event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  /// Tracks which CTA is currently in-flight (null = idle).
  String? _submittingStatus;

  EventModel get event => widget.event;

  Future<void> _handleCTA(String status) async {
    if (_submittingStatus != null) return;
    setState(() => _submittingStatus = status);

    final authProvider = context.read<AuthProvider>();
    var token = authProvider.accessToken;

    if (token == null) {
      setState(() => _submittingStatus = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in first.')),
        );
      }
      return;
    }

    try {
      var res = await ApiService.setUserEvent(token, event.id, status);

      // If the access token expired, refresh it and retry once
      if (res.statusCode == 401) {
        final refreshed = await authProvider.tryRefresh();
        if (refreshed && authProvider.accessToken != null) {
          token = authProvider.accessToken!;
          res = await ApiService.setUserEvent(token, event.id, status);
        }
      }

      if (!mounted) return;

      if (res.statusCode == 200 || res.statusCode == 201) {
        context.read<EventProvider>().setActiveEvent(event);
        context.read<ProfileProvider>().fetchEvents(token!);
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to register (${res.statusCode})')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submittingStatus = null);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String get _formattedDate =>
      DateFormat('EEEE, MMMM d, yyyy').format(event.startDate);

  String get _daysAwayLabel {
    final diff = event.startDate.difference(DateTime.now()).inDays;
    if (diff < 0) return 'Past event';
    if (diff == 0) return 'Today!';
    return '$diff days away';
  }

  bool get _isPast =>
      event.startDate.isBefore(DateTime.now());

  /// Returns a short display-friendly time string.
  String get _timeDisplay {
    if (event.timeDescription.isNotEmpty) return event.timeDescription;
    return DateFormat('h:mm a').format(event.startDate);
  }

  IconData _categoryIcon(String cat) {
    switch (cat.toLowerCase()) {
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

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    
    try {
      // By omitting the 'mode', url_launcher falls back to the best default
      // for the platform. On Web, this safely opens a new tab.
      final success = await launchUrl(uri);
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the link.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Gradient Header ───────────────────────────────────────────
              SliverToBoxAdapter(child: _buildHeader(context, theme)),

              // ── Body content ──────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Category chip
                    if (event.category.isNotEmpty) _buildCategoryChip(theme),
                    const SizedBox(height: 12),

                    // Event name
                    Text(
                      event.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Date + days-away row
                    _buildDateRow(theme),
                    const SizedBox(height: 20),

                    // Info grid
                    _buildInfoGrid(theme),
                    const SizedBox(height: 24),

                    // About
                    _buildSection(
                      theme,
                      title: 'About this event',
                      child: _buildAbout(theme),
                    ),
                    const SizedBox(height: 20),

                    // Highlights
                    _buildSection(
                      theme,
                      title: 'Event Highlights',
                      child: _buildHighlights(theme),
                    ),
                    const SizedBox(height: 20),

                    // Location
                    _buildSection(
                      theme,
                      title: 'Location',
                      child: _buildLocation(context, theme),
                    ),
                  ]),
                ),
              ),
            ],
          ),

          // ── Sticky Bottom CTA ─────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomCTA(context, theme),
          ),
        ],
      ),
    );
  }

  // ── Gradient Header ───────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      height: 200,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFE83E4D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Material(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(50),
              child: InkWell(
                borderRadius: BorderRadius.circular(50),
                onTap: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.arrow_back, color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Category Chip ─────────────────────────────────────────────────────────

  Widget _buildCategoryChip(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_categoryIcon(event.category),
              size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
          const SizedBox(width: 6),
          Text(
            event.category,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ── Date Row ──────────────────────────────────────────────────────────────

  Widget _buildDateRow(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Date pill (blue)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _formattedDate,
            style: const TextStyle(
              color: Color(0xFF3B82F6),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),

        // Days-away pill (orange / grey for past)
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _isPast
                ? Colors.grey.withValues(alpha: 0.12)
                : const Color(0xFFF97316).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _daysAwayLabel,
            style: TextStyle(
              color: _isPast ? Colors.grey : const Color(0xFFF97316),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  // ── Info Grid ─────────────────────────────────────────────────────────────

  Widget _buildInfoGrid(ThemeData theme) {
    final items = [
      _InfoItem(
        icon: Icons.location_on_outlined,
        iconColor: const Color(0xFF3B82F6),
        label: 'LOCATION',
        value: event.venue.isNotEmpty ? event.venue : '—',
      ),
      _InfoItem(
        icon: Icons.people_outline,
        iconColor: const Color(0xFF10B981),
        label: 'ATTENDING',
        value: event.attendees > 0 ? '${event.attendees}' : '—',
      ),
      _InfoItem(
        icon: Icons.access_time_outlined,
        iconColor: const Color(0xFFF97316),
        label: 'TIME',
        value: _timeDisplay,
      ),
      _InfoItem(
        icon: Icons.local_offer_outlined,
        iconColor: const Color(0xFF8B5CF6),
        label: 'PRICE',
        value: event.ticketLink.isEmpty ? 'Free' : 'Ticketed',
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: items.map((item) => _buildInfoCell(theme, item)).toList(),
    );
  }

  Widget _buildInfoCell(ThemeData theme, _InfoItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(item.icon, size: 16, color: item.iconColor),
              const SizedBox(width: 4),
              Text(
                item.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  fontSize: 9,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Section wrapper ───────────────────────────────────────────────────────

  Widget _buildSection(ThemeData theme,
      {required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // ── About ─────────────────────────────────────────────────────────────────

  Widget _buildAbout(ThemeData theme) {
    // Backend doesn't store a description yet — show a sensible fallback
    final description = event.timeDescription.isNotEmpty
        ? 'Join us for ${event.name} at ${event.venue}. '
            '${event.timeDescription}.'
        : 'Join us for ${event.name} at ${event.venue}.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          description,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            height: 1.6,
          ),
        ),
        if (event.organizer.isNotEmpty) ...[
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              children: [
                const TextSpan(text: 'Organized by '),
                TextSpan(
                  text: event.organizer,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Highlights ────────────────────────────────────────────────────────────

  Widget _buildHighlights(ThemeData theme) {
    // Derive basic highlights from available data
    final highlights = <String>[
      if (event.category.isNotEmpty) event.category,
      if (event.timeDescription.isNotEmpty) event.timeDescription,
      if (event.ticketLink.isEmpty) 'Free entry',
      'Networking opportunities',
      'Open to all students',
    ];

    return Column(
      children: highlights
          .map(
            (h) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      h,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.75),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  // ── Location ──────────────────────────────────────────────────────────────

  Widget _buildLocation(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.location_on_outlined,
                  color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.venue.isNotEmpty ? event.venue : 'Venue TBA',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (event.venue.isNotEmpty)
                    Text(
                      event.venue,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),

        // View on Map — always shown if there is a venue
        if (event.venue.isNotEmpty) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                final query = Uri.encodeComponent(event.venue);
                _launchUrl(context,
                    'https://www.google.com/maps/search/?api=1&query=$query');
              },
              icon: Icon(Icons.map_outlined,
                  size: 16, color: theme.colorScheme.primary),
              label: const Text(
                'View on Map',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                side: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.4),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],

        // Event website link (secondary, only when available)
        if (event.eventLink.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _launchUrl(context, event.eventLink),
              icon: Icon(Icons.open_in_new,
                  size: 14,
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.45)),
              label: Text(
                'View Event Website',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Bottom CTA ────────────────────────────────────────────────────────────

  Widget _buildBottomCTA(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary CTA
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _submittingStatus != null
                  ? null
                  : () => _handleCTA('interested'),
              icon: _submittingStatus == 'interested'
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.people_alt_outlined, size: 18),
              label: Text(
                _submittingStatus == 'interested'
                    ? 'Registering…'
                    : 'Interested – Find Travel Buddies',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Secondary text link — just navigate, no backend call
          GestureDetector(
            onTap: _submittingStatus != null
                ? null
                : () {
                    // Only set locally — no API call, no attendee/profile update
                    context.read<EventProvider>().setActiveEvent(event);
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
            child: Text(
              'Skip Details – Start Matching Now',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.w600,
                fontSize: 13,
                decoration: TextDecoration.underline,
                decorationColor:
                    theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data class for info grid cells ────────────────────────────────────────────

class _InfoItem {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });
}
