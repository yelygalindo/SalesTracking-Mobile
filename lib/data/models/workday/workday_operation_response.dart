import 'workday.dart';

class WorkdayOperationResponse {
  const WorkdayOperationResponse({required this.workday, this.message});

  factory WorkdayOperationResponse.fromJson(Map<String, dynamic> json) {
    final workdayJson = json['workday'];
    if (workdayJson is! Map<String, dynamic>) {
      throw const FormatException('Missing workday response.');
    }
    return WorkdayOperationResponse(
      workday: Workday.fromJson(workdayJson),
      message: json['message'] as String?,
    );
  }

  final Workday workday;
  final String? message;
}
