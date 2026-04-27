import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:college_hop/services/api_service.dart';

/// Creates a [MockClient] that always responds with the given [statusCode] and [body].
MockClient _client(int statusCode, String body) {
  return MockClient((request) async {
    return http.Response(body, statusCode,
        headers: {'content-type': 'application/json'});
  });
}

void main() {
  // ApiService uses a module-level http client we can swap out for testing.
  // Each test injects its own MockClient via ApiService.httpClient.

  group('ApiService — Auth', () {
    test('signup returns 200 on success', () async {
      ApiService.httpClient = _client(200, '{"message":"otp sent"}');
      final res = await ApiService.signup('student@nitw.ac.in');
      expect(res.statusCode, 200);
    });

    test('verifyOTP returns 200 with tokens on success', () async {
      final body = jsonEncode({
        'access_token': 'access-abc',
        'refresh_token': 'refresh-xyz',
      });
      ApiService.httpClient = _client(200, body);
      final res = await ApiService.verifyOTP('student@nitw.ac.in', '123456');
      expect(res.statusCode, 200);
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      expect(data['access_token'], isNotEmpty);
      expect(data['refresh_token'], isNotEmpty);
    });

    test('verifyOTP returns 401 on bad OTP', () async {
      ApiService.httpClient = _client(401, '{"error":"invalid otp"}');
      final res = await ApiService.verifyOTP('student@nitw.ac.in', '000000');
      expect(res.statusCode, 401);
    });
  });

  group('ApiService — Events', () {
    test('getEvents returns 200 with list on success', () async {
      final body = jsonEncode([
        {'id': 'evt-1', 'name': 'TechFest'},
        {'id': 'evt-2', 'name': 'HackNITW'},
      ]);
      ApiService.httpClient = _client(200, body);
      final res = await ApiService.getEvents();
      expect(res.statusCode, 200);
      final list = jsonDecode(res.body) as List;
      expect(list.length, 2);
    });

    test('getEvents returns 500 on server error', () async {
      ApiService.httpClient = _client(500, '{"error":"server error"}');
      final res = await ApiService.getEvents();
      expect(res.statusCode, 500);
    });
  });

  group('ApiService — Messages', () {
    test('sendMessage returns 201 on success', () async {
      final body = jsonEncode({'id': 'msg-1', 'content': 'hello'});
      ApiService.httpClient = _client(201, body);
      final res = await ApiService.sendMessage(
          'token', {'thread_id': 't1', 'content': 'hello'});
      expect(res.statusCode, 201);
    });

    test('getThreads returns 200 with threads', () async {
      final body = jsonEncode([
        {'id': 'thread-1', 'name': 'Alice'}
      ]);
      ApiService.httpClient = _client(200, body);
      final res = await ApiService.getThreads('token');
      expect(res.statusCode, 200);
      final list = jsonDecode(res.body) as List;
      expect(list.length, 1);
    });
  });

  group('ApiService — Users', () {
    test('blockUser returns 200', () async {
      ApiService.httpClient = _client(200, '{"message":"blocked"}');
      final res = await ApiService.blockUser('token', 'user-2');
      expect(res.statusCode, 200);
    });

    test('connectUser returns 201', () async {
      ApiService.httpClient = _client(201, '{"message":"request sent"}');
      final res =
          await ApiService.connectUser('token', 'user-2', 'Hey, let\'s connect!');
      expect(res.statusCode, 201);
    });
  });
}
