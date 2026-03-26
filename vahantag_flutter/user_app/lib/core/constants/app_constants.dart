class AppConstants {
  static const String baseUrl = 'https://vahantag-production.up.railway.app/api';
  static const String appName = 'VahanTag';
  static const String razorpayKey = 'rzp_live_xxxxxxxxxxxxxxxx';
  
  // Storage keys
  static const String tokenKey = 'user_token';
  static const String userKey = 'user_data';
  
  // OTP
  static const int otpLength = 6;
  static const int otpExpirySeconds = 600;
  static const int otpResendCooldown = 30;
  
  // Assets
  static const List<Map<String, dynamic>> assetCategories = [
    {'slug': 'vehicle', 'name': 'Vehicle', 'icon': '🚗'},
    {'slug': 'pet', 'name': 'Pet', 'icon': '🐕'},
    {'slug': 'bag', 'name': 'Bag / Luggage', 'icon': '👜'},
    {'slug': 'electronics', 'name': 'Phone / Laptop', 'icon': '📱'},
    {'slug': 'keys', 'name': 'Keys', 'icon': '🔑'},
    {'slug': 'other', 'name': 'Other Asset', 'icon': '📦'},
  ];

  static const List<String> bloodGroups = ['A+','A-','B+','B-','AB+','AB-','O+','O-'];

  static const List<String> vehicleTypes = ['car','bike','truck','auto','scooter','other'];

  static const List<String> relations = ['Father','Mother','Spouse','Brother','Sister','Friend','Other'];

  // Helplines
  static const List<Map<String, String>> helplines = [
    {'name': 'Ambulance', 'number': '108', 'icon': '🚑'},
    {'name': 'Police', 'number': '100', 'icon': '👮'},
    {'name': 'Women Helpline', 'number': '1091', 'icon': '👩'},
    {'name': 'Fire Brigade', 'number': '101', 'icon': '🔥'},
    {'name': 'Disaster Mgmt', 'number': '108', 'icon': '⚠️'},
    {'name': 'Child Helpline', 'number': '1098', 'icon': '👶'},
  ];
}
