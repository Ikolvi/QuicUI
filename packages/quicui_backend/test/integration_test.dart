import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  const String baseUrl = 'http://localhost:8080';

  group('Backend Server Integration Tests', () {
    test('health check endpoint returns 200 OK', () async {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      expect(response.statusCode, equals(200));
      expect(response.body, contains('OK'));
    });

    test('check patches endpoint returns 200', () async {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/patches/check'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'appVersion': '1.0.0'}),
      );
      expect(response.statusCode, equals(200));
      expect(response.headers['content-type'], contains('application/json'));
    });

    test('list patches endpoint returns 200', () async {
      final response = await http.get(Uri.parse('$baseUrl/api/v1/patches'));
      expect(response.statusCode, equals(200));
      expect(response.body, contains('patches'));
    });

    test('create patch endpoint returns 200', () async {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/patches'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'patchId': 'test-patch-001',
          'version': '1.0.1',
        }),
      );
      expect(response.statusCode, equals(200));
      expect(response.body, contains('patchId'));
    });

    test('analytics endpoint returns 200', () async {
      final response = await http.get(Uri.parse('$baseUrl/api/v1/analytics'));
      expect(response.statusCode, equals(200));
      expect(response.body, contains('totalPatches'));
    });

    test('404 endpoint returns 404', () async {
      final response = await http.get(Uri.parse('$baseUrl/invalid/path'));
      expect(response.statusCode, equals(404));
    });

    test('CORS headers are present in response', () async {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      expect(response.statusCode, equals(200));
    });
  });
}
