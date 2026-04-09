import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:college_hop/services/api_service.dart';
import 'package:college_hop/theme/app_scaffold.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;
  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiService.getPublicProfile(widget.userId);
      if (res.statusCode == 200) {
        setState(() {
          _profile = jsonDecode(res.body) as Map<String, dynamic>;
          _loading = false;
        });
      } else {
        setState(() { _error = 'Profile not found.'; _loading = false; });
      }
    } catch (_) {
      setState(() { _error = 'Could not load profile.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_loading) {
      return const AppScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return AppScaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_off_outlined, size: 64, color: colorScheme.outline),
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: colorScheme.outline)),
            ],
          ),
        ),
      );
    }

    final p = _profile!;
    final name = (p['full_name'] as String?)?.trim() ?? 'Unknown User';
    final college = (p['college_name'] as String?) ?? '';
    final major = (p['major'] as String?) ?? '';
    final bio = (p['bio'] as String?) ?? '';
    final photoUrl = (p['profile_photo_url'] as String?) ?? '';
    final isVerified = (p['is_verified'] as bool?) == true;
    final isAlumni = (p['is_alumni'] as bool?) == true;
    final interests = List<String>.from((p['interests'] as List?) ?? []);

    final initials = name.trim().split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    final hasPhoto = photoUrl.isNotEmpty;

    return AppScaffold(
      body: SingleChildScrollView(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Gradient header
            Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue.shade300, Colors.blue.shade500],
                ),
              ),
            ),

            // Back button
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            // Content card
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
              padding: const EdgeInsets.fromLTRB(24, 64, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + tags
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            if (isVerified || isAlumni)
                              Row(
                                children: [
                                  if (isVerified) _tag('Verified', Icons.verified, Colors.blue),
                                  if (isVerified && isAlumni) const SizedBox(width: 6),
                                  if (isAlumni) _tag('Alumni', Icons.school, Colors.purple),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Education
                  if (college.isNotEmpty || major.isNotEmpty) ...[
                    _sectionTitle('Education'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: .1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.school_outlined, color: colorScheme.primary, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (college.isNotEmpty)
                              Text(college, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            if (major.isNotEmpty)
                              Text(major, style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: .5))),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Bio
                  if (bio.isNotEmpty) ...[
                    _sectionTitle('Bio'),
                    const SizedBox(height: 10),
                    Text(bio, style: TextStyle(fontSize: 13, height: 1.5, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: .7))),
                    const SizedBox(height: 24),
                  ],

                  // Interests
                  if (interests.isNotEmpty) ...[
                    _sectionTitle('Interests'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: interests.map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: colorScheme.primary.withValues(alpha: .3)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(tag, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.primary)),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),

            // Avatar
            Positioned(
              top: 140 - 45,
              left: 24,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, shape: BoxShape.circle),
                child: CircleAvatar(
                  radius: 41,
                  backgroundColor: Colors.white,
                  backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
                  child: !hasPhoto
                      ? Text(initials, style: TextStyle(color: colorScheme.primary, fontSize: 24, fontWeight: FontWeight.bold))
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String label, IconData icon, Color color) {
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

  Widget _sectionTitle(String title) =>
      Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold));
}
