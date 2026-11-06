class RegisterResponseModel {
  final String message;
  final String email;
  final bool emailVerified;

  const RegisterResponseModel({
    required this.message,
    required this.email,
    required this.emailVerified,
  });

  factory RegisterResponseModel.fromJson(Map<String, dynamic> json) {
    return RegisterResponseModel(
      message: (json['message'] as String?) ?? 'Registration successful.',
      email: (json['email'] as String?) ?? '',
      emailVerified: json['emailVerified'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {'message': message, 'email': email, 'emailVerified': emailVerified};
  }
}
