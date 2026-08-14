import 'package:flutter_test/flutter_test.dart';

import 'support/visit_lifecycle_flow.dart';

void main() {
  testWidgets(
    'seller checks in and out of a customer visit from the UI',
    runVisitLifecycleFlow,
  );
}
