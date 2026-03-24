import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_response_model.dart';

class AuthSessionRepository extends ChangeNotifier {
  static const _tokenKey = 'auth_token';
  static const _tokenTypeKey = 'auth_token_type';
  static const _userIdKey = 'auth_user_id';
  static const _emailKey = 'auth_email';
  static const _nameKey = 'auth_name';

  final FlutterSecureStorage _storage;

  String? _token;
  String? _tokenType;
  String? _userId;
  String? _email;
  String? _name;

  AuthSessionRepository(this._storage);

  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  String? get token => _token;
  String? get tokenType => _tokenType;
  String? get userId => _userId;
  String? get email => _email;
  String? get name => _name;

  Future<void> loadSession() async {
    _token = await _storage.read(key: _tokenKey);
    _tokenType = await _storage.read(key: _tokenTypeKey);
    _userId = await _storage.read(key: _userIdKey);
    _email = await _storage.read(key: _emailKey);
    _name = await _storage.read(key: _nameKey);
    notifyListeners();
  }

  Future<void> setSession(AuthResponseModel auth) async {
    _token = auth.token;
    _tokenType = auth.tokenType;
    _userId = auth.userId;
    _email = auth.email;
    _name = auth.name;

    await _storage.write(key: _tokenKey, value: auth.token);
    await _storage.write(key: _tokenTypeKey, value: auth.tokenType);
    await _storage.write(key: _userIdKey, value: auth.userId);
    await _storage.write(key: _emailKey, value: auth.email);
    await _storage.write(key: _nameKey, value: auth.name);

    notifyListeners();
  }

  Future<void> clearSession() async {
    _token = null;
    _tokenType = null;
    _userId = null;
    _email = null;
    _name = null;

    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _tokenTypeKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _nameKey);

    notifyListeners();
  }

  Future<String?> getToken() async {
    if (_token != null && _token!.isNotEmpty) {
      return _token;
    }
    _token = await _storage.read(key: _tokenKey);
    return _token;
  }
}
