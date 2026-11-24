import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'android33_flows.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android beta clean EN 320/200 offline first use and persisted favorite',
    (t) async {
      await firstUse33(t, isReview: false, verifyJournalMutations: true);
    },
  );
}
