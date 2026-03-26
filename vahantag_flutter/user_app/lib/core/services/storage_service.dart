import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class StorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<void> saveToken(String token) =>
      _storage.write(key: 'user_token', value: token);

  static Future<String?> getToken() =>
      _storage.read(key: 'user_token');

  static Future<void> deleteToken() =>
      _storage.delete(key: 'user_token');

  static Future<void> saveUser(Map<String, dynamic> user) =>
      _storage.write(key: 'user_data', value: jsonEncode(user));

  static Future<Map<String, dynamic>?> getUser() async {
    final data = await _storage.read(key: 'user_data');
    if (data == null) return null;
    return jsonDecode(data);
  }

  static Future<void> clear() async => await _storage.deleteAll();
}
