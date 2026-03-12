import 'package:flutter/material.dart';
import 'package:college_hop/theme/app_scaffold.dart';
import 'package:file_picker/file_picker.dart';

class SubmitEventScreen extends StatefulWidget {
  const SubmitEventScreen({super.key});

  @override
  State<SubmitEventScreen> createState() => _SubmitEventScreenState();
}

class _SubmitEventScreenState extends State<SubmitEventScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController organizerController = TextEditingController();
  final TextEditingController eventNameController = TextEditingController();
  final TextEditingController venueController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  final TextEditingController eventLinkController = TextEditingController();
  final TextEditingController ticketLinkController = TextEditingController();

  String? selectedCategory;
  DateTime? startDate;
  DateTime? endDate;
  String? brochureName;

  final List<String> categories = [
    "Hackathon",
    "Workshop",
    "Conference",
    "Tech Fest",
    "Seminar"
  ];

  Future<void> pickBrochure() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        brochureName = result.files.single.name;
      });
    }
  }

  Future<void> pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final labelStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );

    return AppScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HEADER
                Row(
                  children: [
                    IconButton(
                      icon: 
                       Icon(Icons.arrow_back,
                          color: colors.onSurface),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        "Submit New Event",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 40)
                  ],
                ),

                const SizedBox(height: 6),

                Text(
                  "Add an event for students to discover and attend",
                  style: theme.textTheme.bodySmall,
                ),

                const SizedBox(height: 20),

                /// ORGANIZER
                _inputField(
                  context: context,
                  controller: organizerController,
                  label: "Organizer Name",
                  hint: "e.g., College Events Inc.",
                   hintStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                    ),
                  
                ),

                const SizedBox(height: 16),

                /// EVENT NAME
                _inputField(
                  context: context,
                  controller: eventNameController,
                  label: "Event Name",
                  hint: "e.g., Hackathon @ IIT Delhi",
                   hintStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                    ),
                ),

                const SizedBox(height: 16),

                /// CATEGORY
                Text("Category", style: labelStyle),
                const SizedBox(height: 8),

                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: categories
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value;
                    });
                  },
                  decoration: _inputDecoration(context),
                ),

                const SizedBox(height: 16),

                /// VENUE
                _inputField(
                  context: context,
                  controller: venueController,
                  label: "Venue",
                  hint: "Venue name",
                   hintStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                    ),
                  icon: Icons.location_on_outlined,
                ),

                const SizedBox(height: 16),

                /// START & END DATE
                Row(
                  children: [
                    Expanded(
                      child: _dateField(
                        context: context,
                        label: "Start Date",
                        date: startDate,
                        onTap: () => pickDate(true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _dateField(
                        context: context,
                        label: "End Date",
                        date: endDate,
                        onTap: () => pickDate(false),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                /// TIME
                _inputField(
                  context: context,
                  controller: timeController,
                  label: "Time",
                  hint: "e.g., 6:00 PM - 11:00 PM",
                   hintStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                    ),
                  icon: Icons.access_time,
                ),

                const SizedBox(height: 20),

                /// BROCHURE
                Text("Official Brochure", style: labelStyle),
                const SizedBox(height: 8),

                GestureDetector(
                  onTap: pickBrochure,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: colors.outline.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.description_outlined,
                            size: 30, color: colors.primary),
                        const SizedBox(height: 8),
                        Text(
                          brochureName ?? "Upload PDF brochure",
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Max 15MB",
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                /// EVENT LINK
                _inputField(
                  context: context,
                  controller: eventLinkController,
                  label: "Official Event Link",
                  hint: "https://event-website.com",
                   hintStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                    ),
                  icon: Icons.link,
                ),

                const SizedBox(height: 16),

                /// TICKET LINK
                _inputField(
                  context: context,
                  controller: ticketLinkController,
                  label: "Ticket Purchase Link (Optional)",
                  hint: "https://tickets.com",
                   hintStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                    ),
                  icon: Icons.link,
                ),

                const SizedBox(height: 20),

                /// INFO BOX
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: colors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "All submitted events will be reviewed within 24-48 hours. You'll receive a notification once approved.",
                          style: theme.textTheme.bodySmall,
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                /// SUBMIT BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
  print("Submit button pressed");
},
                    child: const Text(
                      "Submit Event for Review",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// INPUT DECORATION
  InputDecoration _inputDecoration(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InputDecoration(
      filled: true,
      fillColor: colors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.outline.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.outline.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.primary),
      ),
    );
  }

  /// INPUT FIELD
  Widget _inputField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String hint,
    TextStyle? hintStyle,
    IconData? icon,
  }) {
    final labelStyle =
        Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: _inputDecoration(context).copyWith(
            hintText: hint,
            hintStyle: hintStyle,
            prefixIcon: icon != null ? Icon(icon) : null,
          ),
        ),
      ],
    );
  }

  /// DATE FIELD
  Widget _dateField({
    required BuildContext context,
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;

    final labelStyle =
        Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 48,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.outline.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 18, color: colors.onSurface),
                const SizedBox(width: 10),
                Text(
                  date == null
                      ? "Select"
                      : "${date.day}/${date.month}/${date.year}",
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}