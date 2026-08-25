class PriceComparisonModel {
  final double? lowestPrice;
  final String? lowestStoreId;
  final String? lowestStoreName;
  final double? averagePrice;
  final int? totalEntries;

  const PriceComparisonModel({
    required this.lowestPrice,
    required this.lowestStoreId,
    required this.lowestStoreName,
    required this.averagePrice,
    required this.totalEntries,
  });

  factory PriceComparisonModel.fromJson(Map<String, dynamic> json) {
    return PriceComparisonModel(
      lowestPrice:
          json['lowestPrice'] == null ? null : _readDouble(json['lowestPrice']),
      lowestStoreId: json['lowestStoreId']?.toString(),
      lowestStoreName: json['lowestStoreName']?.toString(),
      averagePrice:
          json['averagePrice'] == null
              ? null
              : _readDouble(json['averagePrice']),
      totalEntries: _readInt(json['totalEntries']),
    );
  }
}

double _readDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? 0;
  return 0;
}

int? _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}
