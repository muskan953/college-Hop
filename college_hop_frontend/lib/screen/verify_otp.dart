import 'dart:async';
import 'package:college_hop/mainn_screen.dart';
import 'package:college_hop/screen/public_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:college_hop/providers/auth_provider.dart';
import 'package:college_hop/services/api_service.dart';
import 'package:college_hop/theme/app_scaffold.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;
  const VerifyOtpScreen({super.key, required this.email});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  bool isLoading = false;
  final List<TextEditingController> controllers =
      List.generate(6, (_) => TextEditingController());

  final List<FocusNode> focusNodes =
      List.generate(6, (_) => FocusNode());

  int secondsRemaining = 40;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    timer?.cancel();
    secondsRemaining = 40;

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (secondsRemaining == 0) {
        t.cancel();
      } else {
        setState(() {
          secondsRemaining--;
        });
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    for (var c in controllers) {
      c.dispose();
    }
    for (var f in focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onOtpChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      focusNodes[index + 1].requestFocus();
    }
  }

  String get timerText {
    final seconds = secondsRemaining.toString().padLeft(2, '0');
    return "00:$seconds";
  }

  /// Determines the post-login destination, honoring any pending deep link.
  Widget _postLoginDestination(AuthProvider auth) {
    final deepLink = auth.consumePendingDeepLink();
    if (deepLink != null) {
      final match = RegExp(r'^/profile/([^/]+)$').firstMatch(deepLink);
      if (match != null) {
        return PublicProfileScreen(userId: match.group(1)!);
      }
    }
    return const MainnScreen();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Header: back arrow + centered title
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Text(
                      "Verify your email",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),

              const SizedBox(height: 8),

              // Centered subtitle
              Center(
                child: Text(
                  "We've sent a 6-digit verification code to\nyour email. Enter the code below to verify your email.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // OTP boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 48,
                    height: 56,
                    child: TextField(
                      controller: controllers[index],
                      focusNode: focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      decoration: InputDecoration(
                        counterText: "",
                        filled: true,
                        fillColor: theme.colorScheme.surfaceVariant
                            .withValues(alpha: 0.8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) =>
                          _onOtpChanged(index, value),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 16),

              // Resend timer
              Center(
                child: secondsRemaining > 0
                    ? Text(
                        "Resend code in $timerText",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    : TextButton(
                        onPressed: () async {
                          startTimer();
                          try {
                            final res = await ApiService.login(widget.email);
                            if (mounted) {
                              if (res.statusCode == 200) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("A new verification code has been sent")),
                                );
                              } else if (res.statusCode == 429) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Please wait before requesting another code")),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Failed to resend code: ${res.body}")),
                                );
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Connection failed. Please try again.")),
                              );
                            }
                          }
                        },
                        child: Text(
                          "Resend Code",
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),

              const Spacer(),

              // Verify button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          bool isOtpComplete = controllers.every((controller) => controller.text.isNotEmpty);

                          if (!isOtpComplete) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please enter the complete 6-digit OTP")),
                            );
                            return;
                          }

                          String otp = controllers.map((c) => c.text).join();
                          setState(() => isLoading = true);

                          final authProvider = Provider.of<AuthProvider>(context, listen: false);
                          final success = await authProvider.verify(widget.email, otp);

                          setState(() => isLoading = false);

                          if (success) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (context) => _postLoginDestination(authProvider)),
                              (route) => false,
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Invalid or expired OTP")),
                            );
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
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          "Verify",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                ),
              ),

              const SizedBox(height: 8),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

