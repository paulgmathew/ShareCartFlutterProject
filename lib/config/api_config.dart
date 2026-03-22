import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  ApiConfig._();

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api/v1';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080/api/v1';
    }
    // iOS simulator and macOS
    return 'http://127.0.0.1:8080/api/v1';
  }

  static const Duration connectionTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
