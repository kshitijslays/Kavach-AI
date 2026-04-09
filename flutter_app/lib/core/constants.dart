import 'package:flutter/foundation.dart';

class AppConstants {
  // Set this to true only if you want to test against your local machine (127.0.0.1:5000)
  static const bool useLocalBackend = false; 
  
  static const String baseUrlProd = 'https://kavach-ai-9tff.onrender.com/api';
  static const String baseUrlLocal = 'http://127.0.0.1:5000/api';

  static String get apiBaseUrl => useLocalBackend ? baseUrlLocal : baseUrlProd;

  static const String appName = 'Kavach';
  static const int otpLength = 6;
  static const int apiTimeout = 30000;
}
