import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/visit_lifecycle_flow.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'seller checks in and out of a customer visit from the UI',
    runVisitLifecycleFlow,
  );
}
