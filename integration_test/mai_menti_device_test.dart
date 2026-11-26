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
  testWidgets('Mai Menti completes, reloads and moves to tomorrow offline', (
    t,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    final journal = preferences.get('mennyiment_drinks_v1');
    final profile = preferences.get('mennyiment_identity_v22');
    final realRhythm = preferences.get(MentiClubStore.dailyRhythmKey);
    final realWeek = preferences.get(MentiClubStore.adventureWeekKey);
    for (final locale in ['hu', 'en']) {
      debugPrint('REVIEW adventure: starting $locale');
      await preferences.remove(MentiClubStore.adventureWeekTestKey);
      await preferences.setString('mennyiment_locale_v1', locale);
      await preferences.setBool('mennyiment_reduce_motion_v1', true);
      await preferences.setString(
        'mennyiment_mai_menti_test_date_v1',
        locale == 'hu' ? '2030-03-04' : '2030-04-01',
      );
      await review.main();
      await t.pumpAndSettle();
      final home = find.byType(HomePage);
      expect(home, findsOneWidget);
      final strings = appStrings(t.element(home));
      expect(strings.localeName, locale);
      if (locale == 'en') {
        final dispatcher = t.platformDispatcher;
        dispatcher.textScaleFactorTestValue = 2;
        await t.pumpAndSettle();
        await _reach(t, find.byKey(const ValueKey('home-primary-log')));
        expect(
          find.byKey(const ValueKey('nav-journal')).hitTestable(),
          findsOneWidget,
        );
        await _reach(t, find.byKey(const ValueKey('adventure-start')));
        expect(t.takeException(), isNull);
        final scroll = t.state<ScrollableState>(find.byType(Scrollable).first);
        scroll.position.jumpTo(scroll.position.minScrollExtent);
        dispatcher.clearTextScaleFactorTestValue();
        await t.pumpAndSettle();
      }
      debugPrint('REVIEW adventure: $locale standalone Rhythm');
      await _tap(t, 'mai-mood-4');
      await _tap(t, 'mai-play');
      final labels = {
        'stretch': strings.rhythmStretch,
        'left': strings.rhythmLeft,
        'right': strings.rhythmRight,
      };
      await _tap(t, 'mai-hit-stretch');
      final early = find.textContaining(
        locale == 'hu' ? 'Korai koppintás' : 'Too soon',
      );
      await _reach(t, early);
      await _tap(t, 'mai-ready');
      await t.pump(const Duration(seconds: 10));
      final late = find.textContaining(
        locale == 'hu' ? 'Késői koppintás' : 'Too late',
      );
      await _reach(t, late);
      await _tap(t, 'mai-replay');
      await _playRhythm(t, labels);
      await _tap(t, 'mai-end-week');
      expect(
        find.text(locale == 'hu' ? 'Az elmúlt hét' : 'The last seven days'),
        findsOneWidget,
      );
      await t.tap(find.byType(BackButton));
      await t.pumpAndSettle();
      await _tap(t, 'mai-next-day');
      final recap = find.byKey(const ValueKey('mai-yesterday'));
      await _reach(t, recap);
      expect(t.widget<Text>(recap).data, contains('3 / 3'));
      await _tap(t, 'mai-next-day');
      final selected = find.byWidgetPredicate(
        (w) =>
            w is ChoiceChip &&
            w.key == const ValueKey('mai-mood-4') &&
            w.selected,
      );
      expect(selected, findsNothing);
      for (var stage = 0; stage < 7; stage++) {
        debugPrint('REVIEW adventure: $locale stage ${stage + 1}');
        await _tap(t, 'adventure-start');
        if (stage == 1 || stage == 5) {
          await _playRhythm(t, labels);
          await _tap(t, 'mai-end-week');
        } else if (stage == 2 || stage == 4) {
          await _tap(t, 'cards-start');
          for (var move = 0; move < 3; move++) {
            await _tap(t, 'cards-next');
          }
          await _tap(t, 'cards-club');
        } else {
          await _tap(t, 'adventure-mood-4');
        }
        await preferences.reload();
        final trial = MentiClubRecord.decode(
          preferences.get(MentiClubStore.adventureWeekTestKey),
        );
        expect(trial.days.length, stage + 1);
        if (stage < 6) {
          final start = find.byKey(const ValueKey('adventure-start'));
          await _reach(t, start);
          expect(t.widget<FilledButton>(start).onPressed, isNull);
          await _tap(t, 'mai-next-day');
          if (stage == 2) await _tap(t, 'mai-next-day');
        } else {
          final finished = find.byKey(
            const ValueKey('adventure-week-finished'),
          );
          await _reach(t, finished);
          expect(trial.best, 3);
        }
      }
      await t.pumpWidget(const SizedBox.shrink());
      await t.pumpAndSettle();
      await preferences.reload();
      final record = MentiClubRecord.decode(
        preferences.get(MentiClubStore.dailyRhythmTestKey),
      );
      expect(record.best, 3);
      expect(record.scoreOn(locale == 'hu' ? '2030-03-04' : '2030-04-01'), 3);
      expect(preferences.get('mennyiment_drinks_v1'), journal);
      expect(preferences.get('mennyiment_identity_v22'), profile);
      expect(preferences.get(MentiClubStore.dailyRhythmKey), realRhythm);
      expect(preferences.get(MentiClubStore.adventureWeekKey), realWeek);
      expect(jsonEncode(record.days), '[]');
    }
  });
}

Future<void> _playRhythm(WidgetTester t, Map<String, String> labels) async {
  for (var length = 1; length <= 3; length++) {
    await _reach(t, find.byKey(const ValueKey('mai-cue-0')));
    final moves = [
      for (var i = 0; i < length; i++)
        t.widget<Text>(find.byKey(ValueKey('mai-cue-$i'))).data!,
    ];
    await _tap(t, 'mai-ready');
    for (final move in moves) {
      await _tap(
        t,
        'mai-hit-${labels.entries.singleWhere((e) => move.endsWith(e.value)).key}',
      );
    }
  }
}

// A scrolled-away lazy child may be above the viewport. Seek from the start
// in that case, rather than repeatedly scrolling toward the bottom.
Future<void> _reach(WidgetTester t, Finder target) async {
  if (target.evaluate().isEmpty) {
    final state = t.state<ScrollableState>(find.byType(Scrollable).first);
    state.position.jumpTo(state.position.minScrollExtent);
    await t.pumpAndSettle();
  }
  if (target.evaluate().isEmpty) {
    await t.scrollUntilVisible(
      target,
      140,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await t.ensureVisible(target);
  await t.pumpAndSettle();
  expect(
    target.hitTestable(),
    findsOneWidget,
    reason: 'Visible REVIEW control: $target',
  );
}

Future<void> _tap(WidgetTester t, String key) async {
  await _reach(t, find.byKey(ValueKey(key)));
  await tap(t, key);
}
