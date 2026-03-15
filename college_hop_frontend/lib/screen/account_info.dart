import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:college_hop/theme/app_scaffold.dart';
import 'package:college_hop/providers/auth_provider.dart';
import 'package:college_hop/providers/profile_provider.dart';

class AccountInformationScreen extends StatefulWidget {
  const AccountInformationScreen({super.key});

  @override
  State<AccountInformationScreen> createState() => _AccountInformationScreenState();
}

class _AccountInformationScreenState extends State<AccountInformationScreen> {

  // Alternate email is loaded from the backend profile data
  String get _alternateEmail {
    final profile = context.read<ProfileProvider>().profileData;
    return (profile?['alternate_email'] as String?) ?? '';
  }

  void _showChangeEmailDialog() {
    final controller = TextEditingController(text: _alternateEmail);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Change Alternate Email"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: "New Alternate Email",
            hintText: "Enter your alternate email",
            prefixIcon: Icon(Icons.alternate_email),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newEmail = controller.text.trim();
              if (newEmail.isNotEmpty && newEmail.contains('@')) {
                Navigator.pop(ctx);
                // Persist alternate email to backend
                final token = context.read<AuthProvider>().accessToken;
                final profileProvider = context.read<ProfileProvider>();
                final existing = profileProvider.profileData;
                if (token != null && existing != null) {
                  await profileProvider.updateProfile(token, {
                    ...existing,
                    'alternate_email': newEmail,
                    'interests': List<String>.from(existing['interests'] ?? []),
                  });
                }
                setState(() {}); // rebuild to show new alternate email
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Alternate email updated successfully!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text("Please enter a valid email address."),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);
    // Use the email saved at login time; fall back to what the profile API returns
    final auth = context.read<AuthProvider>();
    final profileEmail = (context.read<ProfileProvider>().profileData?['email'] as String?);
    final primaryEmail = auth.email ?? profileEmail ?? '';
    final alternateEmail = _alternateEmail;

    return AppScaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            /// HEADER
            Row(
              children: [

                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),

                Expanded(
                  child: Center(
                    child: Text(
                      "Account Information",
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

            /// PRIMARY EMAIL
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mail_outline, color: Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Primary Email (University)",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            "Used for login and verification",
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withOpacity(.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Email + Verified row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(.04),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          primaryEmail,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(.8),
                            fontSize: 13,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 14),
                            const SizedBox(width: 4),
                            const Text(
                              "Verified",
                              style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// ALTERNATE EMAIL
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with subtitle
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.alternate_email, color: Colors.orange),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Alternate Email", style: TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            "Backup for account recovery",
                            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(.5)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Email in its own styled row
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(.04),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      alternateEmail,
                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(.8), fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _showChangeEmailDialog,
                      child: const Text("Change Alternate Email"),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// ABOUT YOUR EMAILS
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.blue.withOpacity(.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [

                  Text(
                    "About Your Emails",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),

                  SizedBox(height: 10),

                  Text(
                    "• Your primary email is used for login and verification.",
                  ),

                  Text(
                    "• Primary email must be your verified university email.",
                  ),

                  Text(
                    "• Alternate email is used for account recovery after graduation.",
                  ),

                  Text(
                    "• You can receive notifications on either email address.",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

