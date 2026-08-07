import 'workday.dart';

class CurrentWorkdayResponse {
  const CurrentWorkdayResponse({
    required this.hasOpenWorkday,
    required this.workday,
  });

  factory CurrentWorkdayResponse.fromJson(Map<String, dynamic> json) {
    final workdayJson = json['workday'];
    return CurrentWorkdayResponse(
      hasOpenWorkday: json['hasOpenWorkday'] as bool? ?? false,
      workday: workdayJson is Map<String, dynamic>
          ? Workday.fromJson(workdayJson)
          : null,
    );
  }

  final bool hasOpenWorkday;
  final Workday? workday;
}
