import 'package:flutter_test/flutter_test.dart';

import 'support/customer_lifecycle_flow.dart';

void main() {
  testWidgets(
    'seller manages the complete customer lifecycle from the UI',
    runCustomerLifecycleFlow,
  );
}
