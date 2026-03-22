import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/api_error_model.dart';

class ApiException implements Exception {
  final ApiErrorModel error;

  const ApiException(this.error);

  @override
  String toString() => 'ApiException(${error.status}): ${error.message}';
}

class ApiClient {
  final http.Client _client;
  final String _baseUrl;

  ApiClient({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<Map<String, dynamic>> get(String path) async {
    final response = await _client
        .get(Uri.parse('$_baseUrl$path'), headers: _headers)
        .timeout(ApiConfig.connectionTimeout);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$_baseUrl$path'),
          headers: _headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(ApiConfig.connectionTimeout);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _client
        .put(
          Uri.parse('$_baseUrl$path'),
          headers: _headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(ApiConfig.connectionTimeout);
    return _handleResponse(response);
  }

  Future<void> delete(String path) async {
    final response = await _client
        .delete(Uri.parse('$_baseUrl$path'), headers: _headers)
        .timeout(ApiConfig.connectionTimeout);
    if (response.statusCode >= 400) {
      _throwApiException(response);
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    _throwApiException(response);
  }

  Never _throwApiException(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException(ApiErrorModel.fromJson(body));
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(
        ApiErrorModel(
          status: response.statusCode,
          error: 'Error',
          message:
              response.body.isNotEmpty
                  ? response.body
                  : 'Unexpected error (${response.statusCode})',
        ),
      );
    }
  }

  void dispose() {
    _client.close();
  }
}
