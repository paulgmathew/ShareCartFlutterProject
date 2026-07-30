double _readDoubleValue(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value.trim()) ?? 0;
  }
  return 0;
}

DateTime _readDateTimeValue(Object? value) {
  final raw = value?.toString();
  if (raw == null || raw.isEmpty) {
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
  return DateTime.parse(raw);
}

class ItemPriceModel {
  final String id;
  final String itemName;
  final String? normalizedName;
  final String? storeId;
  final String? storeName;
  final double price;
  final String? unit;
  final DateTime capturedAt;
  final String source;
  final String? createdBy;
  final DateTime createdAt;

  const ItemPriceModel({
    required this.id,
    required this.itemName,
    this.normalizedName,
    this.storeId,
    this.storeName,
    required this.price,
    this.unit,
    required this.capturedAt,
    required this.source,
    this.createdBy,
    required this.createdAt,
  });

  factory ItemPriceModel.fromJson(Map<String, dynamic> json) {
    return ItemPriceModel(
      id: (json['id'] ?? '').toString(),
      itemName: (json['itemName'] ?? '').toString(),
      normalizedName: json['normalizedName']?.toString(),
      storeId: json['storeId']?.toString(),
      storeName: json['storeName']?.toString(),
      price: _readDoubleValue(json['price']),
      unit: json['unit']?.toString(),
      capturedAt: _readDateTimeValue(json['capturedAt']),
      source: (json['source'] ?? '').toString(),
      createdBy: json['createdBy']?.toString(),
      createdAt: _readDateTimeValue(json['createdAt']),
    );
  }
}
