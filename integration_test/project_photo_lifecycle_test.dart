import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/project_photo_lifecycle_flow.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'seller queues camera and gallery evidence for an offline project visit',
    runProjectPhotoLifecycleFlow,
  );
}
