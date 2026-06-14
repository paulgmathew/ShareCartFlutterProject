enum ReceiptScanType { receipt, priceTag }

extension ReceiptScanTypeX on ReceiptScanType {
  String get apiValue => switch (this) {
    ReceiptScanType.receipt => 'RECEIPT',
    ReceiptScanType.priceTag => 'PRICE_TAG',
  };
}

ReceiptScanType _receiptScanTypeFromJson(Object? value) {
  final normalized = value?.toString().trim().toUpperCase();
  switch (normalized) {
    case 'PRICE_TAG':
      return ReceiptScanType.priceTag;
    case 'RECEIPT':
    default:
      return ReceiptScanType.receipt;
  }
}

double? _readDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}

class ReceiptExtractionItemModel {
  final String name;
  final double? price;
  final String? quantity;
  final String? unit;
  final double? confidence;

  const ReceiptExtractionItemModel({
    required this.name,
    this.price,
    this.quantity,
    this.unit,
    this.confidence,
  });

  factory ReceiptExtractionItemModel.fromJson(Map<String, dynamic> json) {
    return ReceiptExtractionItemModel(
      name: (json['name'] ?? '').toString(),
      price: _readDouble(json['price']),
      quantity: json['quantity']?.toString(),
      unit: json['unit']?.toString(),
      confidence: _readDouble(json['confidence']),
    );
  }

  String toCaptureLine() {
    final buffer = StringBuffer('- $name');
    if (price != null) {
      buffer.write(' | price: ${price!.toStringAsFixed(2)}');
    }
    if (quantity != null && quantity!.trim().isNotEmpty) {
      buffer.write(' | quantity: ${quantity!.trim()}');
    }
    if (unit != null && unit!.trim().isNotEmpty) {
      buffer.write(' | unit: ${unit!.trim()}');
    }
    if (confidence != null) {
      buffer.write(' | confidence: ${confidence!.toStringAsFixed(2)}');
    }
    return buffer.toString();
  }
}

class ReceiptExtractionResultModel {
  final bool success;
  final String? storeName;
  final double? confidence;
  final ReceiptScanType scanType;
  final List<ReceiptExtractionItemModel> items;
  final String? message;

  const ReceiptExtractionResultModel({
    required this.success,
    required this.storeName,
    required this.confidence,
    required this.scanType,
    required this.items,
    required this.message,
  });

  factory ReceiptExtractionResultModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items =
        rawItems is List
            ? rawItems
                .whereType<Map>()
                .map(
                  (item) => ReceiptExtractionItemModel.fromJson(
                    item.cast<String, dynamic>(),
                  ),
                )
                .toList(growable: false)
            : const <ReceiptExtractionItemModel>[];

    return ReceiptExtractionResultModel(
      success: json['success'] == true,
      storeName: json['storeName']?.toString(),
      confidence: _readDouble(json['confidence']),
      scanType: _receiptScanTypeFromJson(json['scanType']),
      items: items,
      message: json['message']?.toString(),
    );
  }

  ReceiptExtractionItemModel? get primaryItem =>
      items.isNotEmpty ? items.first : null;

  String get displayText {
    if (!success) {
      return message ?? 'Unable to confidently extract grocery items.';
    }

    final buffer = StringBuffer();
    if (storeName != null && storeName!.trim().isNotEmpty) {
      buffer.writeln('Store: ${storeName!.trim()}');
    }
    buffer.writeln('Scan type: ${scanType.apiValue}');
    if (confidence != null) {
      buffer.writeln('Confidence: ${confidence!.toStringAsFixed(2)}');
    }
    if (items.isNotEmpty) {
      buffer.writeln('Items:');
      for (final item in items) {
        buffer.writeln(item.toCaptureLine());
      }
    } else {
      buffer.writeln('No line items were returned by the AI service.');
    }
    return buffer.toString().trim();
  }

  String toCaptureText() => displayText;
}
