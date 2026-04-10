import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:college_hop/theme/app_scaffold.dart';
import 'package:college_hop/providers/auth_provider.dart';
import 'package:college_hop/providers/profile_provider.dart';
import 'package:college_hop/services/api_service.dart';

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
    final emailController = TextEditingController(text: _alternateEmail);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Change Alternate Email"),
        content: TextField(
          controller: emailController,
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
            onPressed: () {
              final newEmail = emailController.text.trim();
              if (newEmail.isNotEmpty && newEmail.contains('@')) {
                Navigator.pop(ctx);
                _requestOTPAndVerify(newEmail);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text("Please enter a valid email address."),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Send OTP"),
          ),
        ],
      ),
    );
  }

  Future<void> _requestOTPAndVerify(String email) async {
    final token = context.read<AuthProvider>().accessToken;
    if (token == null) return;

    // Request OTP
    final res = await ApiService.requestAlternateEmailOTP(token, email);
    if (!mounted) return;

    if (res.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.statusCode == 429
              ? "Please wait before requesting another OTP."
              : "Failed to send OTP. Try again."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show OTP input dialog
    _showOTPDialog(email);
  }

  void _showOTPDialog(String email) {
    final otpController = TextEditingController();
    bool verifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text("Verify OTP"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "We sent a verification code to\n$email",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, letterSpacing: 8),
                decoration: const InputDecoration(
                  hintText: "000000",
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: verifying ? null : () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: verifying
                  ? null
                  : () async {
                      final otp = otpController.text.trim();
                      if (otp.length != 6) return;

                      setDialogState(() => verifying = true);

                      final token = context.read<AuthProvider>().accessToken;
                      if (token == null) return;

                      final res = await ApiService.verifyAlternateEmail(token, email, otp);

                      if (!mounted) return;
                      Navigator.pop(ctx);

                      if (res.statusCode == 200) {
                        // Refresh profile to show new email
                        await context.read<ProfileProvider>().fetchProfile(token);
                        if (mounted) {
                          setState(() {}); // rebuild
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Alternate email verified and saved!"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Invalid or expired OTP. Try again."),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              child: verifying
                  ? const SizedBox(
                      height: 16, width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Verify"),
            ),
          ],
        ),
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
                  color: theme.colorScheme.outline.withValues(alpha: .15),
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
                          color: Colors.blue.withValues(alpha: .15),
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
                              color: theme.colorScheme.onSurface.withValues(alpha: .5),
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
                      color: theme.colorScheme.onSurface.withValues(alpha: .04),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          primaryEmail,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(alpha: .8),
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
                  color: theme.colorScheme.outline.withValues(alpha: .15),
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
                          color: Colors.orange.withValues(alpha: .15),
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
                            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: .5)),
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
                      color: theme.colorScheme.onSurface.withValues(alpha: .04),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            alternateEmail.isEmpty ? 'Not set' : alternateEmail,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(alpha: alternateEmail.isEmpty ? .4 : .8),
                              fontSize: 13,
                              fontStyle: alternateEmail.isEmpty ? FontStyle.italic : FontStyle.normal,
                            ),
                          ),
                        ),
                        if (alternateEmail.isNotEmpty) ...[
                          const Icon(Icons.check_circle, color: Colors.green, size: 14),
                          const SizedBox(width: 4),
                          const Text(
                            "Verified",
                            style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _showChangeEmailDialog,
                      child: Text(alternateEmail.isEmpty ? "Add Alternate Email" : "Change Alternate Email"),
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
                color: Colors.blue.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: .25),
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
                    "• Alternate email is verified via OTP to ensure you own it.",
                  ),

                  Text(
                    "• You can log in using either your primary or alternate email.",
                  ),

                  Text(
                    "• Alternate email is used for account recovery after graduation.",
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
