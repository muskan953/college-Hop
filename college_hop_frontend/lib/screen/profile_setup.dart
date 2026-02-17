import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:college_hop/providers/auth_provider.dart';
import 'package:college_hop/providers/signup_provider.dart';
import 'package:college_hop/services/api_service.dart';
import 'package:college_hop/theme/app_scaffold.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
}

class _ProfileSetupScreenState
    extends State<ProfileSetupScreen> {
  final TextEditingController bioController =
      TextEditingController();
  final TextEditingController interestController =
      TextEditingController();

  final List<String> interests = [
    "Programming",
    "Design",
    "Startups",
    "Gaming",
    "Music",
    "Reading",
    "Movies",
  ];

  final Set<String> selectedInterests = {};
  File? profileImage;
  bool isLoading = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage() async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        profileImage = File(image.path);
      });
    }
  }

  void addCustomInterest() {
    String text = interestController.text.trim();
    if (text.isNotEmpty && !interests.contains(text)) {
      setState(() {
        interests.add(text);
        selectedInterests.add(text);
      });
      interestController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Title
              Text(
                "Set up your profile",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              // Profile photo
              GestureDetector(
                onTap: pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor:
                          theme.colorScheme.surfaceVariant,
                      backgroundImage: profileImage != null
                          ? FileImage(profileImage!)
                          : null,
                      child: profileImage == null
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.edit,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Text(
                "Upload Photo",
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              Text(
                "Tap to choose from library",
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      theme.colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 24),

              // Bio
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Bio",
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: bioController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText:
                      "Tell us about yourself in 2 lines...",
                  filled: true,
                  fillColor: theme
                      .colorScheme.surfaceVariant
                      .withOpacity(0.8),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Interest input
              TextField(
                controller: interestController,
                onSubmitted: (_) => addCustomInterest(),
                decoration: InputDecoration(
                  hintText:
                      "Type an interest",
                  filled: true,
                  fillColor: theme
                      .colorScheme.surfaceVariant
                      .withOpacity(0.8),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Interest chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: interests.map((interest) {
                  final isSelected =
                      selectedInterests.contains(
                          interest);

                  return ChoiceChip(
                    label: Text(interest),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          selectedInterests
                              .add(interest);
                        } else {
                          selectedInterests
                              .remove(interest);
                        }
                      });
                    },
                    selectedColor:
                        theme.colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : theme
                              .colorScheme.onSurface,
                    ),
                    backgroundColor:
                        theme.colorScheme.surfaceVariant,
                  );
                }).toList(),
              ),

              const Spacer(),

              // Finish button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() => isLoading = true);

                          final authProvider = Provider.of<AuthProvider>(context, listen: false);
                          final token = authProvider.accessToken;

                          if (token == null) {
                            setState(() => isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Not authenticated. Please log in again.")),
                            );
                            return;
                          }

                          try {
                            final signUpProvider = Provider.of<SignUpProvider>(context, listen: false);

                            // Merge signup data with profile setup data
                            final profileData = signUpProvider.toProfilePayload();
                            profileData["bio"] = bioController.text.trim();
                            profileData["interests"] = selectedInterests.toList();

                            final res = await ApiService.updateProfile(token, profileData);

                            setState(() => isLoading = false);

                            if (res.statusCode == 200) {
                              signUpProvider.reset();
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => AlertDialog(
                                  title: const Text("Profile Complete!"),
                                  content: const Text("Your profile has been set up successfully."),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        // TODO: Navigate to home/dashboard when available
                                      },
                                      child: const Text("OK"),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Failed to save profile: ${res.body}")),
                              );
                            }
                          } catch (e) {
                            setState(() => isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: $e")),
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
                    "Finish setup",
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
    );
  }
}
