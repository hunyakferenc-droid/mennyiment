import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';
import 'package:mennyiment/menti_animation_catalog.dart';
import 'package:mennyiment/menti_animation_controller.dart';
import 'package:mennyiment/menti_home_reactions.dart';
import 'package:mennyiment/menti_life_events.dart';
import 'package:mennyiment/menti_reaction_engine.dart';
import 'package:mennyiment/menti_rhythm.dart';
import 'package:mennyiment/menti_fitness.dart';

import 'menti_life_engine_test.dart' show fixture, FakeMentiVideo;

void main() {
  testWidgets(
    'One welcome across rebuilds/routes/character switch; own missing PNG; rapid wink bounded',
    (t) async {
      final clips = [
        for (final look in ['girl-base-v1', 'neutral-base-v1'])
          for (final reaction in ['welcome', 'wink'])
            fixture(id: '$look-$reaction', look: look, reaction: reaction),
      ];
      final videos = <FakeMentiVideo>[];
      final c = MentiAnimationController(
        catalog: MentiAnimationCatalog(clips),
        verify: (_) async {},
        factory: (_) {
          final v = FakeMentiVideo();
          videos.add(v);
          return v;
        },
      );
      final h = MentiHomeReactions()..attach(c);
      c.configure(
        look: 'girl-base-v1',
        allowed: true,
        frequency: MentiAnimationFrequency.normal,
      );
      final host = Object();
      c.host(host, look: 'girl-base-v1', size: 140, visible: true);
      h.refresh();
      expect(
        h.presentations,
        0,
        reason:
            "An onboarding or Studio host must not consume the home greeting",
      );
      h.visibility(true);
      await t.pump();
      expect(h.presentations, 1);
      expect(c.active!.lookId, 'girl-base-v1');
      h.refresh();
      h.visibility(false);
      h.visibility(true);
      await t.pump();
      expect(h.presentations, 1);
      h.requestWink(now: DateTime(2026));
      await t.pump();
      for (var i = 0; i < 20; i++) {
        h.requestWink(now: DateTime(2026));
      }
      expect(h.presentations, 2);
      expect(c.active!.reaction, MentiLifeReaction.wink);
      c.configure(
        look: 'neutral-base-v1',
        allowed: true,
        frequency: MentiAnimationFrequency.normal,
      );
      c.host(host, look: 'neutral-base-v1', size: 140, visible: true);
      h.refresh();
      await t.pump();
      expect(c.handle, isNull);
      expect(videos.every((v) => v.closed), true);
      expect(h.presentations, 2);
      h.receive(const MentiLifeSignal(MentiLifeEvent.journalSaved, 'save-1'));
      h.receive(const MentiLifeSignal(MentiLifeEvent.journalSaved, 'save-1'));
      await t.pump(const Duration(milliseconds: 150));
      expect(h.presentations, 3);
      expect(h.event, MentiLifeEvent.journalSaved);
      expect(c.lookId, 'neutral-base-v1');
      expect(c.active, isNull);
      expect(c.status, MentiPlaybackStatus.noClip);
      h.dispose();
      c.dispose();
      await t.pump();
    },
  );
  testWidgets(
    'Level event preempts the welcome with its own clip without duplicate save reactions',
    (t) async {
      final clips = [
        fixture(id: 'welcome', look: 'boy-festival-v1'),
        fixture(
          id: 'level',
          look: 'boy-festival-v1',
          reaction: 'congratulation',
        ),
      ];
      final c = MentiAnimationController(
        catalog: MentiAnimationCatalog(clips),
        clock: () => DateTime(2026),
        verify: (_) async {},
        factory: (_) => FakeMentiVideo(),
      );
      c.configure(
        look: 'boy-festival-v1',
        allowed: true,
        frequency: MentiAnimationFrequency.normal,
      );
      c.host(Object(), look: 'boy-festival-v1', size: 140, visible: true);
      final h = MentiHomeReactions()..attach(c);
      h.visibility(true);
      h.refresh();
      await t.pump();
      expect(c.active!.reaction, MentiLifeReaction.welcome);
      h.receive(
        const MentiLifeSignal(MentiLifeEvent.xpMilestone, 'saved-level-7'),
      );
      h.receive(
        const MentiLifeSignal(MentiLifeEvent.xpMilestone, 'saved-level-7'),
      );
      await t.pump(const Duration(milliseconds: 150));
      expect(h.presentations, 2);
      expect(c.active?.reaction, MentiLifeReaction.congratulation);
      expect(c.active?.lookId, 'boy-festival-v1');
      h.dispose();
      c.dispose();
      await t.pump();
    },
  );
  testWidgets(
    'Home welcome waits for the actual home media host instead of being consumed during loading',
    (t) async {
      final c = MentiAnimationController(
        catalog: MentiAnimationCatalog([fixture(look: 'girl-base-v1')]),
        verify: (_) async {},
        factory: (_) => FakeMentiVideo(),
      );
      c.configure(
        look: 'girl-base-v1',
        allowed: true,
        frequency: MentiAnimationFrequency.normal,
      );
      final h = MentiHomeReactions()..attach(c);
      h.visibility(true);
      h.refresh();
      await t.pump();
      expect(h.presentations, 0);
      expect(c.active, isNull);
      c.host(Object(), look: 'girl-base-v1', size: 140, visible: true);
      h.refresh();
      await t.pump();
      expect(h.presentations, 1);
      expect(c.active?.reaction, MentiLifeReaction.welcome);
      h.dispose();
      c.dispose();
      await t.pump();
    },
  );
  testWidgets(
    'Save signals coalesce on route return; reduced motion keeps text; old-character event discarded',
    (t) async {
      final c = MentiAnimationController();
      final h = MentiHomeReactions()..attach(c);
      c.configure(
        look: 'girl-base-v1',
        allowed: false,
        frequency: MentiAnimationFrequency.normal,
      );
      h.refresh();
      h.visibility(true);
      expect(h.presentations, 1);
      expect(c.handle, isNull);
      h.visibility(false);
      h.receive(const MentiLifeSignal(MentiLifeEvent.xpEarned, 'xp-10'));
      await t.pump(const Duration(milliseconds: 200));
      h.receive(const MentiLifeSignal(MentiLifeEvent.checkInSaved, 'day-1'));
      await t.pump(const Duration(milliseconds: 200));
      expect(h.presentations, 1);
      h.visibility(true);
      await t.pump(const Duration(milliseconds: 150));
      expect(h.presentations, 2);
      expect(h.event, MentiLifeEvent.checkInSaved);
      expect(c.handle, isNull);
      h.visibility(false);
      h.receive(const MentiLifeSignal(MentiLifeEvent.journalSaved, 'old'));
      c.configure(
        look: 'neutral-base-v1',
        allowed: false,
        frequency: MentiAnimationFrequency.normal,
      );
      h.refresh();
      h.visibility(true);
      await t.pump(const Duration(milliseconds: 150));
      expect(h.event, isNull);
      expect(h.presentations, 2);
      h.dispose();
      c.dispose();
      await t.pump();
    },
  );
  testWidgets(
    'No welcome before catalog readiness; background signals wait until resume',
    (t) async {
      final c = MentiAnimationController();
      c.configure(
        look: 'girl-base-v1',
        allowed: false,
        frequency: MentiAnimationFrequency.normal,
      );
      final h = MentiHomeReactions()..attach(c, ready: false);
      h.visibility(true);
      expect(h.presentations, 0);
      h.ready(true);
      h.refresh();
      expect(h.presentations, 1);
      h.foreground(false);
      h.receive(
        const MentiLifeSignal(MentiLifeEvent.journalSaved, 'background-save'),
      );
      await t.pump(const Duration(milliseconds: 200));
      expect(h.presentations, 1);
      h.foreground(true);
      await t.pump(const Duration(milliseconds: 150));
      expect(h.presentations, 2);
      expect(h.event, MentiLifeEvent.journalSaved);
      h.dispose();
      c.dispose();
      await t.pump();
    },
  );
  test('Rhythm ignores input during demonstration, retries same sequence and finishes exactly five rounds without persistence', () async {
    SharedPreferences.setMockInitialValues({'sentinel': 'preserve'});
    final p = await SharedPreferences.getInstance();
    final before = {for (final k in p.getKeys()) k: p.get(k)};
    final g = MentiRhythm(random: Random(42));
    expect(g.sequence.length, 3);
    g.press(g.sequence.first);
    expect(g.entered, 0);
    while (g.phase == RhythmPhase.demonstration) {
      g.next();
    }
    g.press(RhythmAction.values.firstWhere((v) => v != g.sequence.first));
    expect(g.phase, RhythmPhase.mistake);
    final same = g.sequence;
    g.retry();
    expect(g.sequence, same);
    expect(g.completed, 0);
    for (var round = 1; round <= 5; round++) {
      expect(g.sequence.length, round + 2);
      while (g.phase == RhythmPhase.demonstration) {
        g.next();
      }
      final seq = g.sequence;
      for (final a in seq) {
        g.press(a);
      }
      expect(g.completed, round);
    }
    expect(g.phase, RhythmPhase.finished);
    g.next();
    g.press(RhythmAction.left);
    expect(g.completed, 5);
    expect({for (final k in p.getKeys()) k: p.get(k)}, before);
    g.restart();
    expect(g.completed, 0);
    expect(g.sequence.length, 3);
    expect(g.phase, RhythmPhase.demonstration);
  });
  for (final locale in ['hu', 'en']) {
    for (final width in [320.0, 360.0, 390.0, 430.0]) {
      testWidgets(
        'Club and full keyboard game $locale $width at 200%, retry/new/return, no writes',
        (t) async {
          SharedPreferences.setMockInitialValues({'sentinel': 'preserve'});
          final p = await SharedPreferences.getInstance();
          t.view.physicalSize = Size(width, 1100);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          final game = MentiRhythm(random: Random(7));
          await t.pumpWidget(
            MaterialApp(
              locale: Locale(locale),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(2)),
                child: child!,
              ),
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => MentiRhythmPage(game: game),
                      ),
                    ),
                    child: const Text('Home'),
                  ),
                ),
              ),
            ),
          );
          await t.tap(find.text('Home'));
          await t.pumpAndSettle();
          Future<void> click(String key) async {
            final f = find.byKey(ValueKey(key));
            for (var n = 0; f.evaluate().isEmpty && n < 40; n++) {
              await t.drag(
                find.byType(Scrollable).first,
                const Offset(0, -200),
              );
              await t.pumpAndSettle();
            }
            expect(f, findsOneWidget);
            await t.ensureVisible(f);
            await t.pumpAndSettle();
            await t.tap(f);
            await t.pumpAndSettle();
          }

          while (game.phase == RhythmPhase.demonstration) {
            await click('rhythm-next');
          }
          await click(
            'rhythm-${RhythmAction.values.firstWhere((a) => a != game.sequence.first).name}',
          );
          expect(game.phase, RhythmPhase.mistake);
          await click('rhythm-retry');
          for (var i = 0; i < 5; i++) {
            while (game.phase == RhythmPhase.demonstration) {
              if (i == 0 && game.shown == game.sequence.length - 1) {
                final next = find.byKey(const ValueKey('rhythm-next'));
                await t.ensureVisible(next);
                await t.pumpAndSettle();
                Focus.of(
                  t.element(
                    find
                        .descendant(of: next, matching: find.byType(Text))
                        .first,
                  ),
                ).requestFocus();
                await t.pump();
                await t.sendKeyEvent(LogicalKeyboardKey.enter);
                await t.pumpAndSettle();
              } else {
                await click('rhythm-next');
              }
            }
            for (final a in game.sequence) {
              if (i == 0) {
                await t.sendKeyEvent(switch (a) {
                  RhythmAction.stretch => LogicalKeyboardKey.digit1,
                  RhythmAction.left => LogicalKeyboardKey.digit2,
                  RhythmAction.right => LogicalKeyboardKey.digit3,
                });
                await t.pumpAndSettle();
              } else {
                await click('rhythm-${a.name}');
              }
            }
          }
          expect(game.completed, 5);
          await click('rhythm-new');
          expect(game.completed, 0);
          await t.tap(find.byType(BackButton));
          await t.pumpAndSettle();
          expect(find.text('Home'), findsOneWidget);
          expect(p.getKeys(), {'sentinel'});
          expect(p.getString('sentinel'), 'preserve');
          expect(t.takeException(), isNull);
        },
      );
    }
  }
}
