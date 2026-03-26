import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class StorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ================= TOKEN =================
  static Future<void> saveToken(String token) async {
    await _storage.write(
      key: AppConstants.tokenKey,
      value: token,
    );
  }

  static Future<String?> getToken() async {
    return await _storage.read(
      key: AppConstants.tokenKey,
    );
  }

  // ================= ADMIN =================
  static Future<void> saveAdmin(Map<String, dynamic> admin) async {
    await _storage.write(
      key: AppConstants.adminKey,
      value: jsonEncode(admin),
    );
  }

  static Future<Map<String, dynamic>?> getAdmin() async {
    final data = await _storage.read(
      key: AppConstants.adminKey,
    );

    if (data == null) return null;

    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ================= CLEAR =================
  static Future<void> clear() async {
    await _storage.deleteAll();
  }
}