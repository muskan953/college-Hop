import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  String? _accessToken;
  String? _refreshToken;
  String? _email;

  final Completer<void> _initCompleter = Completer<void>();

  /// A Future that completes once stored tokens have been loaded.
  Future<void> get initialized => _initCompleter.future;

  String? get accessToken => _accessToken;
  bool get isAuthenticated => _accessToken != null;

  AuthProvider() {
    _loadTokens();
  }

  Future<void> _loadTokens() async {
    try {
      _accessToken = await _storage.read(key: "access_token");
      _refreshToken = await _storage.read(key: "refresh_token");
      _email = await _storage.read(key: "email");
      notifyListeners();
    } catch (e) {
      debugPrint("Failed to load tokens: $e");
    } finally {
      _initCompleter.complete();
    }
  }

  Future<bool> verify(String email, String otp) async {
    try {
      final response = await ApiService.verifyOTP(email, otp);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data["access_token"];
        _refreshToken = data["refresh_token"];
        _email = email;

        await _storage.write(key: "access_token", value: _accessToken);
        await _storage.write(key: "refresh_token", value: _refreshToken);
        await _storage.write(key: "email", value: _email);
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    if (_refreshToken != null) {
      await ApiService.logout(_refreshToken!);
    }
    _accessToken = null;
    _refreshToken = null;
    _email = null;

    await _storage.delete(key: "access_token");
    await _storage.delete(key: "refresh_token");
    await _storage.delete(key: "email");

    notifyListeners();
  }

  Future<bool> tryRefresh() async {
    if (_refreshToken == null) return false;

    try {
      final response = await ApiService.refreshToken(_refreshToken!);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data["access_token"];
        _refreshToken = data["refresh_token"];

        await _storage.write(key: "access_token", value: _accessToken);
        await _storage.write(key: "refresh_token", value: _refreshToken);
        
        notifyListeners();
        return true;
      } else {
        await logout();
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
