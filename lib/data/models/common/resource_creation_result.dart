class ResourceCreationResult {
  const ResourceCreationResult({required this.id, required this.message});

  factory ResourceCreationResult.fromJson(Map<String, dynamic> json) =>
      ResourceCreationResult(
        id: json['id'] as String?,
        message: json['message'] as String? ?? '',
      );

  final String? id;
  final String message;

  Map<String, dynamic> toJson() => {'id': id, 'message': message};
}
