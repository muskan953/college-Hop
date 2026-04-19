import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:college_hop/providers/auth_provider.dart';
import 'package:college_hop/services/api_service.dart';
import 'package:college_hop/screen/group_details_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form Fields
  String? _selectedEventId;
  String _name = '';
  String _description = '';
  int _maxMembers = 4;
  String _meetingPoint = '';
  DateTime? _departureDate;
  bool _requiresApproval = false;

  // Metadata
  bool _isLoadingEvents = true;
  bool _isSpecifyingGroup = false;
  List<Map<String, dynamic>> _myEvents = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchMyEvents();
  }

  Future<void> _fetchMyEvents() async {
    final token = context.read<AuthProvider>().accessToken;
    if (token == null) {
      if (mounted) setState(() { _error = 'Please log in.'; _isLoadingEvents = false; });
      return;
    }

    try {
      final res = await ApiService.getUserEvents(token);
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _myEvents = list.cast<Map<String, dynamic>>();
            // Auto-select first event if any
            if (_myEvents.isNotEmpty) {
              _selectedEventId = _myEvents.first['id'] as String?;
            }
            _isLoadingEvents = false;
          });
        }
      } else {
        if (mounted) setState(() { _error = 'Failed to load events'; _isLoadingEvents = false; });
      }
    } catch (_) {
      if (mounted) setState(() { _error = 'Network error fetching events'; _isLoadingEvents = false; });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _departureDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _departureDate) {
      setState(() {
        _departureDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEventId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an event.')),
      );
      return;
    }

    _formKey.currentState!.save();

    setState(() => _isSpecifyingGroup = true);

    final token = context.read<AuthProvider>().accessToken;
    if (token == null) return;

    final data = {
      "event_id": _selectedEventId,
      "name": _name,
      "description": _description,
      "max_members": _maxMembers,
      "meeting_point": _meetingPoint,
      "requires_approval": _requiresApproval,
    };
    if (_departureDate != null) {
      data["departure_date"] = _departureDate!.toUtc().toIso8601String();
    }

    try {
      final res = await ApiService.createGroup(token, data);
      if (!mounted) return;

      if (res.statusCode == 201 || res.statusCode == 200) {
        final group = jsonDecode(res.body);
        final groupId = group['id'];
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group created successfully!')),
        );
        
        // Pop the creation screen returning true so the list refreshes
        Navigator.pop(context, true);

        // Instantly push to the new group's details
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => GroupDetailsScreen(groupId: groupId)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${res.statusCode} - ${res.body}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error connecting to server.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSpecifyingGroup = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Filter events to only "interested" or "going" and hopefully future events.
    // The backend `getUserEvents` should already only return user's active events.
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Create Travel Group', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: _isLoadingEvents
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _myEvents.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.event_busy_outlined, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            const Text(
                              'No Events Found',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'You must be attending an event to create a travel group. Go explore the dashboard and RSVP to an event first!',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Go Back'),
                            )
                          ],
                        ),
                      ),
                    )
                  : Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          const Text('Select Event', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedEventId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            items: _myEvents.map((evt) {
                              return DropdownMenuItem<String>(
                                value: evt['id'] as String?,
                                child: Text(
                                  evt['name'] as String? ?? 'Unknown Event',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedEventId = val;
                              });
                            },
                          ),
                          const SizedBox(height: 20),

                          const Text('Group Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 8),
                          TextFormField(
                            decoration: InputDecoration(
                              hintText: 'e.g., HackMIT Road Trip',
                              filled: true,
                              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            onSaved: (v) => _name = v!.trim(),
                          ),
                          const SizedBox(height: 20),

                          const Text('Meeting Point / Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 8),
                          TextFormField(
                            decoration: InputDecoration(
                              hintText: 'e.g., Main Subway Station',
                              filled: true,
                              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            onSaved: (v) => _meetingPoint = v?.trim() ?? '',
                          ),
                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Maximum Members', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<int>(
                                      value: _maxMembers,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      ),
                                      items: [2, 3, 4, 5, 6].map((m) {
                                        return DropdownMenuItem<int>(
                                          value: m,
                                          child: Text('$m People'),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          if (val != null) _maxMembers = val;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Departure Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(height: 8),
                                    InkWell(
                                      onTap: () => _selectDate(context),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.calendar_today, size: 18, color: theme.colorScheme.primary),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _departureDate == null 
                                                  ? 'Optional' 
                                                  : DateFormat('MMM d, yyyy').format(_departureDate!),
                                                style: theme.textTheme.bodyMedium,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: SwitchListTile(
                              title: const Text('Invite-Only Group', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: const Text('Users must request to join', style: TextStyle(fontSize: 12)),
                              value: _requiresApproval,
                              activeColor: theme.colorScheme.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              onChanged: (val) {
                                setState(() {
                                  _requiresApproval = val;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 20),

                          const Text('Group Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 8),
                          TextFormField(
                            decoration: InputDecoration(
                              hintText: 'Share your travel plans...',
                              filled: true,
                              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            maxLines: 4,
                            maxLength: 300,
                            onSaved: (v) => _description = v?.trim() ?? '',
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
      bottomNavigationBar: _myEvents.isEmpty || _isLoadingEvents || _error != null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSpecifyingGroup ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isSpecifyingGroup
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Create Group', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ),
            ),
    );
  }
}
