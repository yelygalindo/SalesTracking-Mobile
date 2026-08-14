import 'package:flutter_test/flutter_test.dart';

import 'support/workday_lifecycle_flow.dart';

void main() {
  testWidgets(
    'seller starts and closes a GPS workday from the UI',
    runWorkdayLifecycleFlow,
  );
}
