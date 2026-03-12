import 'package:college_hop/screen/account_info.dart';
import 'package:college_hop/screen/verify_student_id.dart';
import 'package:flutter/material.dart';
import 'package:college_hop/theme/app_scaffold.dart';
import 'help_screen.dart';
import 'legal_info_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  bool showLocation = true;
  bool pushNotifications = true;
  bool emailNotifications = true;
  bool newMatchAlerts = true;
  bool messageAlerts = true;

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    return AppScaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            /// HEADER (Back + Center Title)
            Row(
              children: [

                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),

                Expanded(
                  child: Center(
                    child: Text(
                      "Settings",
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 48),
              ],
            ),

            const SizedBox(height: 20),

            /// ACCOUNT SECTION
            _sectionTitle(theme, "ACCOUNT"),

            _settingsTile(
              theme,
              icon: Icons.person_outline,
              title: "Account Information",
              subtitle: "Email and verification",
              onTap: () {
                Navigator.push(
                   context,
                   MaterialPageRoute(
                     builder: (context) => const AccountInformationScreen(),
                  ),
                );
              },
            ),

            _settingsTile(
              theme,
              icon: Icons.verified_outlined,
              title: "Verify Student ID",
              subtitle: "Update verification status",
              onTap: () {
                Navigator.push(
                   context,
                   MaterialPageRoute(
                     builder: (context) => const VerifyStudentIDScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            /// PRIVACY
            _sectionTitle(theme, "PRIVACY"),

            _settingsTile(
              theme,
              icon: Icons.visibility_outlined,
              title: "Profile Visibility",
              subtitle: "Control who can see your profile",
              onTap: () {},
            ),

            _switchTile(
              theme,
              icon: Icons.location_on_outlined,
              title: "Show Location",
              subtitle: "Display city on profile",
              value: showLocation,
              onChanged: (value) {
                setState(() {
                  showLocation = value;
                });
              },
            ),

            const SizedBox(height: 20),

            /// NOTIFICATIONS
            _sectionTitle(theme, "NOTIFICATIONS"),

            _switchTile(
              theme,
              icon: Icons.notifications_outlined,
              title: "Push Notifications",
              subtitle: "Receive push notifications",
              value: pushNotifications,
              onChanged: (value) {
                setState(() {
                  pushNotifications = value;
                });
              },
            ),

            _switchTile(
              theme,
              icon: Icons.email_outlined,
              title: "Email Notifications",
              subtitle: "Receive email updates",
              value: emailNotifications,
              onChanged: (value) {
                setState(() {
                  emailNotifications = value;
                });
              },
            ),

            _switchTile(
              theme,
              icon: Icons.auto_awesome,
              title: "New Match Alerts",
              subtitle: "Get notified about new matches",
              value: newMatchAlerts,
              onChanged: (value) {
                setState(() {
                  newMatchAlerts = value;
                });
              },
            ),

            _switchTile(
              theme,
              icon: Icons.message_outlined,
              title: "Message Alerts",
              subtitle: "Get notified about messages",
              value: messageAlerts,
              onChanged: (value) {
                setState(() {
                  messageAlerts = value;
                });
              },
            ),

            const SizedBox(height: 20),

            /// SUPPORT
            _sectionTitle(theme, "SUPPORT"),

            _settingsTile(
              theme,
              icon: Icons.help_outline,
              title: "Help Center",
              subtitle: "FAQs and support",
              onTap: () {
                Navigator.push(
                   context,
                   MaterialPageRoute(
                     builder: (context) => const HelpCenterScreen(),
                  ),
                );
              },
            ),

            _settingsTile(
              theme,
              icon: Icons.description_outlined,
              title: "Terms & Privacy",
              subtitle: "Legal information",
              onTap: () {Navigator.push(
                   context,
                   MaterialPageRoute(
                     builder: (context) => const LegalInformationScreen(),
                  ),
                );},
            ),

            const SizedBox(height: 20),

            /// DANGER ZONE
            _sectionTitle(theme, "DANGER ZONE"),

            Container(
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.red.withOpacity(0.2),
                ),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  "Log Out",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {},
              ),
            ),

            const SizedBox(height: 20),

            /// APP VERSION
            Center(
              child: Text(
                "College Hop v1.0.0",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  /// SECTION TITLE
  Widget _sectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  /// NORMAL TILE
  Widget _settingsTile(
      ThemeData theme, {
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.15),
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  /// SWITCH TILE
 Widget _switchTile(
  ThemeData theme, {
  required IconData icon,
  required String title,
  required String subtitle,
  required bool value,
  required Function(bool) onChanged,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: theme.colorScheme.outline.withOpacity(.15),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        )
      ],
    ),
    child: Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(.6),
                ),
              ),
            ],
          ),
        ),

        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: theme.colorScheme.primary,
        )
      ],
    ),
  );
}
}