import 'package:flutter/foundation.dart';

import '../repositories/auth_repository.dart';
import '../repositories/auth_session_repository.dart';
import '../services/api_client.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final AuthSessionRepository _sessionRepository;

  AuthProvider({
    required AuthRepository authRepository,
    required AuthSessionRepository sessionRepository,
  }) : _authRepository = authRepository,
       _sessionRepository = sessionRepository {
    _sessionRepository.addListener(_handleSessionChange);
    _bootstrap();
  }

  bool _isBootstrapping = true;
  bool get isBootstrapping => _isBootstrapping;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _authRepository.isAuthenticated;
  String? get userId => _authRepository.userId;
  String? get email => _authRepository.email;
  String? get name => _authRepository.name;

  Future<void> _bootstrap() async {
    await _authRepository.bootstrapSession();
    _isBootstrapping = false;
    notifyListeners();
  }

  Future<void> register({
    required String email,
    required String password,
    String? name,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.register(
        email: email,
        password: password,
        name: name,
      );
    } on ApiException catch (e) {
      _errorMessage = e.error.message;
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> login({required String email, required String password}) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.login(email: email, password: password);
    } on ApiException catch (e) {
      _errorMessage = e.error.message;
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _errorMessage = null;
    await _authRepository.logout();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _handleSessionChange() {
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionRepository.removeListener(_handleSessionChange);
    super.dispose();
  }
}
