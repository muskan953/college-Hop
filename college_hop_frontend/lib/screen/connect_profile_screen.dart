import 'package:flutter/material.dart';
import 'package:college_hop/theme/app_scaffold.dart';
import 'package:college_hop/screen/connection_success_screen.dart';

class ConnectProfileScreen extends StatefulWidget {
  const ConnectProfileScreen({super.key});

  @override
  State<ConnectProfileScreen> createState() => _ConnectProfileScreenState();
}

class _ConnectProfileScreenState extends State<ConnectProfileScreen> {
  final TextEditingController _messageController = TextEditingController();
  String? _sentMessage;

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
                  backgroundColor: colorScheme.primary,
                  child: const Text(
                    "P", 
                    style: TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold)
                  ),
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
                      "Great Match", 
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
            const Text("Priya Sharma", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text("MIT", style: TextStyle(color: textTheme.bodyMedium?.color?.withOpacity(0.6))),
            
            const SizedBox(height: 24),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatItem(Icons.favorite, Colors.red.shade400, "2 shared\ninterests", textTheme),
                Container(
                  height: 30,
                  width: 1,
                  color: textTheme.bodyMedium?.color?.withOpacity(0.1),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                ),
                _buildStatItem(Icons.people, colorScheme.primary, "5 mutual\nconnections", textTheme),
              ],
            ),
            
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withOpacity(0.15),
                    colorScheme.primary.withOpacity(0.03),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // About Section
                  _buildSectionTitle("About"),
                  const SizedBox(height: 12),
                  Text(
                    "Passionate about AI/ML, and building products that make a difference. Always down for hackathons and tech meetups. Love exploring new cities and meeting fellow tech enthusiasts!",
                    style: TextStyle(color: textTheme.bodyMedium?.color?.withOpacity(0.7), height: 1.5),
                  ),
                  
                  const SizedBox(height: 24),

                  // Education & Info Section
                  _buildSectionTitle("Education & Info"),
                  const SizedBox(height: 16),
                  _buildInfoTile(Icons.school_outlined, "Computer Science", "3rd Year", colorScheme.primary, textTheme),
                  _buildInfoTile(Icons.location_on_outlined, "Cambridge, MA", "Current Location", Colors.orangeAccent, textTheme),

                  const SizedBox(height: 24),

                  // Interests Section
                  _buildSectionTitle("Shared Interests"),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip("# AI", colorScheme.secondary, true),
                      _buildChip("# Startups", colorScheme.secondary, true),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  Text("OTHER INTERESTS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textTheme.bodyMedium?.color?.withOpacity(0.5))),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip("Hackathons", textTheme.bodyMedium?.color?.withOpacity(0.6) ?? Colors.grey, false),
                      _buildChip("Photography", textTheme.bodyMedium?.color?.withOpacity(0.6) ?? Colors.grey, false),
                      _buildChip("Travel", textTheme.bodyMedium?.color?.withOpacity(0.6) ?? Colors.grey, false),
                      _buildChip("Coffee", textTheme.bodyMedium?.color?.withOpacity(0.6) ?? Colors.grey, false),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Attending Events Section
                  _buildSectionTitle("Attending Events"),
                  const SizedBox(height: 12),
                  _buildEventCard("TechCrunch Disrupt", "March 20", true, colorScheme, textTheme),
                  _buildEventCard("TechCrunch Disrupt", null, false, colorScheme, textTheme),
                  _buildEventCard("AWS Summit", null, false, colorScheme, textTheme),
                ],
              ),
            ),
            
            if (_sentMessage != null && _sentMessage!.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildSectionTitle("Sent Message"),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.05),
                  border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _sentMessage!,
                  style: TextStyle(
                    color: textTheme.bodyMedium?.color?.withOpacity(0.9),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ],

          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: textTheme.bodyMedium?.color?.withOpacity(0.05) ?? Colors.transparent)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
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
                  onPressed: () async {
                    final bool? result = await Navigator.push<bool>(
                      context,
                      PageRouteBuilder<bool>(
                        pageBuilder: (context, animation, secondaryAnimation) => const ConnectionSuccessScreen(),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                      ),
                    );

                    if (result == true) {
                      if (!context.mounted) return;
                      _showSendMessageBottomSheet(context, theme, textTheme, colorScheme);
                    }
                  },
                  icon: const Icon(Icons.person_add_alt_1, color: Colors.white, size: 20),
                  label: const Text("Connect", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: textTheme.bodyMedium?.color?.withOpacity(0.1) ?? Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: textTheme.bodyMedium?.color?.withOpacity(0.6)),
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
        Text(text, style: TextStyle(fontSize: 12, color: textTheme.bodyMedium?.color?.withOpacity(0.8))),
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
              color: iconColor.withOpacity(0.1),
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
              Text(subtitle, style: TextStyle(fontSize: 12, color: textTheme.bodyMedium?.color?.withOpacity(0.5))),
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
        color: isShared ? color.withOpacity(0.05) : Colors.transparent,
        border: Border.all(color: color.withOpacity(isShared ? 0.3 : 0.2)),
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
        color: textTheme.bodyMedium?.color?.withOpacity(0.02),
        border: Border.all(color: textTheme.bodyMedium?.color?.withOpacity(0.05) ?? Colors.transparent),
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
                  Text(date, style: TextStyle(fontSize: 12, color: textTheme.bodyMedium?.color?.withOpacity(0.5))),
                ],
              ],
            ),
          ),
          if (sameEvent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
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

  void _showSendMessageBottomSheet(BuildContext context, ThemeData theme, TextTheme textTheme, ColorScheme colorScheme) {
    _messageController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
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
                      Text("Introduce yourself to Priya Sharma", style: TextStyle(fontSize: 14, color: textTheme.bodyMedium?.color?.withOpacity(0.6))),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: textTheme.bodyMedium?.color?.withOpacity(0.6)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                   Icon(Icons.bolt, color: colorScheme.primary, size: 16),
                   const SizedBox(width: 4),
                   Text("QUICK TEMPLATES", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textTheme.bodyMedium?.color?.withOpacity(0.5))),
                ],
              ),
              const SizedBox(height: 12),
              _buildTemplateCard("Hey! Excited to connect for the event. Looking forward to meeting you!", textTheme, colorScheme),
              _buildTemplateCard("Hi! I noticed we share a lot of interests. Would love to coordinate travel plans!", textTheme, colorScheme),
              _buildTemplateCard("Hey Priya! Let's connect and figure out travel details together.", textTheme, colorScheme),
              const SizedBox(height: 24),
              Text("OR WRITE YOUR OWN", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textTheme.bodyMedium?.color?.withOpacity(0.5))),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: textTheme.bodyMedium?.color?.withOpacity(0.02),
                  border: Border.all(color: textTheme.bodyMedium?.color?.withOpacity(0.1) ?? Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "Type your message here...",
                    hintStyle: TextStyle(color: textTheme.bodyMedium?.color?.withOpacity(0.4), fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text("0/500 characters", style: TextStyle(fontSize: 11, color: textTheme.bodyMedium?.color?.withOpacity(0.4))),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: textTheme.bodyMedium?.color?.withOpacity(0.1) ?? Colors.grey.shade300),
                      ),
                      child: Text("Skip for now", style: TextStyle(color: textTheme.bodyMedium?.color, fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _sentMessage = _messageController.text.trim();
                        });
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.send, color: Colors.white, size: 16),
                      label: const Text("Send Message", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
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
          color: textTheme.bodyMedium?.color?.withOpacity(0.02),
          border: Border.all(color: textTheme.bodyMedium?.color?.withOpacity(0.1) ?? Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text, style: TextStyle(fontSize: 13, color: textTheme.bodyMedium?.color?.withOpacity(0.8), height: 1.4)),
      ),
    );
  }
}
