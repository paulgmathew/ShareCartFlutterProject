import 'item_model.dart';
import 'member_model.dart';

class ShoppingListModel {
  final String id;
  final String name;
  final String? ownerId;
  final String? ownerName;
  final List<ItemModel> items;
  final List<MemberModel> members;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ShoppingListModel({
    required this.id,
    required this.name,
    this.ownerId,
    this.ownerName,
    required this.items,
    required this.members,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShoppingListModel.fromJson(Map<String, dynamic> json) {
    return ShoppingListModel(
      id: json['id'] as String,
      name: json['name'] as String,
      ownerId: json['ownerId'] as String?,
      ownerName: json['ownerName'] as String?,
      items:
          (json['items'] as List<dynamic>)
              .map((e) => ItemModel.fromJson(e as Map<String, dynamic>))
              .toList(),
      members:
          (json['members'] as List<dynamic>)
              .map((e) => MemberModel.fromJson(e as Map<String, dynamic>))
              .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'items': items.map((e) => e.toJson()).toList(),
      'members': members.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
