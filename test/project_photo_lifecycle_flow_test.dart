import 'package:flutter_test/flutter_test.dart';

import 'support/project_photo_lifecycle_flow.dart';

void main() {
  testWidgets(
    'seller queues camera and gallery evidence for an offline project visit',
    runProjectPhotoLifecycleFlow,
  );
}
