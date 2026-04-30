import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ApiService {
  // Set at build time via --dart-define=API_BASE_URL=https://api.collegehop.online
  // Falls back to localhost for local development
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  /// Overridable HTTP client — swap this in tests with a MockClient.
  static http.Client httpClient = http.Client();

  // ── Token Refresh Interceptor ───────────────────────────────────────────

  /// Global callback set by AuthProvider to silently refresh the access token.
  /// Returns the new access token on success, or null on failure.
  static Future<String?> Function()? onTokenRefresh;

  /// Wraps any authenticated API call with automatic 401 retry.
  /// [token] is the current access token.
  /// [request] is a function that takes a token and returns the HTTP response.
  static Future<http.Response> _withAuth(
    String token,
    Future<http.Response> Function(String t) request,
  ) async {
    final res = await request(token);
    if (res.statusCode == 401 && onTokenRefresh != null) {
      final newToken = await onTokenRefresh!();
      if (newToken != null) {
        return await request(newToken);
      }
    }
    return res;
  }

  // ── Auth (no interceptor needed) ────────────────────────────────────────

  static Future<http.Response> signup(String email) async {
    final url = Uri.parse("$baseUrl/auth/signup");
    return await httpClient.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );
  }

  static Future<http.Response> login(String email) async {
    final url = Uri.parse("$baseUrl/auth/login");
    return await httpClient.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );
  }

  static Future<http.Response> verifyOTP(String email, String otp) async {
    final url = Uri.parse("$baseUrl/auth/verify");
    return await httpClient.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "otp": otp}),
    );
  }

  static Future<http.Response> refreshToken(String refreshToken) async {
    final url = Uri.parse("$baseUrl/auth/refresh");
    return await httpClient.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"refresh_token": refreshToken}),
    );
  }

  static Future<http.Response> logout(String refreshToken) async {
    final url = Uri.parse("$baseUrl/auth/logout");
    return await httpClient.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"refresh_token": refreshToken}),
    );
  }

  // ── Profile ─────────────────────────────────────────────────────────────

  static Future<http.Response> getProfile(String token) =>
      _withAuth(token, (t) => httpClient.get(
        Uri.parse("$baseUrl/me"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $t"},
      ));

  static Future<http.Response> updateProfile(String token, Map<String, dynamic> profileData) =>
      _withAuth(token, (t) => http.put(
        Uri.parse("$baseUrl/me"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $t"},
        body: jsonEncode(profileData),
      ));

  static Future<http.Response> getPreferences(String token) =>
      _withAuth(token, (t) => httpClient.get(
        Uri.parse("$baseUrl/me/preferences"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $t"},
      ));

  static Future<http.Response> updatePreferences(String token, Map<String, dynamic> prefsData) =>
      _withAuth(token, (t) => http.put(
        Uri.parse("$baseUrl/me/preferences"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $t"},
        body: jsonEncode(prefsData),
      ));

  // ── Events ──────────────────────────────────────────────────────────────

  /// GET /events — fetch all approved events (public, no auth required)
  static Future<http.Response> getEvents() async {
    final url = Uri.parse("$baseUrl/events");
    return await httpClient.get(
      url,
      headers: {"Content-Type": "application/json"},
    );
  }

  /// PUT /me/event — set user's active event interest
  static Future<http.Response> setUserEvent(String token, String eventId, String status) =>
      _withAuth(token, (t) => http.put(
        Uri.parse("$baseUrl/me/event"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $t"},
        body: jsonEncode({"event_id": eventId, "status": status}),
      ));

  static Future<http.Response> getUserEvents(String token) =>
      _withAuth(token, (t) => httpClient.get(
        Uri.parse("$baseUrl/me/events"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $t"},
      ));

  // ── Groups ──────────────────────────────────────────────────────────────

  static Future<http.Response> getUserGroups(String token) =>
      _withAuth(token, (t) => httpClient.get(
        Uri.parse("$baseUrl/me/groups"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $t"},
      ));

  static Future<http.Response> getSuggestedGroups(String token, String eventId) =>
      _withAuth(token, (t) => httpClient.get(
        Uri.parse("$baseUrl/groups/suggested?event_id=$eventId"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $t"},
      ));

  static Future<http.Response> getGroupDetails(String token, String groupId) =>
      _withAuth(token, (t) => httpClient.get(
        Uri.parse("$baseUrl/groups/$groupId"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $t"},
      ));

  static Future<http.Response> joinGroup(String token, String groupId) =>
      _withAuth(token, (t) => httpClient.post(
        Uri.parse("$baseUrl/groups/$groupId/join"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $t"},
      ));

  static Future<http.Response> leaveGroup(String token, String groupId) =>
      _withAuth(token, (t) => httpClient.post(
        Uri.parse("$baseUrl/groups/$groupId/leave"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $t"},
      ));

  static Future<http.Response> getAllGroups(String token) =>
      _withAuth(token, (t) => httpClient.get(
        Uri.parse("$baseUrl/groups"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $t"},
      ));

  static Future<http.Response> createGroup(String token, Map<String, dynamic> data) =>
      _withAuth(token, (t) => httpClient.post(
        Uri.parse("$baseUrl/groups"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $t"},
        body: jsonEncode(data),
      ));

  static Future<http.Response> getGroupRequests(String token, String groupId) =>
      _withAuth(token, (t) => httpClient.get(
        Uri.parse("$baseUrl/groups/$groupId/requests"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $t"},
      ));

  static Future<http.Response> acceptGroupRequest(String token, String groupId, String userId) =>
      _withAuth(token, (t) => httpClient.post(
        Uri.parse("$baseUrl/groups/$groupId/requests/$userId/accept"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $t"},
      ));

  static Future<http.Response> declineGroupRequest(String token, String groupId, String userId) =>
      _withAuth(token, (t) => httpClient.post(
        Uri.parse("$baseUrl/groups/$groupId/requests/$userId/decline"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $t"},
      ));

  // ── Upload (StreamedResponse — not intercepted) ─────────────────────────

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

  // ── Users / Matching ────────────────────────────────────────────────────

  static Future<http.Response> getMatches(String token, String eventId) =>
      _withAuth(token, (t) => httpClient.get(
        Uri.parse("$baseUrl/users/matches?event_id=$eventId"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $t"},
      ));

  static Future<http.Response> getPublicProfile(String token, String userId) =>
      _withAuth(token, (t) => httpClient.get(
        Uri.parse("$baseUrl/users/$userId"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $t"},
      ));

  static Future<http.Response> connectUser(String token, String userId, String message) =>
      _withAuth(token, (t) => httpClient.post(
        Uri.parse("$baseUrl/users/$userId/connect"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $t"},
        body: jsonEncode({"message": message}),
      ));

  // ── Messages ────────────────────────────────────────────────────────────

  static Future<http.Response> acceptRequest(String token, String threadId) =>
      _withAuth(token, (t) => httpClient.post(
        Uri.parse("$baseUrl/messages/threads/$threadId/accept"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $t"},
      ));

  static Future<http.Response> declineRequest(String token, String threadId) =>
      _withAuth(token, (t) => httpClient.post(
        Uri.parse("$baseUrl/messages/threads/$threadId/decline"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $t"},
      ));

  static Future<http.Response> getConnections(String token) =>
      _withAuth(token, (t) => httpClient.get(
        Uri.parse("$baseUrl/me/connections"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $t"},
      ));

  static Future<http.Response> getThreads(String token) =>
      _withAuth(token, (t) => httpClient.get(
        Uri.parse("$baseUrl/messages/threads"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $t"},
      ));

  static Future<http.Response> markAsRead(String token, String threadId) =>
      _withAuth(token, (t) => httpClient.post(
        Uri.parse("$baseUrl/messages/threads/$threadId/read"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $t"},
      ));

  static Future<http.Response> getMessages(String token, String threadId) =>
      _withAuth(token, (t) => httpClient.get(
        Uri.parse("$baseUrl/messages/$threadId"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $t"},
      ));

  static Future<http.Response> sendMessage(String token, Map<String, dynamic> data) =>
      _withAuth(token, (t) => httpClient.post(
        Uri.parse("$baseUrl/messages/send"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $t"},
        body: jsonEncode(data),
      ));

  static Future<http.Response> createDirectThread(String token, String userId) =>
      _withAuth(token, (t) => httpClient.post(
        Uri.parse("$baseUrl/messages/thread/direct"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $t"},
        body: jsonEncode({"user_id": userId}),
      ));

  static Future<http.Response> clearThread(String token, String threadId) =>
      _withAuth(token, (t) => httpClient.post(
        Uri.parse("$baseUrl/messages/threads/$threadId/clear"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $t"},
      ));

  static Future<http.Response> registerDeviceToken(String token, String fcmToken, String platform) =>
      _withAuth(token, (t) => httpClient.post(
        Uri.parse("$baseUrl/me/device-token"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $t"},
        body: jsonEncode({"token": fcmToken, "platform": platform}),
      ));

  static Future<http.Response> deleteMessage(String token, String messageId) =>
      _withAuth(token, (t) => http.delete(
        Uri.parse("$baseUrl/messages/$messageId"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $t"},
      ));

  // ── Alternate Email ─────────────────────────────────────────────────────

  static Future<http.Response> requestAlternateEmailOTP(String token, String email) =>
      _withAuth(token, (t) => httpClient.post(
        Uri.parse("$baseUrl/me/alternate-email/request-otp"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $t"},
        body: jsonEncode({"email": email}),
      ));

  static Future<http.Response> verifyAlternateEmail(String token, String email, String otp) =>
      _withAuth(token, (t) => httpClient.post(
        Uri.parse("$baseUrl/me/alternate-email/verify"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $t"},
        body: jsonEncode({"email": email, "otp": otp}),
      ));

  // ── Block / Unblock ─────────────────────────────────────────────────────

  static Future<http.Response> blockUser(String token, String userId) =>
      _withAuth(token, (t) => httpClient.post(
        Uri.parse("$baseUrl/users/$userId/block"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $t"},
      ));

  static Future<http.Response> unblockUser(String token, String userId) =>
      _withAuth(token, (t) => httpClient.post(
        Uri.parse("$baseUrl/users/$userId/unblock"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $t"},
      ));

  static Future<http.Response> getBlockedUsers(String token) =>
      _withAuth(token, (t) => httpClient.get(
        Uri.parse("$baseUrl/me/blocked"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $t"},
      ));
}
