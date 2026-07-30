import 'receipt_extraction_model.dart';

num? _readNum(Object? value) {
  if (value is num) return value;
  if (value is String) {
    return num.tryParse(value.trim());
  }
  return null;
}

ReceiptScanType _confirmScanTypeFromJson(Object? value) {
  final normalized = value?.toString().trim().toUpperCase();
  switch (normalized) {
    case 'PRICE_TAG':
      return ReceiptScanType.priceTag;
    case 'RECEIPT':
    default:
      return ReceiptScanType.receipt;
  }
}

num _compactNum(num value) {
  if (value is int) return value;
  return value == value.roundToDouble() ? value.toInt() : value;
}

class StoreInfo {
  final String name;
  final String? address;
  final double? latitude;
  final double? longitude;

  const StoreInfo({
    required this.name,
    this.address,
    this.latitude,
    this.longitude,
  });

  factory StoreInfo.fromJson(Map<String, dynamic> json) {
    return StoreInfo(
      name: (json['name'] ?? '').toString(),
      address: json['address']?.toString(),
      latitude: _readNum(json['latitude'])?.toDouble(),
      longitude: _readNum(json['longitude'])?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'name': name};
    if (address != null && address!.trim().isNotEmpty) {
      json['address'] = address;
    }
    if (latitude != null) json['latitude'] = latitude;
    if (longitude != null) json['longitude'] = longitude;
    return json;
  }
}

class ConfirmPriceItem {
  final String itemName;
  final double price;
  final num quantity;
  final String unit;
  final double? confidence;
  final bool edited;

  const ConfirmPriceItem({
    required this.itemName,
    required this.price,
    required this.quantity,
    required this.unit,
    required this.confidence,
    required this.edited,
  });

  factory ConfirmPriceItem.fromJson(Map<String, dynamic> json) {
    return ConfirmPriceItem(
      itemName: (json['itemName'] ?? '').toString(),
      price: _readNum(json['price'])?.toDouble() ?? 0,
      quantity: _readNum(json['quantity']) ?? 0,
      unit: (json['unit'] ?? '').toString(),
      confidence: _readNum(json['confidence'])?.toDouble(),
      edited: json['edited'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'itemName': itemName,
      'price': price,
      'quantity': _compactNum(quantity),
      'unit': unit,
      'edited': edited,
    };
    if (confidence != null) {
      json['confidence'] = confidence;
    }
    return json;
  }
}

class ConfirmPricesRequest {
  final String captureId;
  final ReceiptScanType scanType;
  final StoreInfo store;
  final List<ConfirmPriceItem> items;
  final String source;
  final DateTime capturedAt;

  const ConfirmPricesRequest({
    required this.captureId,
    required this.scanType,
    required this.store,
    required this.items,
    required this.source,
    required this.capturedAt,
  });

  factory ConfirmPricesRequest.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return ConfirmPricesRequest(
      captureId: (json['captureId'] ?? '').toString(),
      scanType: _confirmScanTypeFromJson(json['scanType']),
      store: StoreInfo.fromJson(
        (json['store'] as Map? ?? const <String, dynamic>{})
            .cast<String, dynamic>(),
      ),
      source: (json['source'] ?? '').toString(),
      capturedAt: DateTime.parse((json['capturedAt'] ?? '').toString()),
      items:
          rawItems is List
              ? rawItems
                  .whereType<Map>()
                  .map(
                    (item) =>
                        ConfirmPriceItem.fromJson(item.cast<String, dynamic>()),
                  )
                  .toList(growable: false)
              : const <ConfirmPriceItem>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'captureId': captureId,
      'scanType': scanType.apiValue,
      'store': store.toJson(),
      'items': items.map((item) => item.toJson()).toList(growable: false),
      'source': source,
      'capturedAt': capturedAt.toUtc().toIso8601String(),
    };
  }
}
