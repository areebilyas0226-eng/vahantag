import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
class StorageService {
  static const _s = FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));
  static Future<void> saveToken(String t) => _s.write(key: 'agent_token', value: t);
  static Future<String?> getToken() => _s.read(key: 'agent_token');
  static Future<void> saveAgent(Map<String, dynamic> a) => _s.write(key: 'agent_data', value: jsonEncode(a));
  static Future<Map<String, dynamic>?> getAgent() async {
    final d = await _s.read(key: 'agent_data');
    return d != null ? jsonDecode(d) : null;
  }
  static Future<void> clear() => _s.deleteAll();
}
