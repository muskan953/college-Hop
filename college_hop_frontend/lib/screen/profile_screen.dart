import 'package:college_hop/theme/app_scaffold.dart';
import 'package:college_hop/screen/setting_screen.dart';
import 'package:college_hop/screen/edit_profile_screen.dart';
import 'package:college_hop/screen/splash_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:college_hop/providers/auth_provider.dart';
import 'package:college_hop/providers/profile_provider.dart';
import 'package:college_hop/providers/message_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

enum ProfileTab { about, events, groups }

class _ProfileScreenState extends State<ProfileScreen> {
  ProfileTab activeTab = ProfileTab.about;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().accessToken;
      if (token != null) {
        final prov = context.read<ProfileProvider>();
        prov.fetchProfile(token);
        prov.fetchEvents(token);
        prov.fetchGroups(token);
      }
    });
  }

  void _shareProfile(Map<String, dynamic>? profile) {
    // Use AuthProvider.userId (from JWT) as the authoritative source
    final authUserId = context.read<AuthProvider>().userId ?? '';
    final userId  = authUserId.isNotEmpty ? authUserId : ((profile?['user_id'] as String?) ?? '');
    final name    = (profile?['full_name'] as String?)?.trim() ?? 'CollegeHop User';
    final college = (profile?['college_name'] as String?) ?? '';

    // Builds the link from whatever host the app is currently running on
    final baseUrl = kIsWeb ? Uri.base.origin : 'http://localhost:8080';
    final profileLink = '$baseUrl/profile/$userId';
    final shareText   = Uri.encodeComponent(
      '${Uri.encodeComponent('')}Check out $name\'s profile on CollegeHop!\n$profileLink',
    );

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        bool copied = false;
        return StatefulBuilder(
          builder: (ctx, setS) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Handle bar
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: .3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),

                Text('Share Profile', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                if (college.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(college, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],

                const SizedBox(height: 20),

                // Profile link row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          profileLink,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: profileLink));
                          setS(() => copied = true);
                          Future.delayed(const Duration(seconds: 2), () {
                            if (ctx.mounted) setS(() => copied = false);
                          });
                        },
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: copied
                              ? const Icon(Icons.check_circle, color: Colors.green, size: 20, key: ValueKey('check'))
                              : const Icon(Icons.copy, size: 20, key: ValueKey('copy')),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Text('Share via', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                const SizedBox(height: 14),

                // Quick-share chips
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _shareChip(
                      ctx,
                      icon: Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/6/6b/WhatsApp.svg',
                        width: 28, height: 28,
                        errorBuilder: (_, __, ___) => const Icon(Icons.chat, size: 28, color: Color(0xFF25D366)),
                      ),
                      label: 'WhatsApp',
                      onTap: () => launchUrl(Uri.parse('https://wa.me/?text=$shareText'), mode: LaunchMode.externalApplication),
                    ),
                    _shareChip(
                      ctx,
                      icon: const Icon(Icons.mail_outline, size: 28, color: Colors.red),
                      label: 'Email',
                      onTap: () => launchUrl(
                        Uri.parse('mailto:?subject=${Uri.encodeComponent('Check out $name on CollegeHop')}&body=${Uri.encodeComponent('$name\'s profile:\n$profileLink')}'),
                      ),
                    ),
                    _shareChip(
                      ctx,
                      icon: const Icon(Icons.copy_outlined, size: 28),
                      label: 'Copy Link',
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: profileLink));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Link copied!'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 2)),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _shareChip(BuildContext context, {required Widget icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 58, height: 58,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(child: icon),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final profile = context.watch<ProfileProvider>().profileData;
    final isLoading = context.watch<ProfileProvider>().isLoading;

    // ── Dynamic values ──────────────────────────────────────────────────────
    final fullName = (profile?['full_name'] as String?) ?? 'My Profile';
    // Use first letters of each word as initials (max 2)
    final initials = fullName.trim().split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    final isVerified = (profile?['status'] as String?) == 'verified';
    final isAlumni = (profile?['is_alumni'] as bool?) == true;

    final photoUrl = profile?['profile_photo_url'] as String?;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    final eventsCount = (profile?['events_count'] as int?) ?? 0;
    final connectionsCount = (profile?['connections_count'] as int?) ?? 0;
    final groupsCount = (profile?['groups_count'] as int?) ?? 0;

    return AppScaffold(
      body: isLoading && profile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // The Light Blue Gradient Header
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.blue.shade300,
                          Colors.blue.shade500,
                        ],
                      ),
                    ),
                  ),

                  // Content Card
                  Container(
                    margin: const EdgeInsets.only(top: 140),
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - 140,
                    ),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fullName,
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                // ── Verified / Alumni tags ────────────────────
                                if (isVerified || isAlumni)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Row(
                                      children: [
                                        if (isVerified)
                                          _buildTag('Verified', Icons.verified, Colors.blue),
                                        if (isVerified && isAlumni)
                                          const SizedBox(width: 6),
                                        if (isAlumni)
                                          _buildTag('Alumni', Icons.school, Colors.purple),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                              ).then((_) {
                                final token = context.read<AuthProvider>().accessToken;
                                if (token != null) {
                                  context.read<ProfileProvider>().fetchProfile(token);
                                }
                              }),
                              icon: const Icon(Icons.edit, color: Colors.white, size: 14),
                              label: const Text("Edit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                elevation: 0,
                                minimumSize: const Size(0, 36),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildStatsRow(eventsCount, connectionsCount, groupsCount, colorScheme, textTheme),
                        const SizedBox(height: 24),
                        _buildTabSwitcher(colorScheme, textTheme),
                        const SizedBox(height: 24),
                        _buildTabContent(profile, colorScheme, textTheme),
                      ],
                    ),
                  ),

                  // Avatar rendered exactly on the seam
                  Positioned(
                    top: 140 - 45,
                    left: 24,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 41,
                        backgroundColor: Colors.white,
                        backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
                        child: !hasPhoto
                            ? Text(initials, style: TextStyle(color: colorScheme.primary, fontSize: 24, fontWeight: FontWeight.bold))
                            : null,
                      ),
                    ),
                  ),

                  // Top Nav Icons
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.share_outlined, color: Colors.white, size: 22),
                            onPressed: () => _shareProfile(profile),
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 22),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SettingsScreen()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTag(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // --- UI Building Blocks ---

  Widget _buildStatsRow(int events, int connections, int groups, ColorScheme colorScheme, TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _statTile('$events', "Events", colorScheme, textTheme),
        _statTile('$connections', "Connections", colorScheme, textTheme),
        _statTile('$groups', "Groups", colorScheme, textTheme),
      ],
    );
  }

  Widget _statTile(String val, String label, ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.primary)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: textTheme.bodyMedium?.color?.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildTabSwitcher(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      decoration: BoxDecoration(
        color: textTheme.bodyMedium?.color?.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _tabItem("About", ProfileTab.about, colorScheme, textTheme),
          _tabItem("Events", ProfileTab.events, colorScheme, textTheme),
          _tabItem("Groups", ProfileTab.groups, colorScheme, textTheme),
        ],
      ),
    );
  }

  Widget _tabItem(String title, ProfileTab tab, ColorScheme colorScheme, TextTheme textTheme) {
    bool active = activeTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => activeTab = tab),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? Colors.white : textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(Map<String, dynamic>? profile, ColorScheme colorScheme, TextTheme textTheme) {
    switch (activeTab) {
      case ProfileTab.about:
        return _buildAboutTab(profile, colorScheme, textTheme);
      case ProfileTab.events:
        return _buildEventsTab(colorScheme, textTheme);
      case ProfileTab.groups:
        return _buildGroupsTab(colorScheme, textTheme);
    }
  }

  Widget _buildAboutTab(Map<String, dynamic>? profile, ColorScheme colorScheme, TextTheme textTheme) {
    final bio = (profile?['bio'] as String?) ?? '';
    final collegeName = (profile?['college_name'] as String?) ?? '';
    final major = (profile?['major'] as String?) ?? '';
    final rollNumber = (profile?['roll_number'] as String?) ?? '';
    final idExpiration = (profile?['id_expiration'] as String?) ?? '';
    final interests = List<String>.from((profile?['interests'] as List?) ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Bio"),
        const SizedBox(height: 12),
        Text(
          bio.isNotEmpty ? bio : 'No bio added yet.',
          style: TextStyle(color: textTheme.bodyMedium?.color?.withValues(alpha: 0.7), height: 1.5, fontSize: 13),
        ),

        const SizedBox(height: 24),

        _buildSectionTitle("Education"),
        const SizedBox(height: 12),
        _buildInfoTile(
          Icons.school_outlined,
          collegeName.isNotEmpty ? collegeName : 'Not set',
          major.isNotEmpty ? major : '',
          theme: Theme.of(context),
        ),

        const SizedBox(height: 24),

        _buildSectionTitle("Details"),
        const SizedBox(height: 12),
        _buildDetailRow(Icons.badge_outlined, rollNumber.isNotEmpty ? 'Roll No: $rollNumber' : 'Roll number not set', textTheme),
        const SizedBox(height: 12),
        _buildDetailRow(
          Icons.calendar_today_outlined,
          idExpiration.isNotEmpty ? 'ID Expires: $idExpiration' : 'ID not set',
          textTheme,
        ),

        const SizedBox(height: 24),

        _buildSectionTitle("Interests"),
        const SizedBox(height: 16),
        interests.isNotEmpty
            ? Wrap(
                spacing: 8,
                runSpacing: 8,
                children: interests.map((tag) => _buildChip(tag, colorScheme)).toList(),
              )
            : Text('No interests added yet.', style: TextStyle(fontSize: 13, color: textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),

        const SizedBox(height: 48),

        Center(
          child: TextButton.icon(
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (!context.mounted) return;
              context.read<MessageProvider>().reset();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SplashScreen()),
                (_) => false,
              );
            },
            icon: const Icon(Icons.logout, color: Colors.red, size: 18),
            label: const Text("Log Out", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildEventsTab(ColorScheme colorScheme, TextTheme textTheme) {
    final userEvents = context.watch<ProfileProvider>().userEvents ?? [];

    if (userEvents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 32),
          child: Text("No events joined yet.", style: TextStyle(color: textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
        ),
      );
    }

    return Column(
      children: userEvents.map((e) {
        final name = (e['name'] as String?) ?? 'Unknown Event';
        final date = (e['start_date'] as String?)?.split('T').first ?? 'TBA'; // format YYYY-MM-DD
        final status = (e['user_status'] as String?) ?? 'Unknown';
        return _buildEventListItem(name, date, status, colorScheme, textTheme);
      }).toList(),
    );
  }

  Widget _buildGroupsTab(ColorScheme colorScheme, TextTheme textTheme) {
    final userGroups = context.watch<ProfileProvider>().userGroups ?? [];

    if (userGroups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 32),
          child: Text("No groups joined yet.", style: TextStyle(color: textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
        ),
      );
    }

    return Column(
      children: userGroups.map((g) {
        final groupName = (g['name'] as String?) ?? 'Unknown Group';
        final eventName = (g['event_name'] as String?) ?? 'Unknown Event';
        final membersCount = (g['member_count'] as int?) ?? 0;
        final countStr = membersCount == 1 ? "1 member" : "$membersCount members";
        return _buildGroupListItem(groupName, eventName, countStr, colorScheme, textTheme);
      }).toList(),
    );
  }

  Widget _buildEventListItem(String title, String date, String status, ColorScheme colorScheme, TextTheme textTheme) {
    final isConfirmed = status.toLowerCase() == "confirmed";
    final statusColor = isConfirmed ? Colors.green : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: textTheme.bodyMedium?.color?.withValues(alpha: 0.02),
        border: Border.all(color: textTheme.bodyMedium?.color?.withValues(alpha: 0.05) ?? Colors.grey.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 12, color: textTheme.bodyMedium?.color?.withValues(alpha: 0.4)),
                  const SizedBox(width: 4),
                  Text(date, style: TextStyle(fontSize: 11, color: textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupListItem(String name, String eventName, String members, ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: textTheme.bodyMedium?.color?.withValues(alpha: 0.02),
        border: Border.all(color: textTheme.bodyMedium?.color?.withValues(alpha: 0.05) ?? Colors.grey.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: colorScheme.primary,
            child: const Icon(Icons.group, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(eventName, style: TextStyle(fontSize: 11, color: textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.people_outline, size: 12, color: textTheme.bodyMedium?.color?.withValues(alpha: 0.4)),
                    const SizedBox(width: 4),
                    Text(members, style: TextStyle(fontSize: 10, color: textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildDetailRow(IconData icon, String text, TextTheme textTheme) {
    return Row(
      children: [
        Icon(icon, size: 16, color: textTheme.bodyMedium?.color?.withValues(alpha: 0.4)),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 13, color: textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle, {required ThemeData theme}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5), height: 1.4)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String label, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

