class VerifyEmailResponseModel {
  final String message;
  final String email;
  final bool emailVerified;

  const VerifyEmailResponseModel({
    required this.message,
    required this.email,
    required this.emailVerified,
  });

  factory VerifyEmailResponseModel.fromJson(Map<String, dynamic> json) {
    return VerifyEmailResponseModel(
      message: (json['message'] as String?) ?? 'Email verification finished.',
      email: (json['email'] as String?) ?? '',
      emailVerified: json['emailVerified'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {'message': message, 'email': email, 'emailVerified': emailVerified};
  }
}
