double _readDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? 0;
  return 0;
}

DateTime _readDateTime(Object? value) {
  final raw = value?.toString();
  if (raw == null || raw.isEmpty) {
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
  return DateTime.parse(raw);
}

class NearbyStoreModel {
  final String id;
  final String name;
  final String? address;
  final double? latitude;
  final double? longitude;
  final double? distanceMeters;
  final double? distanceKm;
  final double? price;
  final String? unit;
  final DateTime? capturedAt;
  final String? source;

  const NearbyStoreModel({
    required this.id,
    required this.name,
    this.address,
    this.latitude,
    this.longitude,
    this.distanceMeters,
    this.distanceKm,
    this.price,
    this.unit,
    this.capturedAt,
    this.source,
  });

  factory NearbyStoreModel.fromJson(Map<String, dynamic> json) {
    return NearbyStoreModel(
      id: (json['id'] ?? json['storeId'] ?? '').toString(),
      name: (json['name'] ?? json['storeName'] ?? '').toString(),
      address: json['address']?.toString(),
      latitude: json['latitude'] == null ? null : _readDouble(json['latitude']),
      longitude:
          json['longitude'] == null ? null : _readDouble(json['longitude']),
      distanceMeters:
          json['distanceMeters'] == null
              ? null
              : _readDouble(json['distanceMeters']),
      distanceKm:
          json['distanceKm'] == null ? null : _readDouble(json['distanceKm']),
      price: json['price'] == null ? null : _readDouble(json['price']),
      unit: json['unit']?.toString(),
      capturedAt:
          json['capturedAt'] == null ? null : _readDateTime(json['capturedAt']),
      source: json['source']?.toString(),
    );
  }

  String get distanceLabel {
    final meters = distanceMeters;
    final kilometers = distanceKm;
    if (meters != null && meters > 0) {
      if (meters >= 1000) {
        return '${(meters / 1000).toStringAsFixed(1)} km';
      }
      return '${meters.toStringAsFixed(0)} m';
    }
    if (kilometers != null && kilometers > 0) {
      return '${kilometers.toStringAsFixed(1)} km';
    }
    return 'distance n/a';
  }
}
