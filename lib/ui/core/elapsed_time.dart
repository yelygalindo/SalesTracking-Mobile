Duration elapsedSince(DateTime startedAt, {DateTime? now}) {
  final elapsed = (now ?? DateTime.now()).difference(startedAt);
  return elapsed.isNegative ? Duration.zero : elapsed;
}

String formatHoursMinutes(Duration value) {
  final safeValue = value.isNegative ? Duration.zero : value;
  final hours = safeValue.inHours;
  final minutes = safeValue.inMinutes.remainder(60);
  return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
}
