import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/ui/core/note_input_limit.dart';

void main() {
  test('accepts the boundary and rejects a longer pasted note', () {
    expect(validateNote(List.filled(maxNoteCharacters, 'a').join()), isNull);
    expect(
      validateNote(List.filled(maxNoteCharacters + 1, 'a').join()),
      contains('$maxNoteCharacters caracteres'),
    );
  });

  test('counts visible characters consistently with Flutter TextField', () {
    expect(validateNote(List.filled(maxNoteCharacters, '😊').join()), isNull);
    expect(
      validateNote(List.filled(maxNoteCharacters + 1, '😊').join()),
      isNotNull,
    );
  });
}
