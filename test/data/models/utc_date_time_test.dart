import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/data/models/common/utc_date_time.dart';
import 'package:urbantrack/data/models/customer/customer_note.dart';

void main() {
  test('treats an API timestamp without suffix as UTC', () {
    final parsed = parseUtcDateTime('2026-08-17T18:30:09.419');

    expect(parsed.isUtc, isTrue);
    expect(parsed, DateTime.utc(2026, 8, 17, 18, 30, 9, 419));
  });

  test('normalizes an explicit offset to UTC', () {
    final parsed = parseUtcDateTime('2026-08-17T14:30:00-04:00');

    expect(parsed, DateTime.utc(2026, 8, 17, 18, 30));
  });

  test('prefers the real occurrence time returned for a note', () {
    final note = CustomerNote.fromJson({
      'id': 1,
      'externalId': 'note-id',
      'text': 'Visita realizada',
      'occurredAtUtc': '2026-08-17T14:30:00',
      'createdAt': '2026-08-17T18:31:00',
    });

    expect(note.createdAtUtc, DateTime.utc(2026, 8, 17, 14, 30));
  });
}
