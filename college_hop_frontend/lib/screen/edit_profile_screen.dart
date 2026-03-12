import 'package:flutter/material.dart';
import 'package:college_hop/theme/app_scaffold.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {

  final nameController = TextEditingController(text: "Arjun Mehta");
  final locationController = TextEditingController(text: "Delhi, India");
  final bioController = TextEditingController();
  final universityController =
      TextEditingController(text: "Indian Institute of Technology Delhi");
  final majorController =
      TextEditingController(text: "Computer Science & Engineering");
 
  Uint8List? profileImageBytes;
 final ImagePicker picker = ImagePicker();
 
 Future<void> pickProfileImage() async {
  final XFile? image =
      await picker.pickImage(source: ImageSource.gallery);

  if (image != null) {
    final bytes = await image.readAsBytes();

    setState(() {
      profileImageBytes = bytes;
    });
  }
}
  String expirationDate = "June 11, 2027";
 
  TextEditingController newExpirationController = TextEditingController();
  PlatformFile? selectedPdf; 

  List<String> interests = [
    "Programming",
    "Design",
    "Startups",
    "Gaming",
    "Music",
    "Reading",
    "Movies"
  ];

  List<String> selectedInterests = [
    "Programming",
    "Startups",
    "Gaming"
  ];

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
                  onPressed: () {},
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
      ? MemoryImage(profileImageBytes!)
      : null,
  child: profileImageBytes == null
      ? const Text(
          "AM",
          style: TextStyle(
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
            color: Colors.white.withOpacity(.6),
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

                    backgroundColor: Colors.white.withOpacity(.08),

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
            Colors.white.withOpacity(.08),
            Colors.white.withOpacity(.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(.08),
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
              color: Colors.white.withOpacity(.65),
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
              fillColor: Colors.white.withOpacity(.08),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(.15),
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
              color: Colors.white.withOpacity(.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(.12),
              ),
            ),
            child: Row(
              children: [

                Expanded(
                  child: Text(
                    expirationDate,
                    style: TextStyle(
                      color: Colors.white.withOpacity(.75),
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
            color: Colors.white.withOpacity(.6),
          ),
        ),
      ],
    );
  }

////////////////////////////////////////////////////////////
/// UPDATE STUDENT ID DIALOG
////////////////////////////////////////////////////////////

 void showUpdateStudentIDDialog() {

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
                  color: Colors.white.withOpacity(.08),
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
                        color: Colors.white.withOpacity(.7),
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      "Current Expiration Date",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(.7),
                      ),
                    ),

                    const SizedBox(height: 6),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(expirationDate),
                    ),
                    const SizedBox(height: 14),

Text(
  "New Expiration Date",
  style: TextStyle(
    fontSize: 12,
    color: Colors.white.withOpacity(.7),
  ),
),

const SizedBox(height: 6),

TextField(
  controller: newExpirationController,
  style: TextStyle(color: Colors.grey.shade700),
  decoration: InputDecoration(
    hintText: "Enter new expiration date",
    hintStyle: TextStyle(color: Colors.grey.shade600),
    filled: true,
    fillColor: Colors.white.withOpacity(.08),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: Colors.white.withOpacity(.15),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 14,
    ),
  ),
),

                    const SizedBox(height: 16),

                    Text(
                      "Upload New Student ID (PDF)",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(.7),
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
                        );

                        if (result != null) {

                          selectedPdf = result.files.first;

                          setStateDialog(() {}); // update dialog UI
                        }
                      },
                      child: Container(
                        height: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(.15),
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
                            onPressed: () {

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