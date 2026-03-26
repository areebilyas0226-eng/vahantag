import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Dio? _dio;

  Dio get dio {
    if (_dio == null) {
      throw Exception("ApiService not initialized. Call init() first.");
    }
    return _dio!;
  }

  void init() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      validateStatus: (status) => status != null && status < 500,
      headers: {'Content-Type': 'application/json'},
    ));

    _dio!.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await StorageService.getToken();

          print("\n======== API REQUEST ========");
          print("URL: ${options.method} ${options.uri}");
          print("DATA: ${options.data}");

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
            print("TOKEN: ✔️ attached");
          } else {
            print("TOKEN: ❌ missing");
          }

          print("=============================\n");

          handler.next(options);
        },

        onResponse: (response, handler) {
          print("\n======== API RESPONSE ========");
          print("STATUS: ${response.statusCode}");
          print("URL: ${response.requestOptions.uri}");
          print("DATA: ${response.data}");
          print("==============================\n");

          handler.next(response);
        },

        onError: (error, handler) {
          final message = _extractErrorMessage(error);

          print("\n======== API ERROR ========");
          print("STATUS: ${error.response?.statusCode}");
          print("URL: ${error.requestOptions.uri}");
          print("MESSAGE: $message");
          print("DATA: ${error.response?.data}");
          print("===========================\n");

          handler.next(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              error: message,
              type: error.type,
            ),
          );
        },
      ),
    );
  }

  // ================= ERROR HANDLING =================
  String _extractErrorMessage(DioException error) {
    final data = error.response?.data;

    if (data is Map) {
      return data['message'] ??
          data['error'] ??
          "Something went wrong";
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return "Connection timeout";
      case DioExceptionType.connectionError:
        return "Server unreachable";
      case DioExceptionType.receiveTimeout:
        return "Server slow response";
      default:
        return "Something went wrong";
    }
  }

  // ================= AUTH =================
  Future<Response> sendOTP(String phone) =>
      dio.post('/auth/admin/send-otp', data: {'phone': phone});

  Future<Response> verifyOTP(String phone, String otp) =>
      dio.post('/auth/admin/verify-otp', data: {
        'phone': phone,
        'otp': otp,
      });

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

  // 🔥 FINAL FIXED VERSION
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

    final codes = data['codes'];

    if (codes == null || codes is! List) {
      throw Exception("Invalid codes format");
    }

    return List<String>.from(codes);
  }

  Future<Response> assignTags(
      String agentId, List<String> codes, int price) =>
      dio.post('/admin/tags/assign-agent', data: {
        'agent_id': agentId,
        'tag_codes': codes,
        'wholesale_price_paisa': price,
      });

  // ================= CATEGORIES =================
  Future<Response> getCategories() => dio.get('/admin/categories');

  Future<Response> updateCategory(String id, Map<String, dynamic> data) =>
      dio.put('/admin/categories/$id/price', data: data);

  // ================= REVENUE =================
  Future<Response> getRevenue() => dio.get('/admin/revenue');
}