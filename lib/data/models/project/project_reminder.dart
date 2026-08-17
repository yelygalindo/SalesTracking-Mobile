import '../common/user_reference.dart';

class ProjectReminder {
  const ProjectReminder({
    required this.id,
    required this.externalId,
    required this.text,
    required this.reminderAtUtc,
    required this.assignedTo,
    required this.completed,
  });

  factory ProjectReminder.fromJson(Map<String, dynamic> json) {
    final assignedTo = json['assignedTo'];
    return ProjectReminder(
      id: json['id'] as int? ?? 0,
      externalId: json['externalId'] as String?,
      text: json['text'] as String? ?? '',
      reminderAtUtc: _requiredDate(json['reminderAtUtc']),
      assignedTo: assignedTo is Map<String, dynamic>
          ? UserReference.fromJson(assignedTo)
          : null,
      completed: json['completed'] as bool? ?? false,
    );
  }

  final int id;
  final String? externalId;
  final String text;
  final DateTime reminderAtUtc;
  final UserReference? assignedTo;
  final bool completed;

  Map<String, dynamic> toJson() => {
    'id': id,
    'externalId': externalId,
    'text': text,
    'reminderAtUtc': reminderAtUtc.toUtc().toIso8601String(),
    'assignedTo': assignedTo?.toJson(),
    'completed': completed,
  };
}

DateTime _requiredDate(Object? value) => value is String
    ? DateTime.tryParse(value)?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)
    : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
