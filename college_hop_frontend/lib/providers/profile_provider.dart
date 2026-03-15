import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProfileProvider with ChangeNotifier {
  Map<String, dynamic>? _profileData;
  Map<String, dynamic>? _preferencesData;
  List<dynamic>? _userEvents;
  List<dynamic>? _userGroups;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get profileData => _profileData;
  Map<String, dynamic>? get preferencesData => _preferencesData;
  List<dynamic>? get userEvents => _userEvents;
  List<dynamic>? get userGroups => _userGroups;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ─── Profile ────────────────────────────────────────────────────────────────

  Future<void> fetchProfile(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.getProfile(token);
      if (response.statusCode == 200) {
        _profileData = jsonDecode(response.body);
      } else {
        _error = 'Failed to load profile (${response.statusCode})';
      }
    } catch (e) {
      _error = 'Network error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(String token, Map<String, dynamic> data) async {
    try {
      final response = await ApiService.updateProfile(token, data);
      if (response.statusCode == 200) {
        // Refresh local cache
        await fetchProfile(token);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Upload a profile photo and return the URL on success, or null on failure.
  Future<String?> uploadProfilePhoto({
    required String token,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final streamed = await ApiService.uploadFile(
        token: token,
        filePath: filePath,
        fileName: fileName,
        category: 'profile_photo',
      );
      if (streamed.statusCode == 200) {
        final body = await streamed.stream.bytesToString();
        final data = jsonDecode(body);
        return data['url'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Upload an ID card PDF and return the URL on success, or null on failure.
  Future<String?> uploadIdCard({
    required String token,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final streamed = await ApiService.uploadFile(
        token: token,
        filePath: filePath,
        fileName: fileName,
        category: 'id_card',
      );
      if (streamed.statusCode == 200) {
        final body = await streamed.stream.bytesToString();
        final data = jsonDecode(body);
        return data['url'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ─── Events & Groups ────────────────────────────────────────────────────────

  Future<void> fetchEvents(String token) async {
    try {
      final response = await ApiService.getUserEvents(token);
      if (response.statusCode == 200) {
        _userEvents = jsonDecode(response.body);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> fetchGroups(String token) async {
    try {
      final response = await ApiService.getUserGroups(token);
      if (response.statusCode == 200) {
        _userGroups = jsonDecode(response.body);
        notifyListeners();
      }
    } catch (_) {}
  }

  // ─── Preferences ────────────────────────────────────────────────────────────

  Future<void> fetchPreferences(String token) async {
    try {
      final response = await ApiService.getPreferences(token);
      if (response.statusCode == 200) {
        _preferencesData = jsonDecode(response.body);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> updatePreferences(String token, Map<String, dynamic> data) async {
    // Optimistically update local state so UI reacts immediately
    _preferencesData = {...?_preferencesData, ...data};
    notifyListeners();

    try {
      final response = await ApiService.updatePreferences(token, {
        'profile_visibility': _preferencesData!['profile_visibility'] ?? 'public',
        'show_location': _preferencesData!['show_location'] ?? true,
        'push_notifications': _preferencesData!['push_notifications'] ?? true,
        'email_notifications': _preferencesData!['email_notifications'] ?? true,
        'new_match_alerts': _preferencesData!['new_match_alerts'] ?? true,
        'message_alerts': _preferencesData!['message_alerts'] ?? true,
      });
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void clear() {
    _profileData = null;
    _preferencesData = null;
    _userEvents = null;
    _userGroups = null;
    _error = null;
    notifyListeners();
  }
}
