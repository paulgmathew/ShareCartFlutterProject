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
  final Future<String?> Function()? _accessTokenProvider;
  final Future<void> Function()? _onUnauthorized;

  ApiClient({
    http.Client? client,
    String? baseUrl,
    Future<String?> Function()? accessTokenProvider,
    Future<void> Function()? onUnauthorized,
  }) : _client = client ?? http.Client(),
       _baseUrl = baseUrl ?? ApiConfig.baseUrl,
       _accessTokenProvider = accessTokenProvider,
       _onUnauthorized = onUnauthorized;

  Future<Map<String, String>> _buildHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_accessTokenProvider != null) {
      final token = await _accessTokenProvider();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<Map<String, dynamic>> get(String path) async {
    final headers = await _buildHeaders();
    final response = await _client
        .get(Uri.parse('$_baseUrl$path'), headers: headers)
        .timeout(ApiConfig.connectionTimeout);
    return _handleResponse(response);
  }

  /// GET without Authorization header — for public endpoints.
  Future<Map<String, dynamic>> getPublic(String path) async {
    const headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final response = await _client
        .get(Uri.parse('$_baseUrl$path'), headers: headers)
        .timeout(ApiConfig.connectionTimeout);
    return _handleResponse(response);
  }

  Future<List<dynamic>> getList(String path) async {
    final headers = await _buildHeaders();
    final response = await _client
        .get(Uri.parse('$_baseUrl$path'), headers: headers)
        .timeout(ApiConfig.connectionTimeout);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return [];
      return jsonDecode(response.body) as List<dynamic>;
    }
    await _throwApiException(response);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final headers = await _buildHeaders();
    final response = await _client
        .post(
          Uri.parse('$_baseUrl$path'),
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(ApiConfig.connectionTimeout);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final headers = await _buildHeaders();
    final response = await _client
        .put(
          Uri.parse('$_baseUrl$path'),
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(ApiConfig.connectionTimeout);
    return _handleResponse(response);
  }

  Future<void> delete(String path) async {
    final headers = await _buildHeaders();
    final response = await _client
        .delete(Uri.parse('$_baseUrl$path'), headers: headers)
        .timeout(ApiConfig.connectionTimeout);
    if (response.statusCode >= 400) {
      await _throwApiException(response);
    }
  }

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    await _throwApiException(response);
  }

  Future<Never> _throwApiException(http.Response response) async {
    if (response.statusCode == 403 && _onUnauthorized != null) {
      await _onUnauthorized();
    }

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
