import '../common/user_reference.dart';

class CustomerNote {
  const CustomerNote({
    required this.id,
    required this.externalId,
    required this.text,
    required this.author,
    required this.createdAtUtc,
  });

  factory CustomerNote.fromJson(Map<String, dynamic> json) {
    final author = json['author'];
    return CustomerNote(
      id: json['id'] as int? ?? 0,
      externalId: json['externalId'] as String?,
      text: json['text'] as String? ?? '',
      author: author is Map<String, dynamic>
          ? UserReference.fromJson(author)
          : null,
      createdAtUtc: _requiredDate(json['createdAt']),
    );
  }

  final int id;
  final String? externalId;
  final String text;
  final UserReference? author;
  final DateTime createdAtUtc;

  Map<String, dynamic> toJson() => {
    'id': id,
    'externalId': externalId,
    'text': text,
    'author': author?.toJson(),
    'createdAt': createdAtUtc.toUtc().toIso8601String(),
  };
}

DateTime _requiredDate(Object? value) {
  return value is String
      ? DateTime.tryParse(value)?.toUtc() ??
            DateTime.fromMillisecondsSinceEpoch(0)
      : DateTime.fromMillisecondsSinceEpoch(0);
}
