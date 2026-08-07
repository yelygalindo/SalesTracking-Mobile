class CompanyProfile {
  const CompanyProfile({required this.id, this.externalId, this.name});

  factory CompanyProfile.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {'id': int id} => CompanyProfile(
        id: id,
        externalId: json['externalId'] as String?,
        name: json['name'] as String?,
      ),
      _ => throw const FormatException('Invalid company profile.'),
    };
  }

  final int id;
  final String? externalId;
  final String? name;

  Map<String, dynamic> toJson() => {
    'id': id,
    'externalId': externalId,
    'name': name,
  };
}
