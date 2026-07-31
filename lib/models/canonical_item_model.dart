DateTime _readDateTimeValue(Object? value) {
  final raw = value?.toString();
  if (raw == null || raw.isEmpty) {
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
  return DateTime.parse(raw);
}

class CanonicalItemModel {
  final String id;
  final String name;
  final String? normalizedName;
  final String? category;
  final String? createdBy;
  final DateTime createdAt;

  const CanonicalItemModel({
    required this.id,
    required this.name,
    this.normalizedName,
    this.category,
    this.createdBy,
    required this.createdAt,
  });

  factory CanonicalItemModel.fromJson(Map<String, dynamic> json) {
    return CanonicalItemModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      normalizedName: json['normalizedName']?.toString(),
      category: json['category']?.toString(),
      createdBy: json['createdBy']?.toString(),
      createdAt: _readDateTimeValue(json['createdAt']),
    );
  }
}
