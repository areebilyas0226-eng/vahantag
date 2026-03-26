import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio;

  void init() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await StorageService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        return handler.next(error);
      },
    ));
  }

  // AUTH
  Future<Response> sendOTP(String phone, String role) =>
      _dio.post('/auth/$role/send-otp', data: {'phone': phone});

  Future<Response> verifyOTP(String phone, String otp, String role, {String? name}) =>
      _dio.post('/auth/$role/verify-otp', data: {'phone': phone, 'otp': otp, if (name != null) 'name': name});

  // USER
  Future<Response> getProfile() => _dio.get('/user/profile');
  Future<Response> updateProfile(Map<String, dynamic> data) => _dio.put('/user/profile', data: data);

  // ASSETS
  Future<Response> getCategories() => _dio.get('/assets/categories');
  Future<Response> getMyAssets() => _dio.get('/assets');
  Future<Response> addAsset(Map<String, dynamic> data) => _dio.post('/assets', data: data);
  Future<Response> updateAsset(String id, Map<String, dynamic> data) => _dio.put('/assets/$id', data: data);
  Future<Response> deleteAsset(String id) => _dio.delete('/assets/$id');
  Future<Response> getTagQR(String assetId) => _dio.get('/assets/$assetId/qr');
  Future<Response> getEmergencyContacts(String assetId) => _dio.get('/assets/$assetId/emergency-contacts');
  Future<Response> addEmergencyContact(String assetId, Map<String, dynamic> data) =>
      _dio.post('/assets/$assetId/emergency-contacts', data: data);
  Future<Response> activateTag(Map<String, dynamic> data) => _dio.post('/assets/activate', data: data);
  Future<Response> verifyActivation(Map<String, dynamic> data) => _dio.post('/assets/verify-activation', data: data);

  // EMERGENCY (public)
  Future<Response> getEmergencyPage(String tagCode) => _dio.get('/emergency/page/$tagCode');
  Future<Response> initiateCall(String tagId, String callerPhone) =>
      _dio.post('/emergency/$tagId/call', data: {'callerPhone': callerPhone});
  Future<Response> getWhatsAppLink(String tagId) => _dio.get('/emergency/$tagId/whatsapp');
}
