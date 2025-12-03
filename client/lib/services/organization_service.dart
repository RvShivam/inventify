import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:inventify/services/token_store.dart';

class OrganizationService {
  final String baseUrl;

  OrganizationService({String? baseUrl})
      : baseUrl = baseUrl ?? 'http://localhost:8080';

  Uri _uri(String path) => Uri.parse(baseUrl + path);

  Future<Map<String, dynamic>> getOrganization() async {
    final token = await TokenStore.getToken();
    final orgId = await TokenStore.getOrgId();

    final resp = await http.get(
      _uri('/api/organization'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        if (orgId != null) 'X-Organization-Id': orgId.toString(),
      },
    );

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      throw Exception('Failed to load organization: ${resp.body}');
    }
  }

  Future<String> regenerateReferralCode() async {
    final token = await TokenStore.getToken();
    final orgId = await TokenStore.getOrgId();

    final resp = await http.post(
      _uri('/api/organization/referral_code'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        if (orgId != null) 'X-Organization-Id': orgId.toString(),
      },
    );

    if (resp.statusCode == 200) {
      final body = jsonDecode(resp.body);
      return body['referralCode'];
    } else {
      throw Exception('Failed to regenerate code: ${resp.body}');
    }
  }
}
