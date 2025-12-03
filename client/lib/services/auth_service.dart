// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:inventify/services/token_store.dart'; 

class AuthService {
  /// Base URL for backend. Use 10.0.2.2 for Android emulator.
  final String baseUrl;

  AuthService({String? baseUrl})
      : baseUrl = baseUrl ?? 'http://localhost:8080'; // override in tests or when constructing

  Uri _uri(String path) => Uri.parse(baseUrl + path);

  /// Signup: returns true on success, throws Exception on failure with message.
  Future<bool> signup({
    required String name,
    required String email,
    required String password,
    required String shopName,
    String? referralCode,
  }) async {
    final resp = await http.post(
      _uri('/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'shopName': shopName,
        if (referralCode != null) 'referralCode': referralCode,
      }),
    );

    if (resp.statusCode == 201 || resp.statusCode == 200) {
      return true;
    }

    // try to parse error body
    try {
      final body = jsonDecode(resp.body);
      final msg = (body is Map && (body['error'] ?? body['message']) != null)
          ? (body['error'] ?? body['message']).toString()
          : 'Signup failed (${resp.statusCode})';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Signup failed (${resp.statusCode}): ${resp.reasonPhrase}');
    }
  }

  /// Login: returns token string on success and optionally persists it.
  /// Also persists orgId (if present) into TokenStore.
  /// Throws Exception with backend message on failure.
  Future<String> login({
    required String email,
    required String password,
    bool persistToken = true,
  }) async {
    final resp = await http.post(
      _uri('/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (resp.statusCode == 200) {
      final body = jsonDecode(resp.body);

      // token
      final token = body['token'] as String?;
      if (token == null || token.isEmpty) {
        throw Exception('Login succeeded but no token returned');
      }

      // orgId may be returned as: int, string, or absent
      final dynamic rawOrg = body['orgId'] ?? body['org_id'];
      int? orgId = _parseOrgId(rawOrg);

      if (persistToken) {
        await TokenStore.saveToken(token);

        if (orgId != null && orgId > 0) {
          await TokenStore.saveOrgId(orgId);
        }

        if (body['userId'] != null) {
          await TokenStore.saveUserId(body['userId']);
        }

        if (body['roleId'] != null) {
          await TokenStore.saveRoleId(body['roleId']);
        }
      }


      return token;
    }

    try {
      final body = jsonDecode(resp.body);
      final msg = (body is Map && (body['error'] ?? body['message']) != null)
          ? (body['error'] ?? body['message']).toString()
          : 'Login failed (${resp.statusCode})';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Login failed (${resp.statusCode}): ${resp.reasonPhrase}');
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    final token = await TokenStore.getToken();
    if (token == null) throw Exception('No token found');

    final resp = await http.get(
      _uri('/api/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    }

    throw Exception('Failed to fetch profile (${resp.statusCode})');
  }

  Future<void> logout() async {
    await TokenStore.clear();
  }

  // Helper: parse orgId from dynamic response value
  int? _parseOrgId(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is double) return raw.toInt();
    if (raw is String) {
      final parsed = int.tryParse(raw);
      return parsed;
    }
    return null;
  }
}
