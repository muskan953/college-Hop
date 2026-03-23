import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:college_hop/models/event_model.dart';
import 'package:college_hop/services/api_service.dart';

/// Manages the user's currently active/selected event.
class EventProvider extends ChangeNotifier {
  EventModel? _activeEvent;
  bool _isLoading = false;

  EventModel? get activeEvent => _activeEvent;
  bool get hasActiveEvent => _activeEvent != null;
  bool get isLoading => _isLoading;

  /// Fetch the user's most recent active event from the backend.
  Future<void> fetchActiveEvent(String token) async {
    try {
      _isLoading = true;
      notifyListeners();

      final res = await ApiService.getUserEvents(token);
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        if (list.isNotEmpty) {
          // The first entry is the most recent user event
          _activeEvent = EventModel.fromJson(list.first as Map<String, dynamic>);
        }
      }
    } catch (_) {
      // fail silently — user just sees the default screen
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set a new active event locally (after a successful API call).
  void setActiveEvent(EventModel event) {
    _activeEvent = event;
    notifyListeners();
  }

  /// Clear the active event (e.g. user wants to browse again).
  void clearActiveEvent() {
    _activeEvent = null;
    notifyListeners();
  }
}
