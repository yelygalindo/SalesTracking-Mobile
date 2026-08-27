import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/ui/core/presentation_labels.dart';

void main() {
  test('localizes customer and project status API values', () {
    expect(customerStatusLabel('prospect'), 'Prospecto');
    expect(projectStatusLabel('Draft'), 'Borrador');
    expect(projectStatusLabel('Cancelled'), 'Perdido');
  });

  test('localizes raw timeline codes and keeps descriptive API titles', () {
    expect(
      timelineEventTitle(
        eventType: 'CustomerReminderCompleted',
        serverTitle: 'CustomerReminderCompleted',
      ),
      'Recordatorio completado',
    );
    expect(
      timelineEventTitle(
        eventType: 'ProjectVisitCheckedOut',
        serverTitle: 'Visita finalizada · Obra Norte',
      ),
      'Visita finalizada · Obra Norte',
    );
  });
}
