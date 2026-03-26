import 'package:flutter/foundation.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = true;
  Map<String, dynamic>? _user;
  String? _error;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get user => _user;
  String? get error => _error;

  Future<void> initialize() async {
    final token = await StorageService.getToken();
    final user = await StorageService.getUser();
    if (token != null && user != null) {
      _user = user;
      _isAuthenticated = true;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> sendOTP(String phone) async {
    _error = null;
    try {
      await ApiService().sendOTP(phone, 'user');
      return true;
    } catch (e) {
      _error = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> verifyOTP(String phone, String otp, {String? name}) async {
    _error = null;
    try {
      final res = await ApiService().verifyOTP(phone, otp, 'user', name: name);
      final data = res.data['data'];
      _user = data['user'];
      await StorageService.saveToken(data['accessToken']);
      await StorageService.saveUser(_user!);
      _isAuthenticated = true;
      notifyListeners();
      return _user;
    } catch (e) {
      _error = _parseError(e);
      notifyListeners();
      return null;
    }
  }

  Future<void> updateUser(Map<String, dynamic> updates) async {
    _user = {...?_user, ...updates};
    await StorageService.saveUser(_user!);
    notifyListeners();
  }

  Future<void> logout() async {
    await StorageService.clear();
    _isAuthenticated = false;
    _user = null;
    notifyListeners();
  }

  String _parseError(dynamic e) {
    if (e is Exception) {
      final str = e.toString();
      if (str.contains('message')) {
        try {
          final start = str.indexOf('"message":"') + 11;
          final end = str.indexOf('"', start);
          return str.substring(start, end);
        } catch (_) {}
      }
    }
    return 'Something went wrong. Try again.';
  }
}
