import '../models/auth_response_model.dart';
import 'api_client.dart';

class AuthApiService {
  final ApiClient _apiClient;

  AuthApiService(this._apiClient);

  Future<AuthResponseModel> register({
    required String email,
    required String password,
    String? name,
  }) async {
    final body = <String, dynamic>{'email': email, 'password': password};
    if (name != null && name.trim().isNotEmpty) {
      body['name'] = name.trim();
    }

    final json = await _apiClient.post('/auth/register', body: body);
    return AuthResponseModel.fromJson(json);
  }

  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    final json = await _apiClient.post(
      '/auth/login',
      body: {'email': email, 'password': password},
    );
    return AuthResponseModel.fromJson(json);
  }
}
