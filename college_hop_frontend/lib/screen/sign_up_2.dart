import 'package:college_hop/screen/sign_up_3.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:college_hop/providers/signup_provider.dart';
import 'package:college_hop/theme/app_scaffold.dart';

class SignUpStep2 extends StatefulWidget {
  const SignUpStep2({super.key});

  @override
  State<SignUpStep2> createState() => _SignUpStep2State();
}

class _SignUpStep2State extends State<SignUpStep2> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController collegeController = TextEditingController();
  final TextEditingController majorController = TextEditingController();
  final TextEditingController rollController = TextEditingController();
  final TextEditingController expiryController = TextEditingController();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        expiryController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
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

                // Header with centered title
                SizedBox(
                  height: 48,
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
                      Text(
                        "Your academic details",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  "Help us personalize your experience",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 32),

                // College name
                Text(
                  "College name",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: collegeController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "College name is required";
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: "Enter your college name",
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

                // Major
                Text(
                  "Major / field of study",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: majorController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Major is required";
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: "Enter your major",
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

                // Roll number
                Text(
                  "Roll / enrollment number",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: rollController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Roll number is required";
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: "Enter your roll number",
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

                // Expiry date
                Text(
                  "ID card expiration date",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: expiryController,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Expiration date is required";
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: "mm/dd/yyyy",
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                    ),
                    filled: true,
                    fillColor:
                        theme.colorScheme.surfaceVariant.withOpacity(0.8),
                    suffixIcon: const Icon(Icons.calendar_today, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const Spacer(),

                // Continue buttons
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final signUp = Provider.of<SignUpProvider>(context, listen: false);
                        signUp.updateStep2(
                          collegeName: collegeController.text.trim(),
                          major: majorController.text.trim(),
                          rollNumber: rollController.text.trim(),
                          idExpiration: expiryController.text.trim(),
                        );
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SignUpStep3(),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Continue",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Step indicator at bottom
                Center(
                  child: Text(
                    "Step 2 of 4",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
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
