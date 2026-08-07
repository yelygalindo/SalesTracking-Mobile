import '../common/user_reference.dart';

class CustomerReminder {
  const CustomerReminder({
    required this.id,
    required this.externalId,
    required this.text,
    required this.reminderAtUtc,
    required this.assignedTo,
    required this.completed,
  });

  factory CustomerReminder.fromJson(Map<String, dynamic> json) {
    final assignedTo = json['assignedTo'];
    return CustomerReminder(
      id: json['id'] as int? ?? 0,
      externalId: json['externalId'] as String?,
      text: json['text'] as String? ?? '',
      reminderAtUtc: _requiredDate(json['reminderAt']),
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
    'reminderAt': reminderAtUtc.toUtc().toIso8601String(),
    'assignedTo': assignedTo?.toJson(),
    'completed': completed,
  };
}

DateTime _requiredDate(Object? value) {
  return value is String
      ? DateTime.tryParse(value)?.toUtc() ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)
      : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}
