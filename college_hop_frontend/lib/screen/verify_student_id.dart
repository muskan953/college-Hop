import 'package:flutter/material.dart';
import 'package:college_hop/theme/app_scaffold.dart';
import 'package:file_picker/file_picker.dart';

class VerifyStudentIDScreen extends StatefulWidget {
  const VerifyStudentIDScreen({super.key});

  @override
  State<VerifyStudentIDScreen> createState() => _VerifyStudentIDScreenState();
}

class _VerifyStudentIDScreenState extends State<VerifyStudentIDScreen> {

  String fileName = "student_id.jpg";
  String? newlyPickedFileName;
  bool _isUploading = false;

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
                      "Verify Student ID",
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

            /// VERIFICATION STATUS
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.green.withOpacity(.4),
                ),
              ),
              child: Row(
                children: [

                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 28,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [

                        Text(
                          "Verification Complete",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),

                        SizedBox(height: 2),

                        Text(
                          "Your student ID has been verified. You now have full access to all features.",
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// CURRENT STUDENT ID
            Text(
              "Current Student ID",
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(.15),
                ),
              ),
              child: Row(
                children: [

                  const Icon(Icons.description_outlined),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(fileName),
                  ),

                  Text(
                    "Uploaded Jan 15, 2025",
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(.6),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// UPLOAD NEW ID
            Text(
              "Upload New ID",
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(.15),
                ),
              ),
              child: Column(
                children: [

                  Icon(
                    newlyPickedFileName != null 
                        ? Icons.check_circle_outline
                        : Icons.cloud_upload_outlined,
                    size: 40,
                    color: newlyPickedFileName != null ? Colors.green : Colors.blue,
                  ),

                  const SizedBox(height: 10),

                  Text(
                    newlyPickedFileName != null 
                        ? newlyPickedFileName!
                        : "Upload Student ID",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600, 
                      color: newlyPickedFileName != null ? Colors.green : null,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    newlyPickedFileName != null
                        ? "File selected. Press \"Upload\" to confirm."
                        : "Tap to browse",
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(.6),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['pdf'],
                          );
                          if (result != null) {
                            setState(() => newlyPickedFileName = result.files.first.name);
                          }
                        },
                        icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                        label: const Text("Choose PDF"),
                      ),
                      if (newlyPickedFileName != null) ...[
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _isUploading ? null : () async {
                            setState(() => _isUploading = true);
                            await Future.delayed(const Duration(seconds: 2)); // Simulate upload
                            setState(() {
                              fileName = newlyPickedFileName!;
                              newlyPickedFileName = null;
                              _isUploading = false;
                            });
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Student ID uploaded successfully!"), backgroundColor: Colors.green),
                              );
                            }
                          },
                          icon: _isUploading 
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.upload, size: 16),
                          label: Text(_isUploading ? "Uploading..." : "Upload"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        ),
                      ]
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Supports PDF only (Max 5MB)",
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withOpacity(.6),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// GUIDELINES
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.blue.withOpacity(.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
                    children: const [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 6),
                      Text(
                        "Verification Guidelines",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  const Text("• Upload a clear photo of your valid student ID"),
                  const Text("• Make sure all text is readable and not blurry"),
                  const Text("• Your ID must show your name and university"),
                  const Text("• Verification typically takes 24-48 hours"),
                  const Text("• Your information is kept secure and confidential"),
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