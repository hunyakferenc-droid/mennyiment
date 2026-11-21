import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/menti_alive_preview.dart';
import 'package:mennyiment/menti_animation_player.dart';
import 'package:mennyiment/menti_motion.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';
import 'package:mennyiment/menti_alive_review_catalog.dart';
import 'package:mennyiment/menti_animation_catalog.dart';
import 'package:mennyiment/menti_animation_controller.dart';
import 'package:mennyiment/menti_animation_studio_model.dart';
import 'package:mennyiment/menti_collection_model.dart';
import 'package:mennyiment/menti_reaction_engine.dart';

import 'menti_life_engine_test.dart' show FakeMentiVideo;

Map<String, dynamic> studioData() {
  final original = jsonDecode(
    File('tool/menti_alive/review_assets/catalog.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final extra = jsonDecode(
    File('tool/menti_animation_studio/review_assets/catalog.json')
        .readAsStringSync(),
  ) as Map<String, dynamic>;
  return {
    ...original,
    'clips': [...original['clips'], ...extra['clips']],
  };
}

MentiAliveReviewCatalog studio() => MentiAliveReviewCatalog.decode(
  jsonEncode(studioData()),
  developerPreview: true,
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Own girl and neutral source PNGs and processed videos match exact hashes',
    () {
      final data = jsonDecode(
        File('tool/menti_animation_studio/review_assets/catalog.json')
            .readAsStringSync(),
      );
      expect(data['clips'].length, 5);
      for (final c in data['clips']) {
        final look = CompleteLook.find(c['lookId'])!;
        expect(c['sourcePng'], look.asset);
        expect(
          sha256.convert(File(look.asset).readAsBytesSync()).toString(),
          c['sourcePngSha256'],
        );
        final name = (c['asset'] as String).split('/').last;
        final bytes = File('tool/menti_animation_studio/review_assets/$name')
            .readAsBytesSync();
        expect(bytes.length, c['bytes']);
        expect(sha256.convert(bytes).toString(), c['sha256']);
        for (final flag in [
          'ownerApproved',
          'identityVerified',
          'rightsVerified',
          'backgroundApproved',
        ]) {
          expect(c[flag], false);
        }
      }
    },
  );
  test('Actual combined inventory has 8 REVIEW and 244 missing, never a production clip', () {
    final c = studio();
    final i = MentiStudioInventory(review: c);
    expect(i.slots.length, 252);
    expect(i.count(MentiStudioStatus.reviewRequired), 8);
    expect(i.count(MentiStudioStatus.missing), 244);
    expect(i.count(MentiStudioStatus.approved), 0);
    final prod = MentiAnimationCatalog(c.clips);
    for (final look in CompleteLook.all) {
      for (final r in MentiLifeReaction.values) {
        expect(prod.find(look.id, r), isNull);
      }
    }
    for (final look in CompleteLook.all.where(
      (x) => ![
        'girl-base-v1',
        'neutral-base-v1',
        'boy-festival-v1',
      ].contains(x.id),
    )) {
      for (final r in MentiLifeReaction.values) {
        expect(c.find(look.id, r), isNull);
      }
    }
  });
  for (final clip in studio().clips.where(
    (c) => c.lookId != 'boy-festival-v1',
  )) {
    final family = clip.lookId.split('-').first;
    test(
      '$family ${clip.reaction.name} own clip initialization error recovers by explicit restart, one decoder',
      () async {
        var allocations = 0, live = 0, maxLive = 0;
        final c = MentiAnimationController(
          catalog: studio(),
          verify: (_) async {},
          factory: (_) {
            allocations++;
            return FakeMentiVideo(
              initializeError: allocations == 1,
              onOpen: () {
                live++;
                if (live > maxLive) maxLive = live;
              },
              onClose: () => live--,
            );
          },
        );
        final host = Object();
        c.configure(
          look: '$family-base-v1',
          allowed: true,
          frequency: MentiAnimationFrequency.normal,
        );
        c.host(host, look: '$family-base-v1', size: 180, visible: true);
        final reaction = clip.reaction;
        expect(c.request(reaction, token: 'first', manual: true), true);
        await c.settled;
        expect(c.status, MentiPlaybackStatus.error);
        expect(c.active, isNull);
        expect(live, 0);
        expect(await c.restart(reaction, token: 'retry'), true);
        await c.settled;
        expect(c.active!.lookId, '$family-base-v1');
        expect(c.active!.reaction, reaction);
        expect(maxLive, 1);
        c.foreground(false);
        await c.settled;
        expect(c.active, isNull);
        expect(c.handle, isNull);
        c.foreground(true);
        expect(c.active, isNull);
        c.configure(
          look: '$family-party-v1',
          allowed: true,
          frequency: MentiAnimationFrequency.normal,
        );
        c.host(host, look: '$family-party-v1', size: 180, visible: true);
        expect(c.request(reaction, token: 'wrong-outfit', manual: true), false);
        expect(allocations, 2);
        c.dispose();
        await c.settled;
        expect(live, 0);
      },
    );
  }
  for (final from in ['girl', 'neutral']) {
    for (final pending in [false, true]) {
      test(
        '$from wink switches family while ${pending ? 'loading' : 'playing'} without resurrection or double decoder',
        () async {
          final gate = Completer<void>();
          var allocations = 0, live = 0, maximum = 0;
          final c = MentiAnimationController(
            catalog: studio(),
            verify: (_) async {},
            factory: (_) {
              allocations++;
              return FakeMentiVideo(
                initializeGate: pending && allocations == 1 ? gate : null,
                onOpen: () {
                  live++;
                  if (live > maximum) maximum = live;
                },
                onClose: () => live--,
              );
            },
          );
          final host = Object();
          void select(String family) {
            c.configure(
              look: '$family-base-v1',
              allowed: true,
              frequency: MentiAnimationFrequency.normal,
            );
            c.host(host, look: '$family-base-v1', size: 180, visible: true);
          }

          select(from);
          expect(
            c.request(MentiLifeReaction.wink, token: 'old', manual: true),
            true,
          );
          if (pending) {
            await Future<void>.delayed(Duration.zero);
          } else {
            await c.settled;
            expect(c.active?.lookId, '$from-base-v1');
          }
          final to = from == 'girl' ? 'neutral' : 'girl';
          select(to);
          expect(c.active, isNull);
          expect(
            c.request(MentiLifeReaction.wink, token: 'new', manual: true),
            true,
          );
          gate.complete();
          await c.settled;
          expect(c.active?.lookId, '$to-base-v1');
          expect(c.active?.reaction, MentiLifeReaction.wink);
          expect(maximum, 1);
          c.stop();
          await c.settled;
          expect(c.handle, isNull);
          expect(live, 0);
          select(to);
          expect(c.active, isNull);
          c.dispose();
          await c.settled;
        },
      );
    }
  }
  for (final lang in ['hu', 'en']) {
    testWidgets(
      '$lang actual five-clip controls restart, stop, switch and preserve stored data',
      (t) async {
        SharedPreferences.setMockInitialValues({
          'mennyiment_drinks_v1': 'unknown journal',
          'mennyiment_identity_v22': 'future identity',
        });
        final prefs = await SharedPreferences.getInstance();
        final before = {for (final k in prefs.getKeys()) k: prefs.get(k)};
        final c = MentiAnimationController(
          verify: (_) async {},
          factory: (_) => FakeMentiVideo(),
        );
        await t.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => t.binding.setSurfaceSize(null));
        await t.pumpWidget(
          MaterialApp(
            locale: Locale(lang),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: MentiMotionScope(
              child: MentiAlivePreviewPage(
                studioMode: true,
                developerPreview: true,
                readPreferences: false,
                reviewCatalog: studio(),
                controller: c,
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        Future<void> tap(Key key) async {
          final f = find.byKey(key);
          await t.ensureVisible(f);
          await t.pump();
          expect(f.hitTestable(), findsOneWidget);
          await t.tap(f);
          await t.pumpAndSettle();
        }

        for (final clip in studio().clips.where(
          (x) => x.lookId != 'boy-festival-v1',
        )) {
          final family = clip.lookId.split('-').first;
          await tap(ValueKey('studio-family-$family'));
          final play = ValueKey('alive-play-${clip.reaction.name}');
          await tap(play);
          expect(c.active?.id, clip.id);
          final first = c.handle! as FakeMentiVideo;
          expect(first.playing, true);
          await tap(ValueKey('alive-restart-${clip.reaction.name}'));
          expect(first.closed, true);
          expect(identical(first, c.handle), false);
          expect(c.active?.id, clip.id);
          await tap(const ValueKey('alive-stop'));
          expect(c.active, isNull);
          expect(c.handle, isNull);
          expect(
            t
                .widget<MentiAnimationPlayer>(find.byType(MentiAnimationPlayer))
                .look
                .id,
            clip.lookId,
          );
          await tap(play);
          expect(c.active?.id, clip.id);
          final old = c.handle! as FakeMentiVideo;
          await tap(
            ValueKey('studio-family-${family == 'girl' ? 'neutral' : 'girl'}'),
          );
          expect(old.closed, true);
          expect(c.active, isNull);
          expect(c.handle, isNull);
          expect(
            t
                .widget<MentiAnimationPlayer>(find.byType(MentiAnimationPlayer))
                .look
                .family,
            family == 'girl' ? 'neutral' : 'girl',
          );
        }
        expect({for (final k in prefs.getKeys()) k: prefs.get(k)}, before);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox.shrink());
        await t.pumpAndSettle();
        c.dispose();
        await t.runAsync(() => c.settled);
      },
    );
  }
}
