// Real Android video_player decoder, not FakeMentiVideo. Separate REVIEW ID.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/menti_alive_preview.dart';
import 'package:mennyiment/menti_animation_controller.dart';
import 'package:mennyiment/menti_reaction_engine.dart';

import 'menti_beta_device_test.dart' show reach;

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
      final dynamic state = t.state(find.byType(MentiAlivePreviewPage));
      final MentiAnimationController c = state.c;
      c.configure(
        look: 'girl-base-v1',
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
