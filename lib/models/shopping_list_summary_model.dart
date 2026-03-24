class ShoppingListSummaryModel {
  final String id;
  final String name;
  final String? ownerId;
  final String? ownerName;
  final String? memberRole;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ShoppingListSummaryModel({
    required this.id,
    required this.name,
    this.ownerId,
    this.ownerName,
    this.memberRole,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShoppingListSummaryModel.fromJson(Map<String, dynamic> json) {
    return ShoppingListSummaryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      ownerId: json['ownerId'] as String?,
      ownerName: json['ownerName'] as String?,
      memberRole: json['memberRole'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
