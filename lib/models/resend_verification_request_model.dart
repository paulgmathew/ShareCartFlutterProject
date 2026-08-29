class ResendVerificationRequestModel {
  final String email;

  const ResendVerificationRequestModel({required this.email});

  factory ResendVerificationRequestModel.fromJson(Map<String, dynamic> json) {
    return ResendVerificationRequestModel(
      email: (json['email'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'email': email};
}
