import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/real_location_failure_flow.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'workday stays closed when the user rejects location permission',
    runLocationPermissionDeniedFlow,
  );
}
