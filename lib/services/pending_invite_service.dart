/// Holds an invite token that arrived before the user was authenticated.
/// The token is consumed exactly once after a successful login.
class PendingInviteService {
  String? _pendingToken;

  String? get pendingToken => _pendingToken;

  void setToken(String token) {
    _pendingToken = token;
  }

  /// Returns the pending token and clears it so it is consumed only once.
  String? consumeToken() {
    final token = _pendingToken;
    _pendingToken = null;
    return token;
  }
}
