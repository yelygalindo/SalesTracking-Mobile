import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/workday_lifecycle_flow.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'seller starts and closes a GPS workday from the UI',
    runWorkdayLifecycleFlow,
  );
}
