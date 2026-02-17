import 'dart:convert';
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

  /// Upload a file (e.g. ID card PDF) to the backend.
  /// Returns the response containing the file URL on success.
  static Future<http.StreamedResponse> uploadFile({
    required String token,
    required String filePath,
    required String fileName,
    required String category, // "id_card" or "profile_photo"
  }) async {
    final url = Uri.parse("$baseUrl/upload");
    final request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['category'] = category;
    request.files.add(await http.MultipartFile.fromPath('file', filePath, filename: fileName));
    return await request.send();
  }
}
