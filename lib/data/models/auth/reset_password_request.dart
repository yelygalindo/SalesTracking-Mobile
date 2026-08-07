class ResetPasswordRequest {
  const ResetPasswordRequest({
    required this.token,
    required this.newPassword,
    required this.confirmPassword,
  });

  final String token;
  final String newPassword;
  final String confirmPassword;

  Map<String, dynamic> toJson() => {
    'token': token,
    'newPassword': newPassword,
    'confirmPassword': confirmPassword,
  };
}
