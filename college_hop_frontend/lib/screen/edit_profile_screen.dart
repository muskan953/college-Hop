import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:college_hop/theme/app_scaffold.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:provider/provider.dart';
import 'package:college_hop/providers/auth_provider.dart';
import 'package:college_hop/providers/profile_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {

  final nameController = TextEditingController();
  final locationController = TextEditingController();
  final bioController = TextEditingController();
  final universityController = TextEditingController();
  final majorController = TextEditingController();

  // ID Card Upload state
  String? _uploadedIdCardUrl; // set once upload succeeds
  bool _idCardUploaded = false; // unlocks expiration date field
  String? _uploadedPhotoUrl;   // set after photo upload

  Uint8List? profileImageBytes;
  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Pre-fill controllers with existing profile data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = context.read<ProfileProvider>().profileData;
      if (profile != null) {
        nameController.text = (profile['full_name'] as String?) ?? '';
        locationController.text = (profile['location'] as String?) ?? '';
        bioController.text = (profile['bio'] as String?) ?? '';
        universityController.text = (profile['college_name'] as String?) ?? '';
        majorController.text = (profile['major'] as String?) ?? '';
        expirationDate = (profile['id_expiration'] as String?) ?? 'Not set';
        selectedInterests = List<String>.from((profile['interests'] as List?) ?? []);
        setState(() {});
      }
    });
  }

  Future<void> pickProfileImage() async {
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => profileImageBytes = bytes);
      // Upload immediately
      final token = context.read<AuthProvider>().accessToken;
      if (token != null) {
        final url = await context.read<ProfileProvider>().uploadProfilePhoto(
          token: token,
          fileName: image.name,
          filePath: kIsWeb ? null : image.path,
          fileBytes: bytes,
        );
        if (url != null) {
          setState(() => _uploadedPhotoUrl = url);
        }
      }
    }
  }

  String expirationDate = 'Not set';
  TextEditingController newExpirationController = TextEditingController();
  PlatformFile? selectedPdf;

  Future<void> pickPDF() async {

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        selectedPdf = result.files.first;
      });
    }
  }

  final List<String> interests = [
    "Programming", "Design", "Startups", "Gaming",
    "Music", "Reading", "Movies", "Travel", "Sports",
    "Photography", "Food", "Art",
  ];

  List<String> selectedInterests = [];

  Future<void> _saveProfile() async {
    final token = context.read<AuthProvider>().accessToken;
    if (token == null) return;

    final profileProvider = context.read<ProfileProvider>();
    final existing = profileProvider.profileData;

    final success = await profileProvider.updateProfile(token, {
      'full_name': nameController.text.trim(),
      'college_name': universityController.text.trim(),
      'major': majorController.text.trim(),
      'roll_number': existing?['roll_number'] ?? '',
      'id_expiration': expirationDate == 'Not set' ? (existing?['id_expiration'] ?? '') : expirationDate,
      'bio': bioController.text.trim(),
      'profile_photo_url': _uploadedPhotoUrl ?? existing?['profile_photo_url'] ?? '',
      'college_id_card_url': _uploadedIdCardUrl ?? existing?['college_id_card_url'] ?? '',
      'alternate_email': existing?['alternate_email'] ?? '',
      'interests': selectedInterests,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Profile updated!' : 'Failed to save. Try again.')),
      );
      if (success) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

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
                      "Edit Profile",
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                TextButton(
          onPressed: _saveProfile,
          child: const Text("Save"),
        )
              ],
            ),

            const SizedBox(height: 20),

            /// PROFILE IMAGE
             Center(
  child: Column(
    children: [
      GestureDetector(
        onTap: pickProfileImage,
        child: CircleAvatar(
          radius: 42,
          backgroundColor: theme.colorScheme.primary,
          backgroundImage: profileImageBytes != null
              ? MemoryImage(profileImageBytes!) as ImageProvider
              : (_uploadedPhotoUrl != null && _uploadedPhotoUrl!.isNotEmpty
                  ? NetworkImage(_uploadedPhotoUrl!) as ImageProvider
                  : null),
          child: (profileImageBytes == null && (_uploadedPhotoUrl == null || _uploadedPhotoUrl!.isEmpty))
              ? Text(
                  nameController.text.isNotEmpty
                      ? nameController.text.trim().split(' ').map((e) => e[0]).take(2).join()
                      : 'ME',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
      ),

      const SizedBox(height: 6),

      GestureDetector(
        onTap: pickProfileImage,
        child: Text(
          "Tap to change photo",
          style: TextStyle(
            color: Colors.white.withValues(alpha: .6),
          ),
        ),
      ),
    ],
  ),
),

            const SizedBox(height: 24),

            /// BASIC INFORMATION
            sectionCard("Basic Information", [

              inputField("Full Name", nameController),

              inputField("Location", locationController),

              inputField("Bio", bioController, maxLines: 3),

            ]),

            const SizedBox(height: 16),

            /// EDUCATION
            sectionCard("Education", [

              inputField("University", universityController),

              inputField("Major", majorController),

              const SizedBox(height: 12),

              expirationDateField(),

            ]),

            const SizedBox(height: 16),

            /// SELECT INTERESTS
            sectionCard("Select Interests", [

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: interests.map((interest) {

                  final isSelected =
                      selectedInterests.contains(interest);

                  return ChoiceChip(
                    label: Text(interest),

                    selected: isSelected,

                    selectedColor: theme.colorScheme.primary,

                    backgroundColor: Colors.white.withValues(alpha: .08),

                    labelStyle: TextStyle(
                      color:
                          isSelected ? Colors.white : Colors.white70,
                    ),

                    onSelected: (value) {

                      setState(() {

                        if (isSelected) {
                          selectedInterests.remove(interest);
                        } else {
                          selectedInterests.add(interest);
                        }

                      });

                    },
                  );

                }).toList(),
              )

            ]),

            const SizedBox(height: 40)
          ],
        ),
      ),
    );
  }

////////////////////////////////////////////////////////////
/// CARD SECTION
////////////////////////////////////////////////////////////

  Widget sectionCard(String title, List<Widget> children) {

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: .08),
            Colors.white.withValues(alpha: .04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: .08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 14),

          ...children
        ],
      ),
    );
  }

////////////////////////////////////////////////////////////
/// INPUT FIELD
////////////////////////////////////////////////////////////

  Widget inputField(
      String label,
      TextEditingController controller,
      {int maxLines = 1}) {

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .65),
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 6),

          TextField(
            controller: controller,
            maxLines: maxLines,
            style: TextStyle(
              color: Color(0xFF9CA3AF),
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withValues(alpha: .08),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: .15),
                ),
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                ),
              ),

              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

////////////////////////////////////////////////////////////
/// EXPIRATION FIELD
////////////////////////////////////////////////////////////

  Widget expirationDateField() {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Text(
          "Student ID Expiration Date",
          style: TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 6),

        GestureDetector(
          onTap: showUpdateStudentIDDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: .12),
              ),
            ),
            child: Row(
              children: [

                Expanded(
                  child: Text(
                    expirationDate,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .75),
                    ),
                  ),
                ),

                const Icon(Icons.calendar_today, size: 18)
              ],
            ),
          ),
        ),

        const SizedBox(height: 6),

        Text(
          "Changing this requires uploading a new student ID",
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: .6),
          ),
        ),
      ],
    );
  }

////////////////////////////////////////////////////////////
/// UPDATE STUDENT ID DIALOG
////////////////////////////////////////////////////////////

 void showUpdateStudentIDDialog() {
  newExpirationController.clear();
  selectedPdf = null;

  showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) {

      return StatefulBuilder(
        builder: (context, setStateDialog) {

          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1E2433),
                    Color(0xFF2A3145),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .08),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      "Update Student ID",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "Upload a new student ID to update expiration date.",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .7),
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      "Current Expiration Date",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: .7),
                      ),
                    ),

                    const SizedBox(height: 6),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(expirationDate),
                    ),
                    const SizedBox(height: 14),

Text(
  "New Expiration Date",
  style: TextStyle(
    fontSize: 12,
    color: Colors.white.withValues(alpha: .7),
  ),
),

const SizedBox(height: 6),

GestureDetector(
  onTap: () async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      final formattedDate = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
      setStateDialog(() {
        newExpirationController.text = formattedDate;
      });
    }
  },
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: Colors.white.withValues(alpha: .15),
      ),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            newExpirationController.text.isNotEmpty 
                ? newExpirationController.text 
                : "Select new expiration date",
            style: TextStyle(
              color: newExpirationController.text.isNotEmpty 
                  ? Colors.white 
                  : Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ),
        Icon(Icons.calendar_today, size: 18, color: Colors.white.withValues(alpha: 0.6)),
      ],
    ),
  ),
),

                    const SizedBox(height: 16),

                    Text(
                      "Upload New Student ID (PDF)",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: .7),
                      ),
                    ),

                    const SizedBox(height: 8),

                    /// PDF PICKER
                    GestureDetector(
                      onTap: () async {

                        FilePickerResult? result =
                            await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['pdf'],
                          withData: true,
                        );

                        if (result != null && result.files.isNotEmpty) {

                          selectedPdf = result.files.first;

                          setStateDialog(() {}); // update dialog UI
                        }
                      },
                      child: Container(
                        height: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .15),
                          ),
                        ),
                        child: Center(
                          child: selectedPdf == null
                              ? const Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.upload_file),
                                    SizedBox(height: 6),
                                    Text("Tap to upload PDF"),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.picture_as_pdf,
                                        color: Colors.red),
                                    const SizedBox(height: 6),
                                    Text(
                                      selectedPdf!.name,
                                      style:
                                          const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [

                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text("Cancel"),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {

                              if (selectedPdf == null) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        "Please upload student ID PDF"),
                                  ),
                                );
                                
                                return;
                              }

                              // Upload the ID card
                              final token = context.read<AuthProvider>().accessToken;
                              if (token != null && selectedPdf != null) {
                                final url = await context.read<ProfileProvider>().uploadIdCard(
                                  token: token,
                                  fileName: selectedPdf!.name,
                                  filePath: kIsWeb ? null : selectedPdf!.path,
                                  fileBytes: selectedPdf!.bytes,
                                );
                                if (url != null) {
                                  setState(() {
                                    _uploadedIdCardUrl = url;
                                    _idCardUploaded = true;
                                    if (newExpirationController.text.isNotEmpty) {
                                      expirationDate = newExpirationController.text;
                                    }
                                  });
                                  // ignore: use_build_context_synchronously
                                  Navigator.pop(context);
                                  return;
                                } else {
                                  // ignore: use_build_context_synchronously
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Upload failed. Please try again.')),
                                  );
                                  return;
                                }
                              }

                              if (newExpirationController.text.isNotEmpty) {
                                setState(() {
                                  expirationDate = newExpirationController.text;
                                });
                              }
                              Navigator.pop(context);
                            },
                            child: const Text("Confirm & Update"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
}
