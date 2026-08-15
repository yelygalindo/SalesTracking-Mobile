import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/real_media_attachment_flow.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'seller captures and persists a real camera photo offline',
    (tester) => runRealMediaAttachmentFlow(tester, RealMediaSource.camera),
  );
}
