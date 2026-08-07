class UserReference {
  const UserReference({required this.externalId, required this.name});

  factory UserReference.fromJson(Map<String, dynamic> json) => UserReference(
    externalId: json['externalId'] as String?,
    name: json['name'] as String? ?? '',
  );

  final String? externalId;
  final String name;

  Map<String, dynamic> toJson() => {'externalId': externalId, 'name': name};
}
