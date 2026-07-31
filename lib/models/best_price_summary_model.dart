double _readDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? 0;
  return 0;
}

class BestPriceSummaryModel {
  final String? canonicalItemId;
  final String itemName;
  final double lowestPrice;
  final String? storeId;
  final String? storeName;

  const BestPriceSummaryModel({
    required this.canonicalItemId,
    required this.itemName,
    required this.lowestPrice,
    required this.storeId,
    required this.storeName,
  });

  factory BestPriceSummaryModel.fromJson(Map<String, dynamic> json) {
    return BestPriceSummaryModel(
      canonicalItemId: json['canonicalItemId']?.toString(),
      itemName: (json['itemName'] ?? '').toString(),
      lowestPrice:
          json['lowestPrice'] == null ? 0 : _readDouble(json['lowestPrice']),
      storeId: json['storeId']?.toString(),
      storeName: json['storeName']?.toString(),
    );
  }
}
