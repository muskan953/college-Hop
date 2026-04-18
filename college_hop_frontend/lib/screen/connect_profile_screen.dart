import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:college_hop/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:college_hop/providers/auth_provider.dart';
import 'package:college_hop/theme/app_scaffold.dart';
import 'package:college_hop/screen/connection_success_screen.dart';

class ConnectProfileScreen extends StatefulWidget {
  final Map<String, dynamic> matchData;
  const ConnectProfileScreen({super.key, required this.matchData});

  @override
  State<ConnectProfileScreen> createState() => _ConnectProfileScreenState();
}

class _ConnectProfileScreenState extends State<ConnectProfileScreen> {
  final TextEditingController _messageController = TextEditingController();
  String? _sentMessage;
  bool _isConnecting = false;
  bool _hasConnected = false;
  
  Map<String, dynamic>? _fullProfile;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final token = context.read<AuthProvider>().accessToken;
    final userId = widget.matchData['user_id'];
    if (token == null || userId == null) {
      if (mounted) setState(() => _isLoadingProfile = false);
      return;
    }
    try {
      final results = await Future.wait([
        ApiService.getPublicProfile(token, userId),
        ApiService.getThreads(token),
      ]);
      final profileRes = results[0];
      final threadsRes = results[1];
      
      Map<String, dynamic>? fetchedProfile;
      if (profileRes.statusCode == 200) {
        fetchedProfile = jsonDecode(profileRes.body);
      }
      
      bool hasConnected = _hasConnected;
      String? sentMsg = _sentMessage;
      if (threadsRes.statusCode == 200) {
        final List<dynamic> threads = jsonDecode(threadsRes.body);
        for (var t in threads) {
          if (t['other_user_id'] == userId && t['is_request'] == true && t['is_requester'] == true) {
            hasConnected = true;
            sentMsg = t['last_message'];
            break;
          }
        }
      }

      if (mounted) {
        setState(() {
          if (fetchedProfile != null) _fullProfile = fetchedProfile;
          _hasConnected = hasConnected;
          if (sentMsg != null) _sentMessage = sentMsg;
          _isLoadingProfile = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final match = widget.matchData;
    final String fullName = match['full_name'] ?? 'Unknown User';
    final String firstName = fullName.split(' ').first;
    final String college = match['college_name'] ?? '';
    final String profilePhotoUrl = match['profile_photo_url'] ?? '';
    final List<String> sharedInterests = (match['common_interests'] as List<dynamic>?)?.cast<String>() ?? [];
    final double matchScore = match['match_score'] ?? 0.0;
    final int matchPercent = (matchScore * 100).round();
    
    final hue = (fullName.hashCode % 360).abs().toDouble();
    final avatarColor = HSLColor.fromAHSL(1.0, hue, 0.6, 0.5).toColor();

    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar with Badge
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: avatarColor.withValues(alpha: 0.15),
                  backgroundImage: profilePhotoUrl.isNotEmpty ? NetworkImage(profilePhotoUrl) : null,
                  child: profilePhotoUrl.isEmpty
                      ? Text(
                          fullName.isNotEmpty ? fullName[0].toUpperCase() : '?', 
                          style: TextStyle(fontSize: 36, color: avatarColor, fontWeight: FontWeight.bold)
                        )
                      : null,
                ),
                Positioned(
                  bottom: -10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                    ),
                    child: Text(
                      "$matchPercent% Match", 
                      style: TextStyle(
                        fontSize: 10, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.green.shade700
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Name and Uni
            Text(fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            if (college.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(college, style: TextStyle(color: textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
            ],
            
            const SizedBox(height: 24),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatItem(Icons.favorite, Colors.red.shade400, "${sharedInterests.length} shared\ninterests", textTheme),
              ],
            ),
            
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.15),
                    colorScheme.primary.withValues(alpha: 0.03),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoadingProfile)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    // About Section
                    if (_fullProfile?['bio'] != null && _fullProfile!['bio'].toString().isNotEmpty) ...[
                      _buildSectionTitle("About"),
                      const SizedBox(height: 12),
                      Text(
                        _fullProfile!['bio'],
                        style: TextStyle(color: textTheme.bodyMedium?.color?.withValues(alpha: 0.7), height: 1.5),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Education & Info Section
                    if (_fullProfile?['major'] != null && _fullProfile!['major'].toString().isNotEmpty) ...[
                      _buildSectionTitle("Education & Info"),
                      const SizedBox(height: 16),
                      _buildInfoTile(Icons.school_outlined, _fullProfile!['major'], college.isNotEmpty ? college : "University", colorScheme.primary, textTheme),
                      if (_fullProfile?['is_alumni'] == true)
                        _buildInfoTile(Icons.workspace_premium, "Alumni", "Graduated", Colors.orangeAccent, textTheme),
                      const SizedBox(height: 24),
                    ],

                    // Interests Section
                    if (sharedInterests.isNotEmpty) ...[
                      _buildSectionTitle("Shared Interests"),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: sharedInterests.map((interest) => _buildChip(interest, colorScheme.secondary, true)).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],
                    
                    if (_fullProfile?['interests'] != null) ...[
                      Builder(
                        builder: (ctx) {
                          final List<String> allInterests = (_fullProfile!['interests'] as List<dynamic>).cast<String>();
                          final otherInterests = allInterests.where((i) => !sharedInterests.contains(i)).toList();
                          if (otherInterests.isNotEmpty) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("OTHER INTERESTS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: otherInterests.map((interest) {
                                    return _buildChip(interest, textTheme.bodyMedium?.color?.withValues(alpha: 0.6) ?? Colors.grey, false);
                                  }).toList(),
                                ),
                                const SizedBox(height: 24),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        }
                      ),
                    ],
                  ],
                ],
              ),
            ),

            // Attending Events Section
            Builder(builder: (ctx) {
              final eventName = match['event_name'] as String?;
              final eventDate = match['event_date'] as String?;
              if (eventName == null || eventName.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("Attending Events"),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: textTheme.bodyMedium?.color?.withValues(alpha: 0.08) ?? Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.calendar_month_outlined, color: colorScheme.primary, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(eventName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                if (eventDate != null && eventDate.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text("— $eventDate", style: TextStyle(fontSize: 12, color: textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text("Same Event", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: textTheme.bodyMedium?.color?.withValues(alpha: 0.05) ?? Colors.transparent)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (_isConnecting || _hasConnected) ? null : () async {
                    setState(() => _isConnecting = true);

                    // Skip the success screen animation? The user loved the success screen earlier, so we pop it and THEN logic?
                    // Actually, the success screen was completely fake! 
                    // Let's just launch the modal directly.
                    setState(() => _isConnecting = false);
                    _showSendMessageBottomSheet(context, theme, textTheme, colorScheme, fullName, firstName, match['user_id']);
                  },
                  icon: Icon(_hasConnected ? Icons.check_circle : Icons.person_add_alt_1, color: Colors.white, size: 20),
                  label: Text(_hasConnected ? "Request Pending" : "Connect", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasConnected ? Colors.grey : colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: textTheme.bodyMedium?.color?.withValues(alpha: 0.1) ?? Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, Color iconColor, String text, TextTheme textTheme) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 12, color: textTheme.bodyMedium?.color?.withValues(alpha: 0.8))),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle, Color iconColor, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 12, color: textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color, bool isShared) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isShared ? color.withValues(alpha: 0.05) : Colors.transparent,
        border: Border.all(color: color.withValues(alpha: isShared ? 0.3 : 0.2)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label, 
        style: TextStyle(
          color: color, 
          fontSize: 12, 
          fontWeight: isShared ? FontWeight.w600 : FontWeight.normal
        ),
      ),
    );
  }

  Widget _buildEventCard(String title, String? date, bool sameEvent, ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: textTheme.bodyMedium?.color?.withValues(alpha: 0.02),
        border: Border.all(color: textTheme.bodyMedium?.color?.withValues(alpha: 0.05) ?? Colors.transparent),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_outlined, color: colorScheme.primary, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                if (date != null) ...[
                  const SizedBox(height: 2),
                  Text(date, style: TextStyle(fontSize: 12, color: textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
                ],
              ],
            ),
          ),
          if (sameEvent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "Same Event",
                style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),]
      ),
    );
  }

  void _showSendMessageBottomSheet(BuildContext context, ThemeData theme, TextTheme textTheme, ColorScheme colorScheme, String fullName, String firstName, String userId) {
    _messageController.clear();
    bool sheetSending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Send a message", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text("Introduce yourself to $fullName", style: TextStyle(fontSize: 14, color: textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: Icon(Icons.close, color: textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
              const SizedBox(height: 24),
              Row(
                children: [
                   Icon(Icons.bolt, color: colorScheme.primary, size: 16),
                   const SizedBox(width: 4),
                   Text("QUICK TEMPLATES", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
                ],
              ),
              const SizedBox(height: 12),
              _buildTemplateCard("Hey $firstName! Excited to connect for the event. Looking forward to meeting you!", textTheme, colorScheme),
              _buildTemplateCard("Hi $firstName! I noticed we share a lot of interests. Would love to coordinate plans!", textTheme, colorScheme),
              _buildTemplateCard("Hey $firstName! Let's connect and figure out travel details together.", textTheme, colorScheme),
              const SizedBox(height: 24),
              Text("OR WRITE YOUR OWN", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: textTheme.bodyMedium?.color?.withValues(alpha: 0.02),
                  border: Border.all(color: textTheme.bodyMedium?.color?.withValues(alpha: 0.1) ?? Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "Type your message here...",
                    hintStyle: TextStyle(color: textTheme.bodyMedium?.color?.withValues(alpha: 0.4), fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text("0/500 characters", style: TextStyle(fontSize: 11, color: textTheme.bodyMedium?.color?.withValues(alpha: 0.4))),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: textTheme.bodyMedium?.color?.withValues(alpha: 0.1) ?? Colors.grey.shade300),
                      ),
                      child: Text("Skip for now", style: TextStyle(color: textTheme.bodyMedium?.color, fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: sheetSending ? null : () async {
                        final msg = _messageController.text.trim();
                        if (msg.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add a message.')));
                          return;
                        }
                        setSheetState(() => sheetSending = true);
                        
                        try {
                          final token = context.read<AuthProvider>().accessToken;
                          if (token == null) return;
                          
                          final res = await ApiService.connectUser(token, userId, msg);
                          if (res.statusCode == 201 && mounted) {
                            setState(() {
                              _sentMessage = msg;
                              _hasConnected = true;
                            });
                            Navigator.pop(ctx);
                            
                            // Optionally show success screen
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => const ConnectionSuccessScreen(),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  return FadeTransition(opacity: animation, child: child);
                                },
                              ),
                            );
                          } else {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not request connection'), backgroundColor: Colors.red));
                            setSheetState(() => sheetSending = false);
                          }
                        } catch (e) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error'), backgroundColor: Colors.red));
                          setSheetState(() => sheetSending = false);
                        }
                      },
                      icon: sheetSending 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send, color: Colors.white, size: 16),
                      label: Text(sheetSending ? "Sending..." : "Send Message", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
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

  Widget _buildTemplateCard(String text, TextTheme textTheme, ColorScheme colorScheme) {
    return InkWell(
      onTap: () {
        _messageController.text = text;
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: textTheme.bodyMedium?.color?.withValues(alpha: 0.02),
          border: Border.all(color: textTheme.bodyMedium?.color?.withValues(alpha: 0.1) ?? Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text, style: TextStyle(fontSize: 13, color: textTheme.bodyMedium?.color?.withValues(alpha: 0.8), height: 1.4)),
      ),
    );
  }
}

