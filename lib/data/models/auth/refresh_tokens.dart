class RefreshTokens {
  const RefreshTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAtUtc,
  });

  factory RefreshTokens.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'accessToken': String accessToken,
        'refreshToken': String refreshToken,
        'expiresAtUtc': String expiresAtUtc,
      }
          when accessToken.isNotEmpty && refreshToken.isNotEmpty =>
        RefreshTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
          expiresAtUtc: DateTime.parse(expiresAtUtc).toUtc(),
        ),
      _ => throw const FormatException('Invalid refreshed tokens.'),
    };
  }

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAtUtc;
}
