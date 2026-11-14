import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';
import 'package:mennyiment/menti_animation_preview.dart';
import 'package:mennyiment/menti_animation_player.dart';
import 'package:mennyiment/menti_animation_controller.dart';
import 'package:mennyiment/menti_animation_catalog.dart';
import 'package:mennyiment/menti_animation_settings.dart';
import 'package:mennyiment/menti_complete_looks.dart';
import 'package:mennyiment/menti_experience_settings.dart';
import 'package:mennyiment/menti_motion.dart';
import 'package:mennyiment/menti_reaction_engine.dart';

import 'menti_life_engine_test.dart' show FakeMentiVideo, fixture;

void main() {
  for (final locale in ['hu', 'en']) {
    for (final width in [320.0, 360.0, 390.0, 430.0]) {
      testWidgets(
        '$locale $width 200% Life preview respects PNG identity, reduced motion, settings, and restore-safe storage',
        (t) async {
          t.view.physicalSize = Size(width, 844);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          final raw = const CompleteLookSelection(
            active: true,
            lookId: 'girl-festival-v1',
          ).encode();
          SharedPreferences.setMockInitialValues({CompleteLookStore.key: raw});
          final store = CompleteLookStore();
          await store.load();
          await t.pumpWidget(
            MaterialApp(
              locale: Locale(locale),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              builder: (ctx, child) => MediaQuery(
                data: MediaQuery.of(ctx).copyWith(
                  textScaler: const TextScaler.linear(2),
                  disableAnimations: true,
                ),
                child: CompleteLookScope(
                  store: store,
                  child: MentiExperienceScope(
                    child: MentiMotionScope(
                      child: MentiAnimationScope(child: child!),
                    ),
                  ),
                ),
              ),
              home: const MentiAnimationPreviewPage(),
            ),
          );
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
          final s = AppLocalizations.of(
            t.element(find.byType(MentiAnimationPreviewPage)),
          )!;
          Future<void> reach(Finder f) async {
            await t.scrollUntilVisible(
              f,
              180,
              maxScrolls: 80,
              scrollable: find.byType(Scrollable).last,
            );
            await t.ensureVisible(f);
            await t.pumpAndSettle();
          }

          await reach(find.byType(MentiAnimationPlayer));
          expect(
            t
                .widget<CompleteLookArtwork>(find.byType(CompleteLookArtwork))
                .look
                .id,
            'girl-festival-v1',
          );
          await reach(find.text(s.lifeNoClip));
          expect(find.text(s.lifeNoClip), findsOneWidget);
          final toggle = find.byKey(const ValueKey('life-enabled'));
          await reach(toggle);
          await t.tap(toggle);
          await t.pumpAndSettle();
          final low = find.byKey(const ValueKey('life-frequency-low'));
          await reach(low);
          await t.tap(low);
          await t.pumpAndSettle();
          final prefs = await SharedPreferences.getInstance();
          final value = MentiAnimationPreference.decode(
            prefs.get(MentiAnimationSettings.key),
          );
          expect(value.enabled, false);
          expect(value.frequency, MentiAnimationFrequency.low);
          expect(prefs.getString(CompleteLookStore.key), raw);
          for (final r in MentiLifeReaction.values) {
            final f = find.byKey(ValueKey('life-reaction-${r.name}'));
            await reach(f);
            expect(t.widget<OutlinedButton>(f).onPressed, isNull);
          }
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox.shrink());
          await t.pumpAndSettle();
          store.dispose();
        },
      );
    }
  }
  testWidgets(
    'One largest visible surface owns video; hidden route and disabled policy return to identical PNG',
    (t) async {
      final c = MentiAnimationController(
        catalog: MentiAnimationCatalog([fixture()]),
        verify: (_) async {},
        factory: (_) => FakeMentiVideo(),
      );
      c.configure(
        look: 'boy-base-v1',
        allowed: true,
        frequency: MentiAnimationFrequency.normal,
      );
      Future<void> show(bool visible) => t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TickerMode(
                  enabled: visible,
                  child: MentiAnimationPlayer(
                    look: CompleteLook.all.first,
                    size: 200,
                    controller: c,
                  ),
                ),
                MentiAnimationPlayer(
                  look: CompleteLook.all.first,
                  size: 100,
                  controller: c,
                ),
              ],
            ),
          ),
        ),
      );
      await show(true);
      await t.pumpAndSettle();
      expect(
        c.request(MentiLifeReaction.welcome, token: 'manual', manual: true),
        true,
      );
      await t.pumpAndSettle();
      await t.runAsync(() => c.settled);
      await t.pump();
      expect(
        find.byKey(const ValueKey('real-video-test-surface')),
        findsOneWidget,
      );
      await show(false);
      await t.pumpAndSettle();
      await t.runAsync(() => c.settled);
      expect(
        find.byKey(const ValueKey('real-video-test-surface')),
        findsNothing,
      );
      expect(find.byType(CompleteLookArtwork), findsNWidgets(2));
      c.configure(
        look: 'boy-base-v1',
        allowed: false,
        frequency: MentiAnimationFrequency.normal,
      );
      expect(
        c.request(MentiLifeReaction.welcome, token: 'again', manual: true),
        false,
      );
      await t.pumpWidget(const SizedBox.shrink());
      await t.pumpAndSettle();
      c.dispose();
      await t.pump();
      await t.runAsync(() => c.settled);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'Scrolling the selected character out of viewport releases video and does not replay',
    (t) async {
      final c = MentiAnimationController(
        catalog: MentiAnimationCatalog([fixture()]),
        verify: (_) async {},
        factory: (_) => FakeMentiVideo(),
      );
      c.configure(
        look: 'boy-base-v1',
        allowed: true,
        frequency: MentiAnimationFrequency.normal,
      );
      final scroll = ScrollController();
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              controller: scroll,
              children: [
                MentiAnimationPlayer(
                  look: CompleteLook.all.first,
                  size: 160,
                  controller: c,
                ),
                const SizedBox(height: 1800),
              ],
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(c.hasVisibleHost, true);
      expect(
        c.request(MentiLifeReaction.welcome, token: 'scroll', manual: true),
        true,
      );
      await t.pumpAndSettle();
      await t.runAsync(() => c.settled);
      await t.pump();
      expect(
        find.byKey(const ValueKey('real-video-test-surface')),
        findsOneWidget,
      );
      scroll.jumpTo(700);
      await t.pumpAndSettle();
      await t.runAsync(() => c.settled);
      expect(c.hasVisibleHost, false);
      expect(c.handle, isNull);
      scroll.jumpTo(0);
      await t.pumpAndSettle();
      expect(c.hasVisibleHost, true);
      expect(c.active, isNull);
      expect(find.byType(CompleteLookArtwork), findsOneWidget);
      await t.pumpWidget(const SizedBox.shrink());
      await t.pumpAndSettle();
      c.dispose();
      await t.pump();
      await t.runAsync(() => c.settled);
      scroll.dispose();
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'Available reaction below the fold brings saved character into view before playback',
    (t) async {
      SharedPreferences.setMockInitialValues({
        CompleteLookStore.key: const CompleteLookSelection(active: true)
            .encode(),
      });
      final store = CompleteLookStore();
      await store.load();
      final c = MentiAnimationController(
        catalog: MentiAnimationCatalog([fixture(id: 'wink', reaction: 'wink')]),
        verify: (_) async {},
        factory: (_) => FakeMentiVideo(),
      );
      await t.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (ctx, child) => MediaQuery(
            data: MediaQuery.of(
              ctx,
            ).copyWith(disableAnimations: false, accessibleNavigation: false),
            child: CompleteLookScope(
              store: store,
              child: MentiMotionScope(
                child: MentiAnimationScope(controller: c, child: child!),
              ),
            ),
          ),
          home: const MentiAnimationPreviewPage(),
        ),
      );
      await t.pumpAndSettle();
      final play = find.byKey(const ValueKey('life-reaction-wink'));
      await t.scrollUntilVisible(play, 180, maxScrolls: 30);
      await t.pumpAndSettle();
      expect(c.hasVisibleHost, false);
      expect(t.widget<OutlinedButton>(play).onPressed, isNotNull);
      await t.tap(play);
      await t.pumpAndSettle();
      await t.runAsync(() => c.settled);
      await t.pump();
      expect(c.hasVisibleHost, true);
      expect(c.active?.reaction, MentiLifeReaction.wink);
      expect(
        find.byKey(const ValueKey('real-video-test-surface')),
        findsOneWidget,
      );
      await t.pumpWidget(const SizedBox.shrink());
      await t.pumpAndSettle();
      c.dispose();
      await t.pump();
      await t.runAsync(() => c.settled);
      store.dispose();
      expect(t.takeException(), isNull);
    },
  );
}
