double _readDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? 0;
  return 0;
}

class NearbyStoreModel {
  final String id;
  final String name;
  final String? address;
  final double? latitude;
  final double? longitude;
  final double? distanceMeters;

  const NearbyStoreModel({
    required this.id,
    required this.name,
    this.address,
    this.latitude,
    this.longitude,
    this.distanceMeters,
  });

  factory NearbyStoreModel.fromJson(Map<String, dynamic> json) {
    final store =
        json['store'] is Map
            ? (json['store'] as Map).cast<String, dynamic>()
            : const <String, dynamic>{};

    return NearbyStoreModel(
      id: (store['id'] ?? '').toString(),
      name: (store['name'] ?? '').toString(),
      address: store['address']?.toString(),
      latitude:
          store['latitude'] == null ? null : _readDouble(store['latitude']),
      longitude:
          store['longitude'] == null ? null : _readDouble(store['longitude']),
      distanceMeters:
          json['distanceMeters'] == null
              ? null
              : _readDouble(json['distanceMeters']),
    );
  }

  String get distanceLabel {
    final meters = distanceMeters;
    if (meters != null && meters > 0) {
      if (meters >= 1000) {
        return '${(meters / 1000).toStringAsFixed(1)} km';
      }
      return '${meters.toStringAsFixed(0)} m';
    }
    return 'distance n/a';
  }
}
