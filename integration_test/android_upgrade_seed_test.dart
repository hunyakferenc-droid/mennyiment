// Executed against rebuilt, pinned #58 app source, NOT the current app code.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:mennyiment/menti_club_store.dart';

import 'android33_flows.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Pinned #58 creates real profile, journal, favorite, XP and fitness before same-key update',
    (t) async {
      await firstUse33(t, isReview: true);
      if (!const bool.fromEnvironment('MENTI_JOURNEY_UPGRADE_SEED')) return;
      final week = MentiClubStore(key: MentiClubStore.adventureWeekKey);
      await week.load();
      expect(
        await week.completeAdventure(DateTime(2030, 1, 1), rhythmScore: 2),
        ClubSave.saved,
      );
      week.dispose();
    },
  );
}
