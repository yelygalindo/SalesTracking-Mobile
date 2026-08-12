import 'package:flutter_test/flutter_test.dart';

import 'support/app_navigation_flow.dart';

void main() {
  testWidgets(
    'seller navigates the primary app shell and signs out',
    runAppNavigationFlow,
  );
}
