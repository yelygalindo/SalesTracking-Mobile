import 'dart:convert';

import 'customer_input.dart';

enum PendingCustomerOperationType { create }

class PendingCustomerOperation {
  const PendingCustomerOperation({
    required this.requestId,
    required this.localCustomerId,
    required this.type,
    required this.input,
    required this.createdAtUtc,
    this.attemptCount = 0,
    this.lastError,
  });

  factory PendingCustomerOperation.fromMap(Map<String, Object?> map) {
    final payload = jsonDecode(map['payload'] as String);
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('Invalid customer operation payload.');
    }
    return PendingCustomerOperation(
      requestId: map['request_id'] as String,
      localCustomerId: map['local_customer_id'] as String,
      type: PendingCustomerOperationType.values.byName(
        map['operation_type'] as String,
      ),
      input: CustomerInput.fromJson(payload),
      createdAtUtc: DateTime.parse(map['created_at_utc'] as String).toUtc(),
      attemptCount: map['attempt_count'] as int? ?? 0,
      lastError: map['last_error'] as String?,
    );
  }

  final String requestId;
  final String localCustomerId;
  final PendingCustomerOperationType type;
  final CustomerInput input;
  final DateTime createdAtUtc;
  final int attemptCount;
  final String? lastError;

  Map<String, Object?> toMap() => {
    'request_id': requestId,
    'local_customer_id': localCustomerId,
    'operation_type': type.name,
    'payload': jsonEncode(input.toJson()),
    'attempt_count': attemptCount,
    'last_error': lastError,
    'created_at_utc': createdAtUtc.toUtc().toIso8601String(),
  };
}
