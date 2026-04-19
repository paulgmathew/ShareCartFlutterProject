class AcceptInviteResponseModel {
  final String listId;
  final String message;

  const AcceptInviteResponseModel({
    required this.listId,
    required this.message,
  });

  factory AcceptInviteResponseModel.fromJson(Map<String, dynamic> json) {
    return AcceptInviteResponseModel(
      listId: json['listId'] as String,
      message: json['message'] as String,
    );
  }
}
