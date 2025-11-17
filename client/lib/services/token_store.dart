import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStore {
  // secure storage (Android/iOS)
  static final _storage = FlutterSecureStorage();
  static const _key = 'auth_token';

  /// Save token after login
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _key, value: token);
  }

  /// Get saved token or null
  static Future<String?> getToken() async {
    return await _storage.read(key: _key);
  }

  /// Clear token on logout
  static Future<void> clear() async {
    await _storage.delete(key: _key);
  }
}
