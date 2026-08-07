import 'user_profile.dart';

class AuthSession {
  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAtUtc,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'user': Map<String, dynamic> user,
        'accessToken': String accessToken,
        'refreshToken': String refreshToken,
        'expiresAtUtc': String expiresAtUtc,
      }
          when accessToken.isNotEmpty && refreshToken.isNotEmpty =>
        AuthSession(
          user: UserProfile.fromJson(user),
          accessToken: accessToken,
          refreshToken: refreshToken,
          expiresAtUtc: DateTime.parse(expiresAtUtc).toUtc(),
        ),
      _ => throw const FormatException('Invalid authentication session.'),
    };
  }

  final UserProfile user;
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAtUtc;

  bool get isExpired => expiresAtUtc.isBefore(
    DateTime.now().toUtc().add(const Duration(seconds: 30)),
  );

  AuthSession withTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAtUtc,
  }) {
    return AuthSession(
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAtUtc: expiresAtUtc,
    );
  }

  Map<String, dynamic> toJson() => {
    'user': user.toJson(),
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresAtUtc': expiresAtUtc.toUtc().toIso8601String(),
  };
}
