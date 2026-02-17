import 'package:flutter/material.dart';

class SignUpProvider with ChangeNotifier {
  // Step 1
  String _fullName = '';
  String _email = '';

  // Step 2
  String _collegeName = '';
  String _major = '';
  String _rollNumber = '';
  String _idExpiration = '';

  // Step 3
  String _idCardUrl = '';

  // Getters
  String get fullName => _fullName;
  String get email => _email;
  String get collegeName => _collegeName;
  String get major => _major;
  String get rollNumber => _rollNumber;
  String get idExpiration => _idExpiration;
  String get idCardUrl => _idCardUrl;

  void updateStep1({required String fullName, required String email}) {
    _fullName = fullName;
    _email = email;
    notifyListeners();
  }

  void updateStep2({
    required String collegeName,
    required String major,
    required String rollNumber,
    required String idExpiration,
  }) {
    _collegeName = collegeName;
    _major = major;
    _rollNumber = rollNumber;
    _idExpiration = idExpiration;
    notifyListeners();
  }

  void updateStep3({required String idCardUrl}) {
    _idCardUrl = idCardUrl;
    notifyListeners();
  }

  /// Returns a map suitable for the PUT /me profile endpoint.
  Map<String, dynamic> toProfilePayload() {
    final Map<String, dynamic> payload = {
      "full_name": _fullName,
      "college_name": _collegeName,
      "major": _major,
      "roll_number": _rollNumber,
      "id_expiration": _idExpiration,
    };

    // Only include ID card URL if it's an actual URL (not a local file path)
    if (_idCardUrl.startsWith('http')) {
      payload["college_id_card_url"] = _idCardUrl;
    }

    return payload;
  }

  void reset() {
    _fullName = '';
    _email = '';
    _collegeName = '';
    _major = '';
    _rollNumber = '';
    _idExpiration = '';
    _idCardUrl = '';
    notifyListeners();
  }
}
