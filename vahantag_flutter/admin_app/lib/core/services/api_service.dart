import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;

  Dio get dio => _dio;

  void init() {
    _dio = Dio(
      BaseOptions(
        // 🔥 FORCE correct URL (avoid hidden bug)
        baseUrl: AppConstants.baseUrl, 
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),

        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },

        validateStatus: (status) {
          return status != null && status < 500;
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await StorageService.getToken();

          print("\n======== API REQUEST ========");
          print("${options.method} ${options.uri}");
          print("DATA: ${options.data}");

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
            print("TOKEN: ✔️");
          } else {
            print("TOKEN: ❌");
          }

          handler.next(options);
        },

        onResponse: (response, handler) {
          print("\n======== API RESPONSE ========");
          print("STATUS: ${response.statusCode}");
          print("DATA: ${response.data}");
          handler.next(response);
        },

        onError: (error, handler) {
          print("\n======== API ERROR ========");
          print("TYPE: ${error.type}");
          print("MESSAGE: ${error.message}");
          print("DATA: ${error.response?.data}");

          handler.next(error);
        },
      ),
    );
  }

  // ================= AUTH =================
  Future<Response> sendOTP(String phone) async {
    return await dio.post(
      '/auth/admin/send-otp',
      data: {'phone': phone},
    );
  }

  Future<Response> verifyOTP(String phone, String otp) async {
    return await dio.post(
      '/auth/admin/verify-otp',
      data: {
        'phone': phone,
        'otp': otp,
      },
    );
  }

  // ================= DASHBOARD =================
  Future<Response> getDashboard() => dio.get('/admin/dashboard');

  // ================= USERS =================
  Future<Response> getUsers({int page = 1}) =>
      dio.get('/admin/users', queryParameters: {'page': page});

  Future<Response> toggleUser(String id) =>
      dio.put('/admin/users/$id/toggle');

  // ================= AGENTS =================
  Future<Response> getAgents() => dio.get('/admin/agents');

  Future<Response> approveAgent(String id) =>
      dio.put('/admin/agents/$id/approve');

  // ================= TAGS =================
  Future<Response> getTags({String status = ''}) =>
      dio.get('/admin/tags',
          queryParameters: status.isNotEmpty ? {'status': status} : {});

  Future<List<String>> generateTags(int count) async {
    final response = await dio.post(
      '/admin/tags/generate',
      data: {'count': count},
    );

    final data = response.data;

    if (data == null || data is! Map) {
      throw Exception("Invalid server response");
    }

    if (data['success'] != true) {
      throw Exception(data['message'] ?? "Tag generation failed");
    }

    return List<String>.from(data['codes']);
  }

  Future<Response> assignTags(
      String agentId, List<String> codes, int price) {
    return dio.post('/admin/tags/assign-agent', data: {
      'agent_id': agentId,
      'tag_codes': codes,
      'wholesale_price_paisa': price,
    });
  }

  // ================= CATEGORIES =================
  Future<Response> getCategories() => dio.get('/admin/categories');

  Future<Response> updateCategory(String id, Map<String, dynamic> data) =>
      dio.put('/admin/categories/$id/price', data: data);

  // ================= REVENUE =================
  Future<Response> getRevenue() => dio.get('/admin/revenue');
}