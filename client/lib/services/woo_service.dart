// lib/services/woo_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// WooService - handles connecting a WooCommerce store with the backend.
///
/// NOTE: If you run on Android emulator, use baseUrl 'http://10.0.2.2:8080'
class WooService {
  final String _baseUrl;
  final Duration _timeout;

  WooService({
    String? baseUrl,
    Duration? timeout,
  })  : _baseUrl = baseUrl ?? 'http://localhost:8080',
        _timeout = timeout ?? const Duration(seconds: 15);

  Map<String, String> _authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> createWooStore({
    required String token,
    required String siteUrl,
    required String consumerKey,
    required String consumerSecret,
    bool verifySSL = true,
    String? name,
  }) async {
    final uri = Uri.parse('$_baseUrl/woo_stores');
    final body = jsonEncode({
      'site_url': siteUrl,
      'consumer_key': consumerKey,
      'consumer_secret': consumerSecret,
      'verify_ssl': verifySSL,
      if (name != null) 'name': name,
    });

    http.Response resp;
    try {
      resp = await http
          .post(uri, headers: _authHeaders(token), body: body)
          .timeout(_timeout);
    } on SocketException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on http.ClientException catch (e) {
      throw Exception('HTTP client error: ${e.message}');
    } on Exception catch (e) {
      throw Exception('Request failed: $e');
    }

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      if (resp.body.isEmpty) return <String, dynamic>{};
      try {
        final data = jsonDecode(resp.body);
        if (data is Map<String, dynamic>) return data;
        return {'result': data};
      } catch (e) {
        // non-json success response
        return {'result': resp.body};
      }
    }

    // error handling: try parsing JSON error message
    final parsedMsg = _parseErrorMessage(resp);
    throw Exception(parsedMsg ?? 'Create store failed (${resp.statusCode})');
  }

  Future<bool> testWooStore({
    required String token,
    required int storeId,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/woo_stores/$storeId/test');

    http.Response resp;
    try {
      resp = await http.post(uri, headers: _authHeaders(token)).timeout(_timeout);
    } on SocketException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on Exception catch (e) {
      throw Exception('Request failed: $e');
    }

    if (resp.statusCode == 200) return true;

    final parsedMsg = _parseErrorMessage(resp);
    throw Exception(parsedMsg ?? 'Test store failed (${resp.statusCode})');
  }

  Future<Map<String, dynamic>> registerWebhooks({
    required String token,
    required int storeId,
    String? deliveryUrl,
    List<String>? topics,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/woo_stores/$storeId/webhooks');
    final payload = <String, dynamic>{};
    if (deliveryUrl != null) payload['delivery_url'] = deliveryUrl;
    if (topics != null) payload['topics'] = topics;

    http.Response resp;
    try {
      resp = await http
          .post(uri, headers: _authHeaders(token), body: jsonEncode(payload))
          .timeout(_timeout);
    } on SocketException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on Exception catch (e) {
      throw Exception('Request failed: $e');
    }

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      if (resp.body.isEmpty) return <String, dynamic>{};
      try {
        final data = jsonDecode(resp.body);
        return data is Map<String, dynamic> ? data : {'result': data};
      } catch (e) {
        return {'result': resp.body};
      }
    }

    final parsedMsg = _parseErrorMessage(resp);
    throw Exception(parsedMsg ?? 'Register webhooks failed (${resp.statusCode})');
  }

  String? _parseErrorMessage(http.Response resp) {
    if (resp.body.isEmpty) return null;
    try {
      final err = jsonDecode(resp.body);
      if (err is Map) {
        if (err['error'] != null) return err['error'].toString();
        if (err['message'] != null) return err['message'].toString();
      }
      return err.toString();
    } catch (_) {
      // not JSON
      return resp.body;
    }
  }
}
