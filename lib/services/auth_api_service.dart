import '../models/auth_response_model.dart';
import '../models/register_response_model.dart';
import '../models/resend_verification_request_model.dart';
import '../models/verify_email_response_model.dart';
import 'api_client.dart';

class AuthApiService {
  final ApiClient _apiClient;

  AuthApiService(this._apiClient);

  Future<RegisterResponseModel> register({
    required String email,
    required String password,
    String? name,
  }) async {
    final body = <String, dynamic>{'email': email, 'password': password};
    if (name != null && name.trim().isNotEmpty) {
      body['name'] = name.trim();
    }

    final json = await _apiClient.post('/auth/register', body: body);
    return RegisterResponseModel.fromJson(json);
  }

  Future<VerifyEmailResponseModel> verifyEmail(String token) async {
    final json = await _apiClient.get(
      '/auth/verify-email?token=${Uri.encodeQueryComponent(token.trim())}',
    );
    return VerifyEmailResponseModel.fromJson(json);
  }

  Future<VerifyEmailResponseModel> resendVerification(String email) async {
    final request = ResendVerificationRequestModel(email: email.trim());
    final json = await _apiClient.post(
      '/auth/resend-verification',
      body: request.toJson(),
    );
    return VerifyEmailResponseModel.fromJson(json);
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
