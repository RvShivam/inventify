import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStore {
  static final _storage = const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  static const _orgIdKey = 'org_id';
  static const _userIdKey = 'user_id';
  static const _roleIdKey = 'role_id';

  static Future<void> saveToken(String token) async =>
      await _storage.write(key: _tokenKey, value: token);

  static Future<void> saveOrgId(int orgId) async =>
      await _storage.write(key: _orgIdKey, value: orgId.toString());

  static Future<void> saveUserId(int userId) async =>
      await _storage.write(key: _userIdKey, value: userId.toString());

  static Future<void> saveRoleId(int roleId) async =>
      await _storage.write(key: _roleIdKey, value: roleId.toString());

  static Future<String?> getToken() async =>
      await _storage.read(key: _tokenKey);

  static Future<int?> getOrgId() async {
    final v = await _storage.read(key: _orgIdKey);
    return v == null ? null : int.tryParse(v);
  }

  static Future<int?> getUserId() async {
    final v = await _storage.read(key: _userIdKey);
    return v == null ? null : int.tryParse(v);
  }

  static Future<int?> getRoleId() async {
    final v = await _storage.read(key: _roleIdKey);
    return v == null ? null : int.tryParse(v);
  }

  static Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _orgIdKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _roleIdKey);
  }
}
