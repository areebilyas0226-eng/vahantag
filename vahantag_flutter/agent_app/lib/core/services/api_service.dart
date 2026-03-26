import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _i = ApiService._();
  factory ApiService() => _i;
  ApiService._();
  late final Dio _dio;

  void init() {
    _dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl, connectTimeout: const Duration(seconds: 15), receiveTimeout: const Duration(seconds: 15)));
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) async {
      final token = await StorageService.getToken();
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
      return handler.next(options);
    }));
  }

  Future<Response> sendOTP(String phone) => _dio.post('/auth/agent/send-otp', data: {'phone': phone});
  Future<Response> verifyOTP(String phone, String otp, {String? name}) => _dio.post('/auth/agent/verify-otp', data: {'phone': phone, 'otp': otp, if (name != null) 'name': name});
  Future<Response> getProfile() => _dio.get('/agent/profile');
  Future<Response> updateProfile(Map<String, dynamic> d) => _dio.put('/agent/profile', data: d);
  Future<Response> getInventory() => _dio.get('/agent/inventory');
  Future<Response> recordSale(Map<String, dynamic> d) => _dio.post('/agent/sales/record', data: d);
  Future<Response> getSalesHistory() => _dio.get('/agent/sales/history');
}
