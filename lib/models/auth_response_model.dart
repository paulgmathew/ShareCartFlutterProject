class AuthResponseModel {
  final String token;
  final String tokenType;
  final String userId;
  final String email;
  final String? name;

  const AuthResponseModel({
    required this.token,
    required this.tokenType,
    required this.userId,
    required this.email,
    this.name,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      token: json['token'] as String,
      tokenType: json['tokenType'] as String,
      userId: json['userId'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'tokenType': tokenType,
      'userId': userId,
      'email': email,
      'name': name,
    };
  }
}
