class ApiErrorModel {
  final DateTime? timestamp;
  final int status;
  final String error;
  final String message;
  final Map<String, dynamic>? details;

  const ApiErrorModel({
    this.timestamp,
    required this.status,
    required this.error,
    required this.message,
    this.details,
  });

  factory ApiErrorModel.fromJson(Map<String, dynamic> json) {
    return ApiErrorModel(
      timestamp:
          json['timestamp'] != null
              ? DateTime.parse(json['timestamp'] as String)
              : null,
      status: json['status'] as int,
      error: json['error'] as String,
      message: json['message'] as String,
      details: json['details'] as Map<String, dynamic>?,
    );
  }
}
