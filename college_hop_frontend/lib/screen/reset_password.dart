import 'package:college_hop/screen/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:college_hop/theme/app_scaffold.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController newPasswordController =
      TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;

  String strengthText = "Weak";
  Color strengthColor = Colors.red;

  @override
  void initState() {
    super.initState();
    newPasswordController.addListener(_checkStrength);
  }

  void _checkStrength() {
    String password = newPasswordController.text;

    bool hasMinLength = password.length >= 8;
    bool hasUpper = password.contains(RegExp(r'[A-Z]'));
    bool hasLower = password.contains(RegExp(r'[a-z]'));
    bool hasNumber = password.contains(RegExp(r'\d'));
    bool hasSpecial =
        password.contains(RegExp(r'[@$!%*?&]'));

    int score = 0;
    if (hasMinLength) score++;
    if (hasUpper) score++;
    if (hasLower) score++;
    if (hasNumber) score++;
    if (hasSpecial) score++;

    setState(() {
      if (score <= 2) {
        strengthText = "Weak";
        strengthColor = Colors.red;
      } else if (score == 3 || score == 4) {
        strengthText = "Medium";
        strengthColor = Colors.orange;
      } else {
        strengthText = "Strong";
        strengthColor = Colors.green;
      }
    });
  }

  @override
  void dispose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

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

                // Header
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Expanded(
                      child: Text(
                        "Reset your password",
                        textAlign: TextAlign.center,
                        style:
                            theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),

                const SizedBox(height: 8),

                // Subtitle
                Center(
                  child: Text(
                    "Create a strong password to keep your account secure.",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // New password
                Text(
                  "New password",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: newPasswordController,
                  obscureText: _obscureNew,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Password is required";
                    }
                    if (strengthText != "Strong") {
                      return "Password is not strong enough";
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: "Enter new password",
                     hintStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                    ),
                    filled: true,
                    fillColor: theme
                        .colorScheme.surfaceVariant
                        .withOpacity(0.8),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNew
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureNew = !_obscureNew;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Strength indicator
                Row(
                  children: [
                    Text(
                      "Strength: ",
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      strengthText,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(
                        color: strengthColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Confirm password
                Text(
                  "Confirm password",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: _obscureConfirm,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Confirm your password";
                    }
                    if (value !=
                        newPasswordController.text) {
                      return "Passwords do not match";
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: "Re-enter password",
                     hintStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                    ),
                    filled: true,
                    fillColor: theme
                        .colorScheme.surfaceVariant
                        .withOpacity(0.8),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirm =
                              !_obscureConfirm;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Password rules
                _rulesBox(),

                const Spacer(),

                // Reset button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!
                          .validate()) {
                         Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Reset password",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
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

  Widget _rulesBox() {
    final password = newPasswordController.text;

    bool hasMinLength = password.length >= 8;
    bool hasUpper = password.contains(RegExp(r'[A-Z]'));
    bool hasLower = password.contains(RegExp(r'[a-z]'));
    bool hasNumber = password.contains(RegExp(r'\d'));
    bool hasSpecial =
        password.contains(RegExp(r'[@$!%*?&]'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ruleText("At least 8 characters", hasMinLength),
        _ruleText("At least one number", hasNumber),
        _ruleText("At least one special character",
            hasSpecial),
        _ruleText("Upper and lower case letters",
            hasUpper && hasLower),
      ],
    );
  }

  Widget _ruleText(String text, bool isValid) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            isValid
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            size: 18,
            color: isValid
                ? Colors.green
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color:
                  isValid ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }
}
