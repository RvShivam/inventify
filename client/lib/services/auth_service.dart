import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // For iOS emulator or web, use localhost. For Android emulator, use 10.0.2.2
  final String _baseUrl = 'http://localhost:8080';

  Future<bool> signup({
    required String name,
    required String email,
    required String password,
    required String shopName,
    required String referralCode, 
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'shopName': shopName,
        'referralCode': referralCode, 
      }),
    );
    
    if (response.statusCode != 201) {
      // Try to parse the error message from the server
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Signup failed.');
    }
    
    return true;
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['token'];
    }
    return null;
  }
}
