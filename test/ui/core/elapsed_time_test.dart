import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/ui/core/elapsed_time.dart';

void main() {
  test('elapsedSince returns elapsed time for a past start', () {
    final now = DateTime.utc(2026, 8, 17, 18, 30);

    expect(
      elapsedSince(DateTime.utc(2026, 8, 17, 16, 15), now: now),
      const Duration(hours: 2, minutes: 15),
    );
  });

  test('elapsedSince clamps a future start to zero', () {
    final now = DateTime.utc(2026, 8, 17, 18, 30);

    expect(
      elapsedSince(DateTime.utc(2026, 8, 18, 16, 15), now: now),
      Duration.zero,
    );
  });

  test('formatHoursMinutes never displays a negative duration', () {
    expect(formatHoursMinutes(const Duration(minutes: -21)), '0h 00m');
  });
}
