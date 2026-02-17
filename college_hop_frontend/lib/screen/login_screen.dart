import 'package:college_hop/screen/verify_otp.dart';
import 'package:flutter/material.dart';
import 'package:college_hop/theme/app_scaffold.dart';
import 'package:college_hop/services/api_service.dart';
import 'sign_up1.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                SizedBox(
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.school,
                          size: 40,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Subtitle
                Center(
                  child: Text(
                    "Welcome back! Log in to continue.",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Email
                Text("College Email",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    )),
                const SizedBox(height: 6),
                TextFormField(
                  controller: emailController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Email is required";
                    }
                    if (!value.contains("@")) {
                      return "Enter a valid email";
                    }
                     final domain = value.split('@').last.toLowerCase();

                     // Blacklisted domains
                      const blockedDomains = [
                       'gmail.com',
                       'yahoo.com',
                       'outlook.com',
                       'hotmail.com',
                       'icloud.com',
                       'proton.me',
                       'zoho.com',
                       ];

                       if (blockedDomains.contains(domain)) {
                        return "Use your college email address";
                       }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: "jane@university.edu",
                     hintStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                    ),
                    filled: true,
                    fillColor:
                        theme.colorScheme.surfaceVariant.withOpacity(0.8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),


                const SizedBox(height: 16),


                const Spacer(),

                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() => isLoading = true);
                              try {
                                final res = await ApiService.login(emailController.text);
                                setState(() => isLoading = false);

                                if (res.statusCode == 200) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => VerifyOtpScreen(email: emailController.text),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(res.body)),
                                  );
                                }
                              } catch (e) {
                                setState(() => isLoading = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Connection failed. Is the backend running?")),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Log In",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 8),

                 Center(
  child: TextButton(
    onPressed: () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const SignUpStep1(),
        ),
      );
    },
    child: RichText(
      text: TextSpan(
        style: theme.textTheme.bodyMedium,
        children: [
          TextSpan(
            text: "Don't have an account? ",
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: "Sign In",
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  ),
),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
