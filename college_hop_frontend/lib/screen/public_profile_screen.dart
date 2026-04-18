import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:college_hop/providers/auth_provider.dart';
import 'package:college_hop/services/api_service.dart';
import 'package:college_hop/theme/app_scaffold.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;
  final bool isConnected;
  final Color? avatarColor;
  const PublicProfileScreen({super.key, required this.userId, this.isConnected = false, this.avatarColor});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;
  bool _connecting = false;
  late bool _connected = widget.isConnected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final token = context.read<AuthProvider>().accessToken;
      if (token == null) {
        setState(() { _error = 'Not authenticated.'; _loading = false; });
        return;
      }
      final res = await ApiService.getPublicProfile(token, widget.userId);
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

  Future<void> _showConnectSheet() async {
    final token = context.read<AuthProvider>().accessToken;
    if (token == null) return;
    
    final fullName = (_profile?['full_name'] as String?)?.trim() ?? 'User';
    final firstName = fullName.split(' ').first;

    final templates = [
      "Hey $firstName! Would love to connect 👋",
      "Hi $firstName, saw your profile — let's connect!",
      "Hey $firstName, interested in connecting!"
    ];

    final msgCtrl = TextEditingController();
    bool isSending = false;

    // Use a StatefulBuilder so the bottom sheet can update its own local state (like sending spinners)
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Send Connection Request", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Include a message to introduce yourself.", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: templates.map((t) => ActionChip(
                      label: Text(t, style: const TextStyle(fontSize: 12)),
                      onPressed: () {
                        msgCtrl.text = t;
                      },
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: msgCtrl,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: "Write a message...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isSending ? null : () async {
                        final msg = msgCtrl.text.trim();
                        if (msg.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add a message to connect.')));
                          return;
                        }

                        setSheetState(() => isSending = true);
                        try {
                          final res = await ApiService.connectUser(token, widget.userId, msg);
                          if (res.statusCode == 201 && mounted) {
                            Navigator.pop(ctx); // Close sheet
                            setState(() { _connected = true; _connecting = false; });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Request sent!'), backgroundColor: Colors.green, duration: Duration(seconds: 2)),
                            );
                          } else {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not send request.'), backgroundColor: Colors.red, duration: Duration(seconds: 2)));
                            setSheetState(() => isSending = false);
                          }
                        } catch (_) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error. Check connection.'), backgroundColor: Colors.red, duration: Duration(seconds: 2)));
                          setSheetState(() => isSending = false);
                        }
                      },
                      child: isSending
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text("Send Request"),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
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

            // Header row: back + overflow menu
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      onSelected: (value) async {
                        if (value == 'block') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              title: const Text('Block User'),
                              content: Text('Are you sure you want to block ${p['full_name'] ?? 'this user'}?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text('Block', style: TextStyle(color: theme.colorScheme.error)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && mounted) {
                            final token = context.read<AuthProvider>().accessToken;
                            if (token != null) {
                              await ApiService.blockUser(token, widget.userId);
                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${p['full_name'] ?? 'User'} has been blocked.'),
                                    backgroundColor: Colors.red.shade700,
                                  ),
                                );
                              }
                            }
                          }
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'block',
                          child: Row(
                            children: [
                              Icon(Icons.block, size: 18, color: theme.colorScheme.error),
                              const SizedBox(width: 12),
                              Text('Block User', style: TextStyle(color: theme.colorScheme.error)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
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

                  const SizedBox(height: 16),

                  // Connect button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (_connecting || _connected) ? null : _showConnectSheet,
                      icon: Icon(
                        _connected ? Icons.check_circle : Icons.person_add_alt_1,
                      ),
                      label: Text(
                        _connected
                            ? 'Request Pending'
                            : _connecting
                                ? 'Connecting...'
                                : 'Connect',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
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
                  backgroundColor: hasPhoto
                      ? Colors.white
                      : (widget.avatarColor ?? colorScheme.primary).withValues(alpha: 0.15),
                  backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
                  child: !hasPhoto
                      ? Text(initials, style: TextStyle(color: widget.avatarColor ?? colorScheme.primary, fontSize: 24, fontWeight: FontWeight.bold))
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
