import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ApiService {
  // Use "http://10.0.2.2:8080" for Android emulator
  // Use "http://localhost:8080" for iOS/Web or desktop
  static const String baseUrl = "http://localhost:8080";

  static Future<http.Response> signup(String email) async {
    final url = Uri.parse("$baseUrl/auth/signup");
    return await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );
  }

  static Future<http.Response> login(String email) async {
    final url = Uri.parse("$baseUrl/auth/login");
    return await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );
  }

  static Future<http.Response> verifyOTP(String email, String otp) async {
    final url = Uri.parse("$baseUrl/auth/verify");
    return await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "otp": otp}),
    );
  }

  static Future<http.Response> getProfile(String token) async {
    final url = Uri.parse("$baseUrl/me");
    return await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
  }

  static Future<http.Response> updateProfile(String token, Map<String, dynamic> profileData) async {
    final url = Uri.parse("$baseUrl/me");
    return await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(profileData),
    );
  }

  static Future<http.Response> getPreferences(String token) async {
    final url = Uri.parse("$baseUrl/me/preferences");
    return await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
  }

  static Future<http.Response> updatePreferences(String token, Map<String, dynamic> prefsData) async {
    final url = Uri.parse("$baseUrl/me/preferences");
    return await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(prefsData),
    );
  }

  static Future<http.Response> refreshToken(String refreshToken) async {
    final url = Uri.parse("$baseUrl/auth/refresh");
    return await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"refresh_token": refreshToken}),
    );
  }

  static Future<http.Response> logout(String refreshToken) async {
    final url = Uri.parse("$baseUrl/auth/logout");
    return await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"refresh_token": refreshToken}),
    );
  }

  /// GET /events — fetch all approved events (public, no auth required)
  static Future<http.Response> getEvents() async {
    final url = Uri.parse("$baseUrl/events");
    return await http.get(
      url,
      headers: {"Content-Type": "application/json"},
    );
  }

  /// PUT /me/event — set user's active event interest
  static Future<http.Response> setUserEvent(
      String token, String eventId, String status) async {
    final url = Uri.parse("$baseUrl/me/event");
    return await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"event_id": eventId, "status": status}),
    );
  }

  static Future<http.Response> getUserEvents(String token) async {
    final url = Uri.parse("$baseUrl/me/events");
    return await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
  }

  static Future<http.Response> getUserGroups(String token) async {
    final url = Uri.parse("$baseUrl/me/groups");
    return await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
  }

  /// Upload a file (e.g. ID card PDF) to the backend.
  /// Returns the response containing the file URL on success.
  static Future<http.StreamedResponse> uploadFile({
    required String token,
    required String fileName,
    required String category, // "id_card" or "profile_photo"
    String? filePath,
    Uint8List? fileBytes,
  }) async {
    final url = Uri.parse("$baseUrl/upload");
    final request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['category'] = category;
    
    if (fileBytes != null) {
      request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: fileName));
    } else if (filePath != null) {
      request.files.add(await http.MultipartFile.fromPath('file', filePath, filename: fileName));
    } else {
      throw Exception("Either filePath or fileBytes must be provided");
    }
    
    return await request.send();
  }

  /// GET /users/matches?event_id=xxx — find best peer matches for an event
  static Future<http.Response> getMatches(String token, String eventId) async {
    final url = Uri.parse("$baseUrl/users/matches?event_id=$eventId");
    return await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
  }

  /// GET /groups/suggested?event_id=xxx — get suggested groups for an event
  static Future<http.Response> getSuggestedGroups(
      String token, String eventId) async {
    final url = Uri.parse("$baseUrl/groups/suggested?event_id=$eventId");
    return await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
  }

  /// GET /groups/{id} — get full group details with members
  static Future<http.Response> getGroupDetails(
      String token, String groupId) async {
    final url = Uri.parse("$baseUrl/groups/$groupId");
    return await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
  }

  /// POST /groups/{id}/join — join a travel group
  static Future<http.Response> joinGroup(String token, String groupId) async {
    final url = Uri.parse("$baseUrl/groups/$groupId/join");
    return await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
  }
}

