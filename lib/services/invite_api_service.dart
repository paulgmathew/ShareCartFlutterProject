import '../models/models.dart';
import 'api_client.dart';

String extractInviteToken(String inviteUrl) {
  return Uri.parse(inviteUrl).pathSegments.last;
}

class InviteApiService {
  final ApiClient _apiClient;

  InviteApiService(this._apiClient);

  /// Generates a shareable invite link for a list the current user owns.
  /// Calls POST /lists/{listId}/invite-link. Requires auth.
  Future<String> generateInviteLink(String listId) async {
    final json = await _apiClient.post('/lists/$listId/invite-link');
    return InviteLinkResponseModel.fromJson(json).inviteUrl;
  }

  /// Accepts an invite using the raw token from the URL.
  /// Calls POST /invites/{token}/accept. Requires auth.
  Future<AcceptInviteResponseModel> acceptInvite(String token) async {
    final json = await _apiClient.post('/invites/$token/accept');
    return AcceptInviteResponseModel.fromJson(json);
  }

  /// Fetches preview info for an invite link — no auth required.
  /// Calls GET /invites/{token}.
  Future<InvitePreviewModel> getInvitePreview(String token) async {
    final json = await _apiClient.getPublic('/invites/$token');
    return InvitePreviewModel.fromJson(json);
  }
}
