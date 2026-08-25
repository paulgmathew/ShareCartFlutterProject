class CanonicalItemModel {
  final String id;
  final String name;
  final String? normalizedName;
  final String? description;

  const CanonicalItemModel({
    required this.id,
    required this.name,
    this.normalizedName,
    this.description,
  });

  factory CanonicalItemModel.fromJson(Map<String, dynamic> json) {
    return CanonicalItemModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      normalizedName: json['normalizedName']?.toString(),
      description: json['description']?.toString(),
    );
  }
}
