import 'package:flutter/foundation.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';

class AgentAuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = true;
  bool _isPending = false;
  Map<String, dynamic>? _agent;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isPending => _isPending;
  Map<String, dynamic>? get agent => _agent;

  Future<void> initialize() async {
    final token = await StorageService.getToken();
    final agent = await StorageService.getAgent();
    if (token != null && agent != null) { _agent = agent; _isAuthenticated = true; }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> sendOTP(String phone) async {
    try { await ApiService().sendOTP(phone); return true; }
    catch (_) { return false; }
  }

  Future<String> verifyOTP(String phone, String otp, {String? name}) async {
    try {
      final res = await ApiService().verifyOTP(phone, otp, name: name);
      final data = res.data['data'];
      if (data['pendingApproval'] == true) { _isPending = true; notifyListeners(); return 'pending'; }
      _agent = data['user'];
      await StorageService.saveToken(data['accessToken']);
      await StorageService.saveAgent(_agent!);
      _isAuthenticated = true;
      notifyListeners();
      return 'success';
    } catch (_) { return 'error'; }
  }

  Future<void> logout() async {
    await StorageService.clear();
    _isAuthenticated = false;
    _isPending = false;
    _agent = null;
    notifyListeners();
  }
}
