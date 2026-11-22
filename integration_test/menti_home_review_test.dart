// Native plugins and real MP4 decode on a disposable emulator. No clear-data.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/main.dart';
import 'package:mennyiment/app_language.dart';
import 'package:mennyiment/menti_animation_player.dart';
import 'package:mennyiment/menti_collection_store.dart';
import 'package:mennyiment/menti_collection_widgets.dart';
import 'package:mennyiment/menti_fitness.dart';
import 'package:mennyiment/menti_rhythm.dart';
import 'package:mennyiment/menti_motion.dart';
import 'package:mennyiment/menti_xp_store.dart';
import 'package:mennyiment/menti_club_store.dart';

import '../tool/menti_home_review.dart' as review;
import 'menti_beta_device_test.dart' show tap, reach, until;

Future<void> clubTap(WidgetTester t, String key) async {
  final scroll = find.byType(Scrollable);
  if (scroll.evaluate().isNotEmpty) {
    await t.drag(scroll.first, const Offset(0, 4000));
    await t.pumpAndSettle();
  }
  await tap(t, key);
}

Future<void> tapOwnMenti(WidgetTester t) async {
  final own = find.byKey(const ValueKey('home-menti'));
  await reach(t, own);
  await t.tap(own);
  await t.pump();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Native home REVIEW HU/EN video, own fallback, save, club five rounds, same data',
    (t) async {
      final p = await SharedPreferences.getInstance();
      // The preceding Studio test verified it wrote no preferences.
      expect(p.getString('mennyiment_drinks_v1'), isNull);
      await review.main();
      await t.pumpAndSettle();
      await tap(t, 'start-language-hu');
      await tap(t, 'start-next');
      await tap(t, 'start-adult');
      await tap(t, 'start-next');
      await tap(t, 'start-family-girl');
      await tap(t, 'start-look-girl-base-v1');
      await tap(t, 'start-next');
      // Observe the first actual frame; settling all home animations here can
      // outlive the one-shot welcome we are explicitly testing.
      final finish = find.byKey(const ValueKey('start-next'));
      await reach(t, finish);
      await t.tap(finish);
      await t.pump();
      await until(t, find.byType(HomePage));
      final ctx = t.element(find.byType(HomePage));
      final session = MentiAnimationScope.of(ctx)!;
      Future<void> waitVideo(String look, String reaction) async {
        final deadline = DateTime.now().add(const Duration(seconds: 20));
        while ((session.controller.handle?.frameVisible != true ||
                session.controller.active?.lookId != look ||
                session.controller.active?.reaction.name != reaction) &&
            DateTime.now().isBefore(deadline)) {
          await t.pump(const Duration(milliseconds: 80));
        }
        if (session.controller.active?.lookId != look ||
            session.controller.handle?.frameVisible != true) {
          debugPrint(
            jsonEncode({
              'diagnostic': 'HOME_NATIVE',
              'look': session.controller.lookId,
              'status': session.controller.status.name,
              'host': session.controller.hasVisibleHost,
              'catalog': session.controller.catalog.clips.length,
              'presentations': session.home!.presentations,
              'event': session.home!.event?.name,
              'motionReduced': MentiMotionScope.reducedOf(ctx),
              'measurements': session.controller.measurements,
            }),
          );
        }
        expect(session.controller.active?.lookId, look);
        expect(session.controller.active?.reaction.name, reaction);
        expect(session.controller.handle?.frameVisible, true);
        debugPrint('HOME_NATIVE actual video $look $reaction');
      }

      await waitVideo('girl-base-v1', 'welcome');
      expect(session.home!.presentations, 1);
      await tapOwnMenti(t);
      await waitVideo('girl-base-v1', 'wink');
      await tap(t, 'home-stop');
      expect(session.controller.handle, isNull);
      final store = CompleteLookStore();
      await store.load();
      expect(
        await store.save(
          store.selection.copyWith(active: true, lookId: 'neutral-base-v1'),
        ),
        true,
      );
      await CompleteLookScope.of(ctx)!.load();
      await t.pumpAndSettle();
      await tapOwnMenti(t);
      await waitVideo('neutral-base-v1', 'wink');
      expect(session.home!.presentations, 3); // No second welcome on switch.
      await tap(t, 'home-stop');
      await AppLanguageScope.of(ctx)!.select('en');
      await t.pumpAndSettle();
      await reach(t, find.byKey(const ValueKey('home-primary-log')));
      await tap(t, 'home-primary-log');
      await t.tap(
        find
            .descendant(
              of: find.byType(BottomSheet),
              matching: find.byType(ListTile),
            )
            .first,
      );
      await t.pumpAndSettle();
      final s = appStrings(t.element(find.byType(HomePage)));
      await reach(t, find.text(s.journalSave));
      await t.tap(find.text(s.journalSave));
      await t.pumpAndSettle();
      await p.reload();
      expect(
        (jsonDecode(p.getString('mennyiment_drinks_v1')!) as List).length,
        1,
      );
      expect(session.home!.event?.name, 'journalSaved');
      expect(session.controller.active, isNull);
      final before = {for (final k in p.getKeys()) k: p.get(k)};
      await tap(t, 'home-fitness');
      expect(find.byType(MentiFitnessClub), findsOneWidget);
      expect(session.controller.handle, isNull);
      await tap(t, 'fitness-play');
      final page = t.widget<MentiRhythmPage>(find.byType(MentiRhythmPage));
      // Read the exact sequence shown by the production page, never replace game logic.
      final dynamic state = t.state(find.byType(MentiRhythmPage));
      final MentiRhythm game = state.game;
      expect(page.game, isNull);
      for (var round = 0; round < 5; round++) {
        while (game.phase == RhythmPhase.demonstration) {
          await tap(t, 'rhythm-next');
        }
        if (round == 0) {
          final wrong = RhythmAction.values.firstWhere(
            (a) => a != game.sequence.first,
          );
          await tap(t, 'rhythm-${wrong.name}');
          expect(game.phase, RhythmPhase.mistake);
          await tap(t, 'rhythm-retry');
          while (game.phase == RhythmPhase.demonstration) {
            await tap(t, 'rhythm-next');
          }
        }
        for (final a in game.sequence) {
          await tap(t, 'rhythm-${a.name}');
        }
      }
      expect(game.completed, 5);
      await tap(t, 'rhythm-new');
      expect(game.completed, 0);
      await t.tap(find.byType(BackButton));
      await t.pumpAndSettle();
      expect(find.byType(MentiFitnessClub), findsOneWidget);
      await t.tap(find.byType(BackButton));
      await t.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);
      await p.reload();
      final after = {for (final k in p.getKeys()) k: p.get(k)};
      final club = MentiClubRecord.decode(
        after.remove(MentiClubStore.normalKey),
      );
      expect(club.best, 5);
      expect(club.days.length, 1);
      expect(club.last, clubDay(DateTime.now()));
      expect(after, before);
      await MentiMotionScope.settingsOf(ctx)!.setReduced(true);
      await t.pumpAndSettle();
      await tapOwnMenti(t);
      expect(session.controller.handle, isNull);
      expect(session.home!.wink, true);
      expect((await MentiXpStore.load()).xp, 0);
      debugPrint(
        'HOME_NATIVE passed: HU welcome/wink, neutral switch, EN save PNG, retry/five rounds/new/home, only separate club record written; no journal/XP writes, reduced motion',
      );
    },
  );
  testWidgets(
    'Native isolated seven virtual days, skip, repeat, new challenge and durable own record',
    (t) async {
      final p = await SharedPreferences.getInstance();
      await p.reload();
      final actual = p.getString(MentiClubStore.normalKey);
      expect(MentiClubRecord.decode(actual).best, 5);
      await review.main();
      await t.pumpAndSettle();
      await until(t, find.byType(HomePage));
      await clubTap(t, 'home-fitness');
      await clubTap(t, 'club-test-mode');
      Future<void> cards({bool skip = false, bool partial = false}) async {
        await clubTap(t, 'fitness-cards');
        await clubTap(t, 'cards-start');
        if (partial) {
          await clubTap(t, 'cards-next');
          await clubTap(t, 'cards-exit');
          return;
        }
        for (var n = 0; n < 3; n++) {
          await clubTap(t, skip ? 'cards-skip' : 'cards-next');
        }
        await clubTap(t, 'cards-club');
      }

      await cards(partial: true);
      await p.reload();
      expect(p.getString(MentiClubStore.testKey), isNull);
      await cards(skip: true);
      await p.reload();
      expect(p.getString(MentiClubStore.testKey), isNull);
      for (var i = 0; i < 7; i++) {
        await cards();
        await p.reload();
        expect(
          MentiClubRecord.decode(p.get(MentiClubStore.testKey)).days.length,
          i + 1,
        );
        if (i == 0) {
          await cards();
          await p.reload();
          expect(
            MentiClubRecord.decode(p.get(MentiClubStore.testKey)).days.length,
            1,
          );
        }
        if (i < 6) {
          await clubTap(t, 'club-next-day');
          if (i == 1) await clubTap(t, 'club-next-day');
        }
      }
      await p.reload();
      expect(MentiClubRecord.decode(p.get(MentiClubStore.testKey)).days, [
        '2030-01-01',
        '2030-01-02',
        '2030-01-04',
        '2030-01-05',
        '2030-01-06',
        '2030-01-07',
        '2030-01-08',
      ]);
      await clubTap(t, 'club-new-challenge');
      await cards();
      await p.reload();
      expect(
        MentiClubRecord.decode(p.get(MentiClubStore.testKey)).days,
        isEmpty,
      );
      await clubTap(t, 'club-next-day');
      await cards();
      await p.reload();
      expect(MentiClubRecord.decode(p.get(MentiClubStore.testKey)).days, [
        '2030-01-09',
      ]);
      expect(p.getString(MentiClubStore.normalKey), actual);
      await t.tap(find.byType(BackButton));
      await t.pumpAndSettle();
      await t.tap(find.byType(BackButton));
      await t.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);
      debugPrint(
        'CLUB_NATIVE passed: partial/all-skip, seven days with gap, repeat, reset, isolated storage, unchanged own best and days',
      );
    },
  );
}
