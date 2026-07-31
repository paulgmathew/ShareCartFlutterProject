import 'nearby_store_model.dart';

class PriceComparisonModel {
  final String? itemName;
  final String? normalizedName;
  final String? message;
  final String? bestStoreId;
  final String? bestStoreName;
  final double? bestPrice;
  final String? bestUnit;
  final List<NearbyStoreModel> stores;
  final Map<String, dynamic> raw;

  const PriceComparisonModel({
    required this.itemName,
    required this.normalizedName,
    required this.message,
    required this.bestStoreId,
    required this.bestStoreName,
    required this.bestPrice,
    required this.bestUnit,
    required this.stores,
    required this.raw,
  });

  factory PriceComparisonModel.fromJson(Map<String, dynamic> json) {
    final storeSources = <Map<String, dynamic>>[];
    for (final key in ['stores', 'results', 'items', 'comparisons']) {
      final value = json[key];
      if (value is List) {
        storeSources.addAll(
          value.whereType<Map>().map((e) => e.cast<String, dynamic>()),
        );
      }
    }

    final bestStore =
        json['bestStore'] is Map
            ? (json['bestStore'] as Map).cast<String, dynamic>()
            : null;

    return PriceComparisonModel(
      itemName: json['itemName']?.toString(),
      normalizedName: json['normalizedName']?.toString(),
      message: json['message']?.toString(),
      bestStoreId:
          (json['bestStoreId'] ?? bestStore?['id'] ?? bestStore?['storeId'])
              ?.toString(),
      bestStoreName:
          (json['bestStoreName'] ??
                  bestStore?['name'] ??
                  bestStore?['storeName'])
              ?.toString(),
      bestPrice:
          json['bestPrice'] == null ? null : _readDouble(json['bestPrice']),
      bestUnit: (json['bestUnit'] ?? bestStore?['unit'])?.toString(),
      stores: storeSources
          .map(NearbyStoreModel.fromJson)
          .toList(growable: false),
      raw: json,
    );
  }

  bool get hasStores => stores.isNotEmpty;
}

double _readDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? 0;
  return 0;
}
