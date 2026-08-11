import '../common/user_reference.dart';

class ProjectNote {
  const ProjectNote({
    required this.id,
    required this.externalId,
    required this.content,
    required this.createdBy,
    required this.createdAtUtc,
    required this.occurredAtUtc,
    required this.receivedAtUtc,
    required this.updatedBy,
    required this.updatedAtUtc,
  });

  factory ProjectNote.fromJson(Map<String, dynamic> json) {
    final createdBy = json['createdBy'];
    final updatedBy = json['updatedBy'];
    return ProjectNote(
      id: json['id'] as int? ?? 0,
      externalId: json['externalId'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdBy: createdBy is Map<String, dynamic>
          ? UserReference.fromJson(createdBy)
          : null,
      createdAtUtc: _requiredDate(json['createdAtUtc']),
      occurredAtUtc: _requiredDate(json['occurredAtUtc']),
      receivedAtUtc: _requiredDate(json['receivedAtUtc']),
      updatedBy: updatedBy is Map<String, dynamic>
          ? UserReference.fromJson(updatedBy)
          : null,
      updatedAtUtc: _optionalDate(json['updatedAtUtc']),
    );
  }

  final int id;
  final String externalId;
  final String content;
  final UserReference? createdBy;
  final DateTime createdAtUtc;
  final DateTime occurredAtUtc;
  final DateTime receivedAtUtc;
  final UserReference? updatedBy;
  final DateTime? updatedAtUtc;

  Map<String, dynamic> toJson() => {
    'id': id,
    'externalId': externalId,
    'content': content,
    'createdBy': createdBy?.toJson(),
    'createdAtUtc': createdAtUtc.toUtc().toIso8601String(),
    'occurredAtUtc': occurredAtUtc.toUtc().toIso8601String(),
    'receivedAtUtc': receivedAtUtc.toUtc().toIso8601String(),
    'updatedBy': updatedBy?.toJson(),
    'updatedAtUtc': updatedAtUtc?.toUtc().toIso8601String(),
  };
}

DateTime _requiredDate(Object? value) =>
    _optionalDate(value) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

DateTime? _optionalDate(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toUtc() : null;
