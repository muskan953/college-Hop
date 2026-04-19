import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:college_hop/providers/auth_provider.dart';
import 'package:college_hop/services/api_service.dart';

class ManageRequestsScreen extends StatefulWidget {
  final String groupId;
  const ManageRequestsScreen({super.key, required this.groupId});

  @override
  State<ManageRequestsScreen> createState() => _ManageRequestsScreenState();
}

class _ManageRequestsScreenState extends State<ManageRequestsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final token = context.read<AuthProvider>().accessToken;
    if (token == null) return;

    try {
      final res = await ApiService.getGroupRequests(token, widget.groupId);
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body) ?? [];
        if (mounted) {
          setState(() {
            _requests = list.cast<Map<String, dynamic>>();
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() { _error = 'Failed to load requests'; _loading = false; });
      }
    } catch (_) {
      if (mounted) setState(() { _error = 'Network error fetching requests'; _loading = false; });
    }
  }

  Future<void> _handleAction(String userId, String action) async {
    final token = context.read<AuthProvider>().accessToken;
    if (token == null) return;

    try {
      final res = action == 'accept' 
          ? await ApiService.acceptGroupRequest(token, widget.groupId, userId)
          : await ApiService.declineGroupRequest(token, widget.groupId, userId);
      
      if (res.statusCode == 200) {
        if (mounted) _fetchRequests(); // refresh list
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to $action request')));
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Join Requests')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _requests.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text('No pending requests', style: theme.textTheme.titleMedium),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _requests.length,
                      itemBuilder: (context, index) {
                        final req = _requests[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            backgroundImage: req['profile_photo_url'] != null && req['profile_photo_url'].toString().isNotEmpty
                                ? NetworkImage(req['profile_photo_url'])
                                : null,
                            child: (req['profile_photo_url'] == null || req['profile_photo_url'].toString().isEmpty)
                                ? Icon(Icons.person, color: theme.colorScheme.onPrimaryContainer)
                                : null,
                          ),
                          title: Text(req['full_name'] ?? 'Unknown User', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(req['college_name'] ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.grey),
                                onPressed: () => _handleAction(req['user_id'], 'decline'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.check, color: Colors.green),
                                onPressed: () => _handleAction(req['user_id'], 'accept'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
