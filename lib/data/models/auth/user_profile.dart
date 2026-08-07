import 'company_profile.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.roles,
    required this.permissions,
    this.externalId,
    this.username,
    this.fullName,
    this.company,
    this.email,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final companyJson = json['company'];
    final rolesJson = json['roles'];
    final permissionsJson = json['permissions'];

    return switch (json) {
      {'id': int id} => UserProfile(
        id: id,
        externalId: json['externalId'] as String?,
        username: json['username'] as String?,
        fullName: json['fullName'] as String?,
        company: companyJson is Map<String, dynamic>
            ? CompanyProfile.fromJson(companyJson)
            : null,
        email: json['email'] as String?,
        roles: rolesJson is List
            ? rolesJson.whereType<String>().toList(growable: false)
            : const [],
        permissions: permissionsJson is List
            ? permissionsJson.whereType<String>().toList(growable: false)
            : const [],
      ),
      _ => throw const FormatException('Invalid user profile.'),
    };
  }

  final int id;
  final String? externalId;
  final String? username;
  final String? fullName;
  final CompanyProfile? company;
  final String? email;
  final List<String> roles;
  final List<String> permissions;

  String get displayName => fullName?.trim().isNotEmpty == true
      ? fullName!.trim()
      : (username?.trim().isNotEmpty == true ? username!.trim() : 'Usuario');

  Map<String, dynamic> toJson() => {
    'id': id,
    'externalId': externalId,
    'username': username,
    'fullName': fullName,
    'company': company?.toJson(),
    'email': email,
    'roles': roles,
    'permissions': permissions,
  };
}
