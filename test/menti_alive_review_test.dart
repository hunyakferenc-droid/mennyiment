import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';
import 'package:mennyiment/menti_alive_preview.dart';
import 'package:mennyiment/menti_alive_review_catalog.dart';
import 'package:mennyiment/menti_animation_catalog.dart';
import 'package:mennyiment/menti_animation_controller.dart';
import 'package:mennyiment/menti_animation_player.dart';
import 'package:mennyiment/menti_collection_model.dart';
import 'package:mennyiment/menti_collection_store.dart';
import 'package:mennyiment/menti_motion.dart';
import 'package:mennyiment/menti_reaction_engine.dart';

import 'menti_life_engine_test.dart' show FakeMentiVideo;

String rawCatalog() =>
    File('tool/menti_alive/review_assets/catalog.json').readAsStringSync();
MentiAliveReviewCatalog review() =>
    MentiAliveReviewCatalog.decode(rawCatalog(), developerPreview: true);
Future<void> close(MentiAnimationController c) async {
  c.dispose();
  await c.settled;
}

void mount(MentiAnimationController c) {
  c.configure(
    look: 'boy-festival-v1',
    allowed: true,
    frequency: MentiAnimationFrequency.normal,
  );
  c.host('test', look: 'boy-festival-v1', size: 200, visible: true);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Three actual processed files stay unapproved and invisible to production catalog', () {
    final cat = review();
    expect(cat.clips.length, 3);
    expect(
      () => MentiAnimationCatalog.decode(rawCatalog()),
      throwsFormatException,
    );
    final normal = MentiAnimationCatalog(cat.clips);
    final locked = MentiAliveReviewCatalog.decode(rawCatalog());
    for (final c in cat.clips) {
      expect(c.playable, false);
      expect(c.approvedBy, isEmpty);
      expect(c.rightsVerified, false);
      expect(c.identityVerified, false);
      expect(c.backgroundApproved, false);
      expect(normal.find(c.lookId, c.reaction), isNull);
      expect(locked.find(c.lookId, c.reaction), isNull);
      final bytes = File(
        'tool/menti_alive/review_assets/${c.asset.split('/').last}',
      ).readAsBytesSync();
      expect(bytes.length, c.bytes);
      expect(sha256.convert(bytes).toString(), c.sha256);
    }
    for (final look in CompleteLook.all) {
      for (final r in MentiLifeReaction.values) {
        final selected = cat.find(look.id, r);
        if (look.id != 'boy-festival-v1') expect(selected, isNull);
      }
    }
  });
  for (final change in <String, dynamic>{
    'asset': 'https://example.invalid/movie.mp4',
    'lookId': 'unknown',
    'rightsVerified': true,
    'identityVerified': true,
    'ownerApproved': true,
    'status': 'approved',
    'audio': true,
    'bytes': 7 * 1024 * 1024,
    'durationMs': 9000,
    'width': 1000,
    'approvedBy': 'automatic',
  }.entries) {
    test('Review catalog rejects unsafe ${change.key}', () {
      final j = jsonDecode(rawCatalog());
      j['clips'][0][change.key] = change.value;
      expect(
        () => MentiAliveReviewCatalog.decode(
          jsonEncode(j),
          developerPreview: true,
        ),
        throwsFormatException,
      );
    });
  }
  test('Unknown root version and duplicate clips are rejected', () {
    final j = jsonDecode(rawCatalog());
    j['version'] = 99;
    expect(
      () => MentiAliveReviewCatalog.decode(jsonEncode(j)),
      throwsFormatException,
    );
    j['version'] = 1;
    j['clips'].add(j['clips'][0]);
    expect(
      () => MentiAliveReviewCatalog.decode(jsonEncode(j)),
      throwsFormatException,
    );
  });
  test('Restart waits for decoder disposal; double requests never allocate in parallel', () async {
    final gate = Completer<void>();
    var created = 0, live = 0, maxLive = 0;
    final c = MentiAnimationController(
      catalog: review(),
      verify: (_) async {},
      factory: (_) {
        created++;
        return FakeMentiVideo(
          closeGate: created == 1 ? gate : null,
          onOpen: () {
            live++;
            if (live > maxLive) maxLive = live;
          },
          onClose: () => live--,
        );
      },
    );
    mount(c);
    expect(
      c.request(MentiLifeReaction.welcome, token: 'first', manual: true),
      true,
    );
    await c.settled;
    final restarted = c.restart(MentiLifeReaction.wink, token: 'restart');
    await Future<void>.delayed(Duration.zero);
    expect(created, 1);
    gate.complete();
    expect(await restarted, true);
    await c.settled;
    expect(c.active?.reaction, MentiLifeReaction.wink);
    expect(created, 2);
    expect(maxLive, 1);
    expect(
      c.request(MentiLifeReaction.wink, token: 'double', manual: true),
      false,
    );
    await close(c);
    expect(live, 0);
  });
  test('Character change cancels pending restart instead of replaying another look', () async {
    final gate = Completer<void>();
    var created = 0;
    final c = MentiAnimationController(
      catalog: review(),
      verify: (_) async {},
      factory: (_) {
        created++;
        return FakeMentiVideo(closeGate: created == 1 ? gate : null);
      },
    );
    mount(c);
    c.request(MentiLifeReaction.welcome, token: 'first', manual: true);
    await c.settled;
    final pending = c.restart(MentiLifeReaction.wink, token: 'restart');
    await Future<void>.delayed(Duration.zero);
    c.configure(
      look: 'girl-festival-v1',
      allowed: true,
      frequency: MentiAnimationFrequency.normal,
    );
    gate.complete();
    expect(await pending, false);
    await c.settled;
    expect(c.active, isNull);
    expect(created, 1);
    await close(c);
  });
  testWidgets('Normal entry gate never loads or exposes review videos', (
    t,
  ) async {
    await t.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const MentiAlivePreviewPage(),
      ),
    );
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('alive-candidates')), findsNothing);
    expect(find.byType(MentiAnimationPlayer), findsNothing);
    expect(t.takeException(), isNull);
  });
  for (final lang in ['hu', 'en']) {
    for (final width in [320.0, 360.0, 390.0, 430.0]) {
      testWidgets(
        '$lang $width 200% review plays only explicit candidate and never writes profile XP or journal',
        (t) async {
          t.view.physicalSize = Size(width, 844);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          final saved = const CompleteLookSelection(
            active: true,
            lookId: 'girl-festival-v1',
            extras: {'future': 'keep'},
          ).encode();
          final originals = <String, Object>{
            CompleteLookStore.key: saved,
            'mennyiment_menti_xp_v2': '{"xp":190,"days":[],"future":"keep"}',
            'mennyiment_drinks_v1': 'unchanged historical raw bytes',
          };
          SharedPreferences.setMockInitialValues(originals);
          var allocations = 0;
          final c = MentiAnimationController(
            catalog: review(),
            verify: (_) async {},
            factory: (_) {
              allocations++;
              return FakeMentiVideo();
            },
          );
          await t.pumpWidget(
            MaterialApp(
              locale: Locale(lang),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              builder: (ctx, child) => MediaQuery(
                data: MediaQuery.of(ctx).copyWith(
                  textScaler: const TextScaler.linear(2),
                  disableAnimations: false,
                  accessibleNavigation: false,
                ),
                child: MentiMotionScope(child: child!),
              ),
              home: MentiAlivePreviewPage(
                developerPreview: true,
                controller: c,
                reviewCatalog: review(),
              ),
            ),
          );
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
          expect(
            t
                .widget<MentiAnimationPlayer>(find.byType(MentiAnimationPlayer))
                .look
                .id,
            'girl-festival-v1',
          );
          final play = find.byKey(const ValueKey('alive-play-welcome'));
          expect(t.widget<FilledButton>(play).onPressed, isNull);
          await t.ensureVisible(find.byKey(const ValueKey('alive-candidates')));
          await t.tap(find.byKey(const ValueKey('alive-candidates')));
          await t.pumpAndSettle();
          expect(
            t
                .widget<MentiAnimationPlayer>(find.byType(MentiAnimationPlayer))
                .look
                .id,
            'boy-festival-v1',
          );
          await Scrollable.ensureVisible(t.element(play), alignment: .5);
          await t.pumpAndSettle();
          await t.tap(play);
          await t.pumpAndSettle();
          await t.runAsync(() => c.settled);
          await t.pump();
          expect(c.active?.reaction, MentiLifeReaction.welcome);
          expect(
            find.byKey(const ValueKey('real-video-test-surface')),
            findsOneWidget,
          );
          final restart = find.byKey(const ValueKey('alive-restart-wink'));
          await Scrollable.ensureVisible(t.element(restart), alignment: .5);
          await t.pumpAndSettle();
          await t.tap(restart);
          await t.pumpAndSettle();
          await t.runAsync(() => c.settled);
          await t.pump();
          expect(c.active?.reaction, MentiLifeReaction.wink);
          await t.ensureVisible(find.byKey(const ValueKey('alive-stop')));
          await t.tap(find.byKey(const ValueKey('alive-stop')));
          await t.pumpAndSettle();
          await t.runAsync(() => c.settled);
          expect(c.active, isNull);
          await t.ensureVisible(find.byKey(const ValueKey('alive-enabled')));
          await t.tap(find.byKey(const ValueKey('alive-enabled')));
          await t.pumpAndSettle();
          expect(t.widget<FilledButton>(play).onPressed, isNull);
          final prefs = await SharedPreferences.getInstance();
          expect({for (final k in prefs.getKeys()) k: prefs.get(k)}, originals);
          expect(allocations, 2);
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox.shrink());
          await t.pumpAndSettle();
          c.dispose();
          await t.pump();
          await t.runAsync(() => c.settled);
        },
      );
    }
  }
}
