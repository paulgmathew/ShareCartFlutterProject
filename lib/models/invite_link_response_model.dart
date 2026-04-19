class InviteLinkResponseModel {
  final String inviteUrl;

  const InviteLinkResponseModel({required this.inviteUrl});

  factory InviteLinkResponseModel.fromJson(Map<String, dynamic> json) {
    return InviteLinkResponseModel(inviteUrl: json['inviteUrl'] as String);
  }
}
