import 'package:flutter/foundation.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';

class AdminAuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = true;
  Map<String, dynamic>? _admin;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get admin => _admin;

  Future<void> initialize() async {
    final token = await StorageService.getToken();
    final admin = await StorageService.getAdmin();

    if (token != null && token.isNotEmpty && admin != null) {
      _admin = admin;
      _isAuthenticated = true;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> sendOTP(String phone) async {
    try {
      await ApiService().sendOTP(phone);
      return true;
    } catch (e) {
      debugPrint("OTP ERROR: $e");
      return false;
    }
  }

  Future<bool> verifyOTP(String phone, String otp) async {
    try {
      final res = await ApiService().verifyOTP(phone, otp);

      final data = res.data['data'];
      if (data == null) throw Exception("Invalid response");

      final token = data['accessToken'];
      final user = data['user'];

      if (token == null || user == null) {
        throw Exception("Missing token/user");
      }

      await StorageService.saveToken(token);
      await StorageService.saveAdmin(user);

      _admin = Map<String, dynamic>.from(user);
      _isAuthenticated = true;

      notifyListeners();
      return true;

    } catch (e) {
      debugPrint("VERIFY ERROR: $e");
      return false;
    }
  }

  Future<void> logout() async {
    await StorageService.clear();
    _isAuthenticated = false;
    _admin = null;
    notifyListeners();
  }
}