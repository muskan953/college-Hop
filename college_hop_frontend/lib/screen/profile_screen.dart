import 'package:college_hop/theme/app_scaffold.dart'; 
import 'package:college_hop/screen/setting_screen.dart';
import 'package:college_hop/screen/edit_profile_screen.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

enum ProfileTab { about, events, groups }

class _ProfileScreenState extends State<ProfileScreen> {
  ProfileTab activeTab = ProfileTab.about;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return AppScaffold(
      body: SingleChildScrollView(
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
                // Ensure the card takes at least the remaining screen height 
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
                          const Text(
                            "Arjun Mehta",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text("@arjunmehta", style: TextStyle(color: textTheme.bodyMedium?.color?.withOpacity(0.5), fontSize: 13)),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                        ),
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
                  _buildStatsRow(colorScheme, textTheme),
                  const SizedBox(height: 24),
                  _buildTabSwitcher(colorScheme, textTheme),
                  const SizedBox(height: 24),
                  _buildTabContent(colorScheme, textTheme),
                ],
              ),
            ),

            // Avatar rendered exactly on the seam so it overlaps both the blue and white sections
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
                  child: Text("AM", style: TextStyle(color: colorScheme.primary, fontSize: 24, fontWeight: FontWeight.bold)),
                ),
              ),
            ),

            // Top Nav Icons
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.share_outlined, color: Colors.white, size: 22),
                          onPressed: () {},
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI Building Blocks ---

  Widget _buildStatsRow(ColorScheme colorScheme, TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _statTile("12", "Events", colorScheme, textTheme),
        _statTile("147", "Connections", colorScheme, textTheme),
        _statTile("8", "Groups", colorScheme, textTheme),
      ],
    );
  }

  Widget _statTile(String val, String label, ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.primary)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: textTheme.bodyMedium?.color?.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildTabSwitcher(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      decoration: BoxDecoration(
        color: textTheme.bodyMedium?.color?.withOpacity(0.04),
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
              color: active ? Colors.white : textTheme.bodyMedium?.color?.withOpacity(0.5), 
              fontSize: 12,
              fontWeight: FontWeight.bold
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(ColorScheme colorScheme, TextTheme textTheme) {
    switch (activeTab) {
      case ProfileTab.about:
        return _buildAboutTab(colorScheme, textTheme);
      case ProfileTab.events:
        return _buildEventsTab(colorScheme, textTheme);
      case ProfileTab.groups:
        return _buildGroupsTab(colorScheme, textTheme);
    }
  }

  Widget _buildAboutTab(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Bio"),
        const SizedBox(height: 12),
        Text(
          "Tech enthusiast passionate about AI/ML and building innovative solutions. Love attending hackathons and connecting with like-minded people!", 
          style: TextStyle(color: textTheme.bodyMedium?.color?.withOpacity(0.7), height: 1.5, fontSize: 13),
        ),
        
        const SizedBox(height: 24),
        
        _buildSectionTitle("Education"),
        const SizedBox(height: 12),
        _buildInfoTile(
          Icons.school_outlined, 
          "Indian Institute of Technology Delhi", 
          "Computer Science & Engineering\n3rd Year", 
          theme: Theme.of(context)
        ),
        
        const SizedBox(height: 24),
        
        _buildSectionTitle("Details"),
        const SizedBox(height: 12),
        _buildDetailRow(Icons.location_on_outlined, "Delhi, India", textTheme),
        const SizedBox(height: 12),
        _buildDetailRow(Icons.calendar_today_outlined, "Member since January 2024", textTheme),
        
        const SizedBox(height: 24),
        
        _buildSectionTitle("Interests"),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildChip("AI/ML/Data Science", colorScheme),
            _buildChip("Web Development", colorScheme),
            _buildChip("Startups", colorScheme),
            _buildChip("Music", colorScheme),
            _buildChip("Travel", colorScheme),
            _buildChip("Photography", colorScheme),
          ],
        ),
        
        const SizedBox(height: 48),
        
        Center(
          child: TextButton.icon(
            onPressed: () {}, 
            icon: const Icon(Icons.logout, color: Colors.red, size: 18), 
            label: const Text("Log Out", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600))
          ),
        ),
      ],
    );
  }

  Widget _buildEventsTab(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      children: [
        _buildEventListItem("Hackathon IIT Delhi", "March 12, 2024", "Confirmed", colorScheme, textTheme),
        _buildEventListItem("TechxTech Disrupt", "April 10, 2024", "Interested", colorScheme, textTheme),
        _buildEventListItem("Coachella Music Festival", "April 18, 2024", "Confirmed", colorScheme, textTheme),
      ],
    );
  }

  Widget _buildGroupsTab(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      children: [
        _buildGroupListItem("AI Enthusiasts", "Hackathon IIT Delhi", "12 members", colorScheme, textTheme),
        _buildGroupListItem("Tech Explorers", "TechXTech Disrupt", "8 members", colorScheme, textTheme),
        _buildGroupListItem("Festival Squad", "Coachella Music Festival", "4 members", colorScheme, textTheme),
      ],
    );
  }

  Widget _buildEventListItem(String title, String date, String status, ColorScheme colorScheme, TextTheme textTheme) {
    final isConfirmed = status.toLowerCase() == "confirmed";
    final statusColor = isConfirmed ? Colors.green : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: textTheme.bodyMedium?.color?.withOpacity(0.02),
        border: Border.all(color: textTheme.bodyMedium?.color?.withOpacity(0.05) ?? Colors.grey.withOpacity(0.05)),
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
                  Icon(Icons.calendar_today, size: 12, color: textTheme.bodyMedium?.color?.withOpacity(0.4)),
                  const SizedBox(width: 4),
                  Text(date, style: TextStyle(fontSize: 11, color: textTheme.bodyMedium?.color?.withOpacity(0.5))),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status, 
              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)
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
        color: textTheme.bodyMedium?.color?.withOpacity(0.02),
        border: Border.all(color: textTheme.bodyMedium?.color?.withOpacity(0.05) ?? Colors.grey.withOpacity(0.05)),
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
                Text(eventName, style: TextStyle(fontSize: 11, color: textTheme.bodyMedium?.color?.withOpacity(0.5))),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.people_outline, size: 12, color: textTheme.bodyMedium?.color?.withOpacity(0.4)),
                    const SizedBox(width: 4),
                    Text(members, style: TextStyle(fontSize: 10, color: textTheme.bodyMedium?.color?.withOpacity(0.6))),
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
        Icon(icon, size: 16, color: textTheme.bodyMedium?.color?.withOpacity(0.4)),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 13, color: textTheme.bodyMedium?.color?.withOpacity(0.6))),
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
            color: theme.colorScheme.primary.withOpacity(0.1),
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
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5), height: 1.4)),
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
        border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label, 
        style: TextStyle(color: colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
