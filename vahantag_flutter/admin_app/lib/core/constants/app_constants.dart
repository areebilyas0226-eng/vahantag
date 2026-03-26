class AppConstants {
  // 🔥 CHANGE HERE IF TESTING LOCAL
  static const bool isLocal = false;

  static const String baseUrl = isLocal
      ? 'http://192.168.1.5:5000/api'   // 🔁 replace with your IP
      : 'https://vahantag-production.up.railway.app/api';

  static const String tokenKey = 'admin_token';
  static const String adminKey = 'admin_data';
}