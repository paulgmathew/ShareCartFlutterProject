double _readDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? 0;
  return 0;
}

class BestStoreOptionModel {
  final String? storeId;
  final String storeName;
  final double lowestPrice;

  const BestStoreOptionModel({
    required this.storeId,
    required this.storeName,
    required this.lowestPrice,
  });

  factory BestStoreOptionModel.fromJson(Map<String, dynamic> json) {
    return BestStoreOptionModel(
      storeId: json['storeId']?.toString(),
      storeName: (json['storeName'] ?? '').toString(),
      lowestPrice:
          json['lowestPrice'] == null ? 0 : _readDouble(json['lowestPrice']),
    );
  }
}
