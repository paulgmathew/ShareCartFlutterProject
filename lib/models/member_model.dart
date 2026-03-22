class MemberModel {
  final String userId;
  final String? name;
  final String email;
  final String role;
  final DateTime joinedAt;

  const MemberModel({
    required this.userId,
    this.name,
    required this.email,
    required this.role,
    required this.joinedAt,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      userId: json['userId'] as String,
      name: json['name'] as String?,
      email: json['email'] as String,
      role: json['role'] as String,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'role': role,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }
}
