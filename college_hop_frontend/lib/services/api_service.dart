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
    final url = Uri.parse("$baseUrl/upload?type=$category");
    final request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    
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

  /// GET /groups — list all travel groups with is_joined flag
  static Future<http.Response> getAllGroups(String token) async {
    final url = Uri.parse("$baseUrl/groups");
    return await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
  }

  /// GET /users/:id — fetch a user's public profile (requires auth)
  static Future<http.Response> getPublicProfile(String token, String userId) async {
    final url = Uri.parse("$baseUrl/users/$userId");
    return await http.get(url, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
  }

  /// POST /users/:id/connect — connect with another user (sends a request pending approval)
  static Future<http.Response> connectUser(String token, String userId, String message) async {
    final url = Uri.parse("$baseUrl/users/$userId/connect");
    return await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"message": message}),
    );
  }

  /// POST /messages/threads/:id/accept — Accept a request thread
  static Future<http.Response> acceptRequest(String token, String threadId) async {
    final url = Uri.parse("$baseUrl/messages/threads/$threadId/accept");
    return await http.post(url, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
  }

  /// POST /messages/threads/:id/decline — Decline a request thread
  static Future<http.Response> declineRequest(String token, String threadId) async {
    final url = Uri.parse("$baseUrl/messages/threads/$threadId/decline");
    return await http.post(url, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
  }

  /// POST /me/alternate-email/request-otp — request OTP for alternate email verification
  static Future<http.Response> requestAlternateEmailOTP(String token, String email) async {
    final url = Uri.parse("$baseUrl/me/alternate-email/request-otp");
    return await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"email": email}),
    );
  }

  /// POST /me/alternate-email/verify — verify OTP and save alternate email
  static Future<http.Response> verifyAlternateEmail(String token, String email, String otp) async {
    final url = Uri.parse("$baseUrl/me/alternate-email/verify");
    return await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"email": email, "otp": otp}),
    );
  }

  /// GET /me/connections — fetch confirmed connections
  static Future<http.Response> getConnections(String token) async {
    final url = Uri.parse("$baseUrl/me/connections");
    return await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
  }

  /// GET /messages/threads — fetch all message threads for the user
  static Future<http.Response> getThreads(String token) async {
    final url = Uri.parse("$baseUrl/messages/threads");
    return await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
  }

  /// POST /messages/threads/{threadId}/read — mark a chat as read
  static Future<http.Response> markAsRead(String token, String threadId) async {
    final url = Uri.parse("$baseUrl/messages/threads/$threadId/read");
    return await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
  }

  /// GET /messages/{threadId} — fetch message thread
  static Future<http.Response> getMessages(String token, String threadId) async {
    final url = Uri.parse("$baseUrl/messages/$threadId");
    return await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
  }

  /// POST /messages/send — send a message (HTTP fallback)
  static Future<http.Response> sendMessage(String token, Map<String, dynamic> data) async {
    final url = Uri.parse("$baseUrl/messages/send");
    return await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(data),
    );
  }

  /// POST /messages/thread/direct — get or create a 1:1 thread
  static Future<http.Response> createDirectThread(String token, String userId) async {
    final url = Uri.parse("$baseUrl/messages/thread/direct");
    return await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"user_id": userId}),
    );
  }

  /// POST /messages/threads/{id}/clear — clear chat for current user
  static Future<http.Response> clearThread(String token, String threadId) async {
    final url = Uri.parse("$baseUrl/messages/threads/$threadId/clear");
    return await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
  }

  /// POST /me/device-token — register FCM token
  static Future<http.Response> registerDeviceToken(String token, String fcmToken, String platform) async {
    final url = Uri.parse("$baseUrl/me/device-token");
    return await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"token": fcmToken, "platform": platform}),
    );
  }

  /// DELETE /messages/{messageId} — delete own message
  static Future<http.Response> deleteMessage(String token, String messageId) async {
    final url = Uri.parse("$baseUrl/messages/$messageId");
    return await http.delete(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
  }

  /// POST /users/{id}/block — block a user
  static Future<http.Response> blockUser(String token, String userId) async {
    final url = Uri.parse("$baseUrl/users/$userId/block");
    return await http.post(url, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
  }

  /// POST /users/{id}/unblock — unblock a user
  static Future<http.Response> unblockUser(String token, String userId) async {
    final url = Uri.parse("$baseUrl/users/$userId/unblock");
    return await http.post(url, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
  }

  /// GET /me/blocked — fetch all blocked users
  static Future<http.Response> getBlockedUsers(String token) async {
    final url = Uri.parse("$baseUrl/me/blocked");
    return await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
  }
}

