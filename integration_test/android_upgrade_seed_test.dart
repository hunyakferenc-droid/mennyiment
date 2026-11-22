// Executed against rebuilt, pinned #50 app source, NOT the current app code.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'android33_flows.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Pinned #50 creates real profile, journal, favorite, XP and fitness before same-key update',
    (t) async {
      await firstUse33(t, isReview: true);
    },
  );
}
