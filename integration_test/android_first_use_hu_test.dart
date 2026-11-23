import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'android33_flows.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Fresh offline Hungarian onboarding and first journal entry', (t) {
    return firstUse33(t, isReview: false, locale: 'hu');
  });
}
