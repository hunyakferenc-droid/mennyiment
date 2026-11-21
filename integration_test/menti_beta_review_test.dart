// Real Android video_player decoder, not FakeMentiVideo. Separate REVIEW ID.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/menti_alive_preview.dart';
import 'package:mennyiment/menti_animation_controller.dart';
import 'package:mennyiment/menti_reaction_engine.dart';

import 'menti_beta_device_test.dart' show reach, until;

Future<LocalMentiVideo> studioFrame(
  WidgetTester t,
  String look,
  MentiLifeReaction reaction, {
  LocalMentiVideo? previous,
}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 20));
  while (DateTime.now().isBefore(deadline)) {
    await t.pump(const Duration(milliseconds: 100));
    final dynamic owner = t.state(find.byType(MentiAlivePreviewPage));
    final MentiAnimationController engine = owner.c;
    expect(engine.status, isNot(MentiPlaybackStatus.error));
    if (engine.handle is LocalMentiVideo &&
        !identical(engine.handle, previous) &&
        engine.handle!.frameVisible) {
      final video = engine.handle! as LocalMentiVideo;
      expect(engine.active?.lookId, look);
      expect(engine.active?.reaction, reaction);
      expect(video.video.value.size, const Size(540, 720));
      expect(video.video.value.volume, 0);
      return video;
    }
  }
  throw TestFailure('No actual Studio frame: $look/${reaction.name}');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Separate native REVIEW sandbox and three real muted decoders in HU/EN',
    (t) async {
      final p = await SharedPreferences.getInstance();
      expect(
        p.getKeys().where((k) => k.startsWith('mennyiment_')),
        isEmpty,
        reason: 'Normal app data must not leak into the REVIEW sandbox',
      );
      await t.pumpWidget(const MentiAliveReviewApp(reviewEnabled: true));
      await t.pumpAndSettle();
      final page = t.widget<MentiAlivePreviewPage>(
        find.byType(MentiAlivePreviewPage),
      );
      expect(page.developerPreview, true);
      for (final lang in ['HU', 'EN']) {
        final language = find.widgetWithText(TextButton, lang);
        await t.tap(language);
        await t.pumpAndSettle();
        for (final reaction in ['welcome', 'wink', 'congratulation']) {
          final play = find.byKey(ValueKey('alive-play-$reaction'));
          await reach(t, play);
          final readyBy = DateTime.now().add(const Duration(seconds: 20));
          while (t.widget<FilledButton>(play).onPressed == null &&
              DateTime.now().isBefore(readyBy)) {
            await t.pump(const Duration(milliseconds: 100));
          }
          expect(
            t.widget<FilledButton>(play).onPressed,
            isNotNull,
            reason: 'Native media did not become ready; system motion policy is not overridden',
          );
          await t.tap(play);
          final deadline = DateTime.now().add(const Duration(seconds: 20));
          LocalMentiVideo? video;
          while (DateTime.now().isBefore(deadline)) {
            await t.pump(const Duration(milliseconds: 100));
            // Inspect the actual controller used by the shared player widget.
            final dynamic state = t.state(find.byType(MentiAlivePreviewPage));
            final MentiAnimationController c = state.c;
            if (c.status == MentiPlaybackStatus.error) {
              fail('Native decoder failed: $lang/$reaction');
            }
            if (c.handle is LocalMentiVideo && c.handle!.frameVisible) {
              video = c.handle! as LocalMentiVideo;
              break;
            }
          }
          expect(video, isNotNull);
          expect(video!.video.value.volume, 0);
          expect(video.video.value.size, const Size(540, 720));
          final dynamic state = t.state(find.byType(MentiAlivePreviewPage));
          final MentiAnimationController c = state.c;
          expect(c.active?.reaction.name, reaction);
          expect(c.active?.lookId, 'boy-festival-v1');
          // ignore: avoid_print
          print(
            'MENTI_BETA_DECODER: ${jsonEncode({'locale': lang, 'reaction': reaction, 'positionMs': video.video.value.position.inMilliseconds, 'size': '540x720', 'muted': true, 'measurements': c.measurements.last})}',
          );
          c.stop();
          await c.settled;
          await t.pumpAndSettle();
          expect(c.handle, isNull);
        }
      }
      await t.pumpWidget(const SizedBox.shrink());
      await t.pumpAndSettle();
      await t.pumpWidget(
        const MentiAliveReviewApp(reviewEnabled: true, studioMode: true),
      );
      await t.pumpAndSettle();
      await until(t, find.byKey(const ValueKey('studio-inventory-ready')));
      expect(find.byKey(const ValueKey('studio-family-girl')), findsOneWidget);
      for (final lang in ['HU', 'EN']) {
        await t.tap(find.widgetWithText(TextButton, lang));
        await t.pumpAndSettle();
        for (final family in ['girl', 'neutral']) {
          final available = {
            MentiLifeReaction.welcome,
            MentiLifeReaction.wink,
            if (family == 'girl') MentiLifeReaction.thinking,
          };
          for (final reaction in available) {
            final chip = find.byKey(ValueKey('studio-family-$family'));
            await t.ensureVisible(chip);
            await t.tap(chip);
            await t.pumpAndSettle();
            for (final slot in MentiLifeReaction.values) {
              expect(
                find.byKey(ValueKey('studio-slot-${slot.name}')),
                findsOneWidget,
              );
              expect(
                t
                        .widget<FilledButton>(
                          find.byKey(ValueKey('alive-play-${slot.name}')),
                        )
                        .onPressed !=
                    null,
                available.contains(slot),
              );
            }
            final play = find.byKey(ValueKey('alive-play-${reaction.name}'));
            await t.ensureVisible(play);
            await t.tap(play);
            final actual = await studioFrame(t, '$family-base-v1', reaction);
            final dynamic owner = t.state(find.byType(MentiAlivePreviewPage));
            final MentiAnimationController engine = owner.c;
            // ignore: avoid_print
            print(
              'MENTI_STUDIO_DECODER: ${jsonEncode({'locale': lang, 'lookId': engine.active!.lookId, 'reaction': reaction.name, 'positionMs': actual.video.value.position.inMilliseconds, 'measurements': engine.measurements.last})}',
            );
            final restart = find.byKey(
              ValueKey('alive-restart-${reaction.name}'),
            );
            await t.tap(restart);
            final restarted = await studioFrame(
              t,
              '$family-base-v1',
              reaction,
              previous: actual,
            );
            expect(identical(actual, restarted), false);
            final stop = find.byKey(const ValueKey('alive-stop'));
            await t.ensureVisible(stop);
            await t.tap(stop);
            await engine.settled;
            await t.pumpAndSettle();
            expect(engine.handle, isNull);
            expect(engine.active, isNull);
            // Start from the real Play control, then change family while it plays.
            await t.ensureVisible(play);
            await t.tap(play);
            await studioFrame(t, '$family-base-v1', reaction);
            final other = find.byKey(
              ValueKey(
                'studio-family-${family == 'girl' ? 'neutral' : 'girl'}',
              ),
            );
            await t.ensureVisible(other);
            expect(engine.active?.lookId, '$family-base-v1');
            await t.tap(other);
            await engine.settled;
            await t.pumpAndSettle();
            expect(engine.active, isNull);
            expect(engine.handle, isNull);
            await p.reload();
            expect(
              p.getKeys().where((k) => k.startsWith('mennyiment_')),
              isEmpty,
            );
          }
        }
      }
      // ignore: avoid_print
      print(
        'MENTI_STUDIO_NATIVE: all fourteen exact slots; all five girl/neutral videos decoded/restarted/stopped/switched HU/EN; no data writes',
      );
      final dynamic state = t.state(find.byType(MentiAlivePreviewPage));
      final MentiAnimationController c = state.c;
      c.configure(
        look: 'girl-party-v1',
        allowed: true,
        frequency: MentiAnimationFrequency.normal,
      );
      expect(
        c.request(
          MentiLifeReaction.welcome,
          token: 'no-substitute',
          manual: true,
        ),
        false,
      );
      expect(c.active, isNull);
      await p.reload();
      expect(p.getKeys().where((k) => k.startsWith('mennyiment_')), isEmpty);
      expect(t.takeException(), isNull);
    },
  );
}
