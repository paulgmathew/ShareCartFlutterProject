import 'item_model.dart';

class ListRealtimeEventModel {
  final String eventType;
  final String listId;
  final ItemModel item;
  final DateTime occurredAt;

  const ListRealtimeEventModel({
    required this.eventType,
    required this.listId,
    required this.item,
    required this.occurredAt,
  });

  factory ListRealtimeEventModel.fromJson(Map<String, dynamic> json) {
    return ListRealtimeEventModel(
      eventType: json['eventType'] as String,
      listId: json['listId'] as String,
      item: ItemModel.fromJson(json['item'] as Map<String, dynamic>),
      occurredAt: DateTime.parse(json['occurredAt'] as String),
    );
  }
}
