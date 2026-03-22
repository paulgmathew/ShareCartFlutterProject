class ItemModel {
  final String id;
  final String listId;
  final String name;
  final String? quantity;
  final bool isCompleted;
  final String? category;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ItemModel({
    required this.id,
    required this.listId,
    required this.name,
    this.quantity,
    required this.isCompleted,
    this.category,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'] as String,
      listId: json['listId'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] as String?,
      isCompleted: json['isCompleted'] as bool,
      category: json['category'] as String?,
      createdBy: json['createdBy'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'listId': listId,
      'name': name,
      'quantity': quantity,
      'isCompleted': isCompleted,
      'category': category,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ItemModel copyWith({
    String? id,
    String? listId,
    String? name,
    String? quantity,
    bool? isCompleted,
    String? category,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ItemModel(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      isCompleted: isCompleted ?? this.isCompleted,
      category: category ?? this.category,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
