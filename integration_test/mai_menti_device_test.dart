import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mennyiment/app_language.dart';
import 'package:mennyiment/main.dart';
import 'package:mennyiment/menti_club_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../tool/menti_home_review.dart' as review;
import 'menti_beta_device_test.dart' show tap;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Mai Menti completes, reloads and moves to tomorrow offline', (t) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    final journal = preferences.get('mennyiment_drinks_v1');
    final profile = preferences.get('mennyiment_identity_v22');
    final realRhythm = preferences.get(MentiClubStore.dailyRhythmKey);
    for (final locale in ['hu', 'en']) {
      await preferences.setString('mennyiment_locale_v1', locale);
      await preferences.setBool('mennyiment_reduce_motion_v1', true);
      await preferences.setString('mennyiment_mai_menti_test_date_v1',
        locale == 'hu' ? '2030-03-04' : '2030-03-11');
      await review.main();
      await t.pumpAndSettle();
      final home = find.byType(HomePage);
      expect(home, findsOneWidget);
      final strings = appStrings(t.element(home));
      expect(strings.localeName, locale);
      await tap(t, 'mai-mood-4');
      await tap(t, 'mai-play');
      final labels = {
        'stretch': strings.rhythmStretch,
        'left': strings.rhythmLeft,
        'right': strings.rhythmRight,
      };
      for (var length = 1; length <= 3; length++) {
        final moves = [
          for (var i = 0; i < length; i++)
            t.widget<Text>(find.byKey(ValueKey('mai-cue-$i'))).data!,
        ];
        await tap(t, 'mai-ready');
        for (final move in moves) {
          await tap(t, 'mai-hit-${labels.entries.singleWhere((e) => move.endsWith(e.value)).key}');
        }
      }
      await tap(t, 'mai-end-week');
      expect(find.text(locale == 'hu' ? 'Az elmúlt hét' : 'The last seven days'), findsOneWidget);
      await t.tap(find.byType(BackButton));
      await t.pumpAndSettle();
      await tap(t, 'mai-next-day');
      await tap(t, 'mai-next-day');
      final selected = find.byWidgetPredicate((w) =>
          w is ChoiceChip && w.key == const ValueKey('mai-mood-4') && w.selected);
      expect(selected, findsNothing);
      await t.pumpWidget(const SizedBox.shrink());
      await t.pumpAndSettle();
      await preferences.reload();
      final record = MentiClubRecord.decode(preferences.get(MentiClubStore.dailyRhythmTestKey));
      expect(record.best, 3);
      expect(preferences.get('mennyiment_drinks_v1'), journal);
      expect(preferences.get('mennyiment_identity_v22'), profile);
      expect(preferences.get(MentiClubStore.dailyRhythmKey), realRhythm);
      expect(jsonEncode(record.days), '[]');
    }
  });
}
