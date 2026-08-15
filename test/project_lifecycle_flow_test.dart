import 'package:flutter_test/flutter_test.dart';

import 'support/project_lifecycle_flow.dart';

void main() {
  testWidgets(
    'seller manages the complete project lifecycle from the UI',
    runProjectLifecycleFlow,
  );
}
