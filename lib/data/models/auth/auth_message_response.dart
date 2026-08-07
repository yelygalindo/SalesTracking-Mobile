class AuthMessageResponse {
  const AuthMessageResponse({this.message});

  factory AuthMessageResponse.fromJson(Map<String, dynamic> json) {
    return AuthMessageResponse(message: json['message'] as String?);
  }

  final String? message;

  Map<String, dynamic> toJson() => {'message': message};
}
