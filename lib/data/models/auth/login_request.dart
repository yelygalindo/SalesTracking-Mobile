class LoginRequest {
  const LoginRequest({
    required this.email,
    required this.password,
    required this.deviceType,
    required this.deviceId,
  });

  final String email;
  final String password;
  final String deviceType;
  final String deviceId;

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'deviceType': deviceType,
    'deviceId': deviceId,
  };
}
