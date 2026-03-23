import '../services/auth_api_service.dart';
import 'auth_session_repository.dart';

class AuthRepository {
  final AuthApiService _authApiService;
  final AuthSessionRepository _sessionRepository;

  AuthRepository({
    required AuthApiService authApiService,
    required AuthSessionRepository sessionRepository,
  }) : _authApiService = authApiService,
       _sessionRepository = sessionRepository;

  Future<void> bootstrapSession() async {
    await _sessionRepository.loadSession();
  }

  bool get isAuthenticated => _sessionRepository.isAuthenticated;
  String? get userId => _sessionRepository.userId;
  String? get email => _sessionRepository.email;
  String? get name => _sessionRepository.name;

  Future<void> register({
    required String email,
    required String password,
    String? name,
  }) async {
    final auth = await _authApiService.register(
      email: email,
      password: password,
      name: name,
    );
    await _sessionRepository.setSession(auth);
  }

  Future<void> login({required String email, required String password}) async {
    final auth = await _authApiService.login(email: email, password: password);
    await _sessionRepository.setSession(auth);
  }

  Future<void> logout() async {
    await _sessionRepository.clearSession();
  }

  Future<String?> getAccessToken() => _sessionRepository.getToken();

  Future<void> handleUnauthorized() => _sessionRepository.clearSession();
}
