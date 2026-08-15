import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/real_gps_workday_flow.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'seller starts and closes a workday with the device GPS',
    runRealGpsWorkdayFlow,
  );
}
