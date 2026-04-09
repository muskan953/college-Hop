import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:college_hop/theme/app_scaffold.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:college_hop/providers/profile_provider.dart';
import 'package:college_hop/providers/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'package:college_hop/utils/pdf_preview_stub.dart'
    if (dart.library.html) 'package:college_hop/utils/pdf_preview_web.dart';

class VerifyStudentIDScreen extends StatefulWidget {
  const VerifyStudentIDScreen({super.key});

  @override
  State<VerifyStudentIDScreen> createState() => _VerifyStudentIDScreenState();
}

class _VerifyStudentIDScreenState extends State<VerifyStudentIDScreen> {

  PlatformFile? selectedPdf;
  bool _isUploading = false;
  bool _isLoadingPreview = false;

  String _getFormattedDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${months[date.month - 1]} ${date.day}, ${date.year}";
  }

  Future<void> _viewIdCard(String idUrl, String token) async {
    setState(() => _isLoadingPreview = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final response = await http.get(
        Uri.parse(idUrl),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        if (kIsWeb) {
          openBlobPdf(response.bodyBytes);
        } else {
          messenger.showSnackBar(
            const SnackBar(content: Text("PDF preview is available on web only.")),
          );
        }
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text("Failed to load ID card."), backgroundColor: Colors.red),
        );
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Error opening ID card."), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoadingPreview = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().profileData;
    final theme = Theme.of(context);
    
    String currentFileName = "No ID uploaded";
    String? uploadedDate;
    String verificationStatus = profile?['status'] as String? ?? '';

    if (profile != null) {
      final idUrl = profile['college_id_card_url'] as String?;
      if (idUrl != null && idUrl.isNotEmpty) {
        currentFileName = "Your Student ID";
      }
      final uploadedAt = profile['id_card_uploaded_at'] as String?;
      if (uploadedAt != null && uploadedAt.isNotEmpty) {
        try {
          final dt = DateTime.parse(uploadedAt).toLocal();
          uploadedDate = _getFormattedDate(dt);
        } catch (_) {}
      }
    }

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

            /// VERIFICATION STATUS BANNER
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: verificationStatus == 'verified'
                    ? Colors.green.withValues(alpha: .12)
                    : Colors.orange.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: verificationStatus == 'verified'
                      ? Colors.green.withValues(alpha: .4)
                      : Colors.orange.withValues(alpha: .4),
                ),
              ),
              child: Row(
                children: [

                  Icon(
                    verificationStatus == 'verified'
                        ? Icons.check_circle
                        : Icons.hourglass_top_rounded,
                    color: verificationStatus == 'verified' ? Colors.green : Colors.orange,
                    size: 28,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          verificationStatus == 'verified'
                              ? "Verification Complete"
                              : "Pending Review",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: verificationStatus == 'verified'
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          verificationStatus == 'verified'
                              ? "Your student ID has been verified. You now have full access to all features."
                              : "Your ID has been submitted and is awaiting admin review. This typically takes 24–48 hours.",
                          style: const TextStyle(fontSize: 13),
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
                  color: theme.colorScheme.outline.withValues(alpha: .15),
                ),
              ),
              child: Row(
                children: [

                  const Icon(Icons.description_outlined),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentFileName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        if (uploadedDate != null) ...
                          [
                            const SizedBox(height: 2),
                            Text(
                              "Uploaded $uploadedDate",
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface.withValues(alpha: .5),
                              ),
                            ),
                          ],
                      ],
                    ),
                  ),

                  // View button — only when an ID is uploaded
                  if ((profile?['college_id_card_url'] as String?)?.isNotEmpty == true) ...[  
                    _isLoadingPreview
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            tooltip: "View ID Card",
                            icon: const Icon(Icons.open_in_new, size: 20),
                            onPressed: () {
                              final token = context.read<AuthProvider>().accessToken;
                              final idUrl = profile!['college_id_card_url'] as String;
                              if (token != null) _viewIdCard(idUrl, token);
                            },
                          ),
                    const SizedBox(width: 4),
                  ],

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: verificationStatus == 'verified'
                          ? Colors.green.withValues(alpha: .12)
                          : Colors.orange.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      verificationStatus == 'verified' ? "Verified" : "Pending Review",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: verificationStatus == 'verified' ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
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
                  color: theme.colorScheme.outline.withValues(alpha: .15),
                ),
              ),
              child: Column(
                children: [

                  Icon(
                    selectedPdf != null 
                        ? Icons.check_circle_outline
                        : Icons.cloud_upload_outlined,
                    size: 40,
                    color: selectedPdf != null ? Colors.green : Colors.blue,
                  ),

                  const SizedBox(height: 10),

                  Text(
                    selectedPdf != null 
                        ? selectedPdf!.name
                        : "Upload Student ID",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600, 
                      color: selectedPdf != null ? Colors.green : null,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    selectedPdf != null
                        ? "File selected. Press \"Upload\" to confirm."
                        : "Tap to browse",
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: .6),
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
                            withData: true,
                          );
                          if (result != null && result.files.isNotEmpty) {
                            setState(() => selectedPdf = result.files.first);
                          }
                        },
                        icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                        label: const Text("Choose PDF"),
                      ),
                      if (selectedPdf != null) ...[
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _isUploading ? null : () async {
                            final token = context.read<AuthProvider>().accessToken;
                            if (token == null) return;
                            
                            setState(() => _isUploading = true);
                            final profileProvider = context.read<ProfileProvider>();
                            final url = await profileProvider.uploadIdCard(
                              token: token,
                              fileName: selectedPdf!.name,
                              filePath: kIsWeb ? null : selectedPdf!.path,
                              fileBytes: selectedPdf!.bytes,
                            );
                            
                            bool profileUpdated = false;
                            if (url != null) {
                              final currentProfile = profileProvider.profileData ?? {};
                              final updatedProfile = Map<String, dynamic>.from(currentProfile);
                              updatedProfile['college_id_card_url'] = url;
                              
                              profileUpdated = await profileProvider.updateProfile(token, updatedProfile);
                            }
                            
                            setState(() {
                              selectedPdf = null;
                              _isUploading = false;
                            });
                            
                            if (mounted) {
                              if (url != null && profileUpdated) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Student ID uploaded successfully!"), backgroundColor: Colors.green),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Upload failed. Please try again."), backgroundColor: Colors.red),
                                );
                              }
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
                      color: theme.colorScheme.onSurface.withValues(alpha: .6),
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
                color: Colors.blue.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: .3),
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
