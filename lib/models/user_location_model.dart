double _readLocationDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? 0;
  return 0;
}

class UserLocationModel {
  final double latitude;
  final double longitude;
  final String? address;

  const UserLocationModel({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  factory UserLocationModel.fromJson(Map<String, dynamic> json) {
    return UserLocationModel(
      latitude: _readLocationDouble(json['latitude']),
      longitude: _readLocationDouble(json['longitude']),
      address: json['address']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final body = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
    };
    if (address != null && address!.trim().isNotEmpty) {
      body['address'] = address;
    }
    return body;
  }
}
