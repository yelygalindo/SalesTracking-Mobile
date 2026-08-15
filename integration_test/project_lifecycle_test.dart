import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/project_lifecycle_flow.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'seller manages the complete project lifecycle from the UI',
    runProjectLifecycleFlow,
  );
}
