class InvitePreviewModel {
  final String listName;
  final String? ownerName;

  const InvitePreviewModel({required this.listName, this.ownerName});

  factory InvitePreviewModel.fromJson(Map<String, dynamic> json) {
    return InvitePreviewModel(
      listName: json['listName'] as String,
      ownerName: json['ownerName'] as String?,
    );
  }
}
