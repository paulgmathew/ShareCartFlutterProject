import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  ApiConfig._();

  /// Set to [true] to use the deployed Render backend.
  /// Set to [false] to use your local Spring Boot instance.
  static const bool useProductionServer = true;

  static const String _productionBaseUrl =
      'https://sharecartspringbootproject.onrender.com/api/v1';
  static const String _productionWebSocketUrl =
      'wss://sharecartspringbootproject.onrender.com/ws';

  static String get _localBaseUrl {
    if (kIsWeb) return 'http://localhost:8080/api/v1';
    if (Platform.isAndroid) return 'http://10.0.2.2:8080/api/v1';
    // iOS simulator and macOS
    return 'http://127.0.0.1:8080/api/v1';
  }

  static String get _localWebSocketUrl {
    if (kIsWeb) return 'ws://localhost:8080/ws';
    if (Platform.isAndroid) return 'ws://10.0.2.2:8080/ws';
    // iOS simulator and macOS
    return 'ws://127.0.0.1:8080/ws';
  }

  static String get baseUrl =>
      useProductionServer ? _productionBaseUrl : _localBaseUrl;

  static String get webSocketUrl =>
      useProductionServer ? _productionWebSocketUrl : _localWebSocketUrl;

  static const Duration connectionTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);
}
