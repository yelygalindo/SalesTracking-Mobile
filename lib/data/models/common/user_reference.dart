class UserReference {
  const UserReference({required this.externalId, required this.name, this.id});

  factory UserReference.fromJson(Map<String, dynamic> json) => UserReference(
    id: json['id'] as int?,
    externalId: json['externalId'] as String?,
    name: json['name'] as String? ?? '',
  );

  final int? id;
  final String? externalId;
  final String name;

  Map<String, dynamic> toJson() => {
    'id': id,
    'externalId': externalId,
    'name': name,
  };
}
