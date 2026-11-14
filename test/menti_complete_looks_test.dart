import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:mennyiment/menti_complete_looks.dart';
import 'package:mennyiment/data_backup.dart';
import 'package:mennyiment/data_restore.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';
import 'package:mennyiment/menti_identity/menti_avatar_renderer.dart';
import 'package:mennyiment/menti_identity/menti_identity.dart';

import 'personal_hub_fixtures.dart';

import 'package:mennyiment/personal_hub.dart';
import 'package:mennyiment/menti_identity/menti_identity_controller.dart';

class LookFaults extends InMemorySharedPreferencesStore {
  LookFaults(
    super.data, {
    this.persist = false,
    this.throwing = false,
    this.gate,
  }) : super.withData();
  final bool persist, throwing;
  final Completer<void>? gate;
  int writes = 0;
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (key == 'flutter.${CompleteLookStore.key}') {
      writes++;
      await gate?.future;
      if (persist) await super.setValue(type, key, value);
      if (throwing) throw StateError('Injected disk failure');
      return gate != null ? super.setValue(type, key, value) : false;
    }
    return super.setValue(type, key, value);
  }
}

Future<Map<String, Object?>> snapshot() async {
  final p = await SharedPreferences.getInstance();
  await p.reload();
  return {for (final k in p.getKeys()) k: p.get(k)};
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('Collection has 15 distinct free starters and 3 real XP looks, with RGBA assets', () {
    expect(CompleteLook.all.length, 18);
    expect(CompleteLook.all.where((e) => e.minXp == 0).length, 15);
    expect(CompleteLook.all.where((e) => e.minXp > 0).length, 3);
    expect(CompleteLook.all.map((e) => e.id).toSet().length, 18);
    expect(CompleteLook.all.map((e) => e.family).toSet(), {
      'boy',
      'girl',
      'neutral',
    });
    for (final e in CompleteLook.all) {
      expect(e.unlock, e.style == 'legendary' ? 'xp:200' : 'free');
      final bytes = File(e.asset).readAsBytesSync();
      expect(bytes.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
      expect(bytes[25], 6); // PNG RGBA
    }
  });
  test('Read-only defaults, all choices reload, legacy switch preserves every old byte', () async {
    final original = hubValues(DateTime(2026, 11, 13));
    SharedPreferences.setMockInitialValues(original);
    final store = CompleteLookStore();
    await store.load();
    expect(store.selection.active, false);
    expect(await snapshot(), original);
    for (final look in CompleteLook.all.where((l) => l.minXp == 0)) {
      expect(
        await store.save(CompleteLookSelection(active: true, lookId: look.id)),
        true,
      );
      final reloaded = CompleteLookStore();
      await reloaded.load();
      expect(reloaded.selection.active, true);
      expect(reloaded.selection.lookId, look.id);
      reloaded.dispose();
    }
    expect(
      await store.save(
        CompleteLookSelection(active: false, lookId: 'neutral-base-v1'),
      ),
      true,
    );
    final after = await snapshot();
    after.remove(CompleteLookStore.key);
    expect(after, original);
    store.dispose();
  });
  test('Malformed, future, ambiguous extension and unknown IDs never become writable', () async {
    for (final raw in [
      false,
      '{',
      '{"version":2,"active":true,"look":"girl-base-v1"}',
      '{"version":1,"active":true,"look":"future"}',
      '{"version":1,"active":true,"look":"girl-base-v1","acquired":[]}',
      '{"version":1,"version":1,"active":true,"look":"girl-base-v1"}',
    ]) {
      SharedPreferences.setMockInitialValues({CompleteLookStore.key: raw});
      final store = CompleteLookStore();
      await store.load();
      expect(store.ready, false);
      expect(
        await store.save(const CompleteLookSelection(active: true)),
        false,
      );
      expect((await snapshot())[CompleteLookStore.key], raw);
      store.dispose();
    }
  });
  test(
    'Stale store cannot overwrite newer selection, even for idempotent save',
    () async {
      final a = CompleteLookStore(), b = CompleteLookStore();
      await a.load();
      await b.load();
      expect(
        await a.save(
          const CompleteLookSelection(active: true, lookId: 'girl-base-v1'),
        ),
        true,
      );
      expect(await b.save(const CompleteLookSelection()), false);
      expect(b.error, 'conflict');
      expect(b.ready, false);
      await b.load();
      expect(b.selection.lookId, 'girl-base-v1');
      a.dispose();
      b.dispose();
    },
  );
  for (final persist in [false, true]) {
    for (final throwing in [false, true]) {
      test(
        'Unconfirmed write does not publish success: persist=$persist throw=$throwing',
        () async {
          final store = CompleteLookStore();
          await store.load();
          final platform = SharedPreferencesStorePlatform.instance;
          addTearDown(() => SharedPreferencesStorePlatform.instance = platform);
          SharedPreferencesStorePlatform.instance = LookFaults(
            {},
            persist: persist,
            throwing: throwing,
          );
          expect(
            await store.save(
              const CompleteLookSelection(active: true, lookId: 'girl-base-v1'),
            ),
            false,
          );
          expect(store.selection.active, false);
          expect(store.error, 'save');
          expect(store.saving, false);
          if (persist) {
            expect(await store.save(const CompleteLookSelection()), false);
            expect(store.error, 'conflict');
          }
          store.dispose();
        },
      );
    }
  }
  test(
    'Double tap and competing store are blocked while persistence is pending',
    () async {
      final a = CompleteLookStore(), b = CompleteLookStore();
      await a.load();
      await b.load();
      final platform = SharedPreferencesStorePlatform.instance;
      addTearDown(() => SharedPreferencesStorePlatform.instance = platform);
      final gate = Completer<void>();
      final fault = LookFaults({}, gate: gate);
      SharedPreferencesStorePlatform.instance = fault;
      final first = a.save(const CompleteLookSelection(active: true));
      expect(await a.save(const CompleteLookSelection()), false);
      expect(
        await b.save(
          const CompleteLookSelection(active: true, lookId: 'girl-base-v1'),
        ),
        false,
      );
      expect(a.selection.active, false);
      gate.complete();
      expect(await first, true);
      expect(fault.writes, 1);
      a.dispose();
      b.dispose();
    },
  );
  test('Backup/restore carries exact new choice and old data; older backup overlays safely', () async {
    final original = hubValues(DateTime(2026, 11, 13));
    final selection = const CompleteLookSelection(
      active: true,
      lookId: 'girl-base-v1',
    ).encode();
    SharedPreferences.setMockInitialValues({
      ...original,
      CompleteLookStore.key: selection,
    });
    final backup = await BackupExporter().capture();
    SharedPreferences.setMockInitialValues({});
    final restorer = BackupRestorer();
    await restorer.restore(
      await restorer.prepare(backup.json),
      confirmed: true,
    );
    expect(await snapshot(), {
      for (final e in original.entries)
        if (BackupDocument.ownedKey(e.key)) e.key: e.value,
      CompleteLookStore.key: selection,
    });
    final root = jsonDecode(backup.json) as Map<String, dynamic>;
    (root['entries'] as Map).remove(CompleteLookStore.key);
    await restorer.restore(
      await restorer.prepare(jsonEncode(root)),
      confirmed: true,
    );
    expect((await snapshot())[CompleteLookStore.key], selection);
    final p = await SharedPreferences.getInstance();
    await p.setString(CompleteLookStore.key, '{"version":99}');
    await expectLater(restorer.prepare(backup.json), throwsFormatException);
    expect((await snapshot())[CompleteLookStore.key], '{"version":99}');
  });
  test('Restore rollback pending blocks new selection writes', () async {
    SharedPreferences.setMockInitialValues({
      '__mennyiment_restore_rollback_v1': 'pending',
    });
    final store = CompleteLookStore();
    await store.load();
    expect(await store.save(const CompleteLookSelection(active: true)), false);
    expect((await snapshot()).containsKey(CompleteLookStore.key), false);
    store.dispose();
  });

  for (final locale in ['hu', 'en']) {
    for (final look in CompleteLook.all.where((l) => l.minXp == 0)) {
      testWidgets(
        '$locale actual personal hub displays ${look.id} without changing the legacy profile',
        (tester) async {
          tester.view.physicalSize = const Size(320, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final now = DateTime(2026, 11, 13);
          final original = hubValues(now);
          SharedPreferences.setMockInitialValues(original);
          final store = CompleteLookStore();
          await store.load();
          await tester.pumpWidget(
            MentiIdentityScope(
              child: CompleteLookScope(
                store: store,
                child: MaterialApp(
                  locale: Locale(locale),
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: const TextScaler.linear(2),
                      disableAnimations: true,
                    ),
                    child: child!,
                  ),
                  home: PersonalHubPage(clock: () => now),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final panel = find.byKey(const ValueKey('hub-profile'));
          await tester.scrollUntilVisible(
            panel,
            200,
            scrollable: find.byType(Scrollable).first,
            maxScrolls: 50,
          );
          await tester.pumpAndSettle();
          final legacyTexts = tester
              .widgetList<Text>(
                find.descendant(of: panel, matching: find.byType(Text)),
              )
              .map((t) => t.data)
              .toList();
          expect(legacyTexts, isNotEmpty);
          expect(await snapshot(), original);
          expect(
            await store.save(
              CompleteLookSelection(active: true, lookId: look.id),
            ),
            true,
          );
          await tester.pumpAndSettle();
          final name = look.name(tester.element(panel));
          expect(
            find.descendant(of: panel, matching: find.text(name)),
            findsOneWidget,
          );
          expect(
            tester
                .widget<CompleteLookArtwork>(
                  find.descendant(
                    of: panel,
                    matching: find.byType(CompleteLookArtwork),
                  ),
                )
                .look
                .id,
            look.id,
          );
          final after = await snapshot();
          after.remove(CompleteLookStore.key);
          expect(after, original);
          expect(
            await store.save(
              CompleteLookSelection(active: false, lookId: look.id),
            ),
            true,
          );
          await tester.pumpAndSettle();
          expect(
            tester
                .widgetList<Text>(
                  find.descendant(of: panel, matching: find.byType(Text)),
                )
                .map((t) => t.data)
                .toList(),
            legacyTexts,
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          store.dispose();
        },
      );
    }
  }
  for (final locale in ['hu', 'en']) {
    for (final width in [320.0, 360.0, 390.0, 430.0]) {
      testWidgets(
        '$locale ${width}px 200% choose/cancel/save/reload/legacy/common renderer',
        (tester) async {
          tester.view.physicalSize = Size(width, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final original = hubValues(DateTime(2026, 11, 13));
          SharedPreferences.setMockInitialValues(original);
          final store = CompleteLookStore();
          await store.load();
          final nav = GlobalKey<NavigatorState>();
          await tester.pumpWidget(
            CompleteLookScope(
              store: store,
              child: MaterialApp(
                navigatorKey: nav,
                locale: Locale(locale),
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                builder: (ctx, child) => MediaQuery(
                  data: MediaQuery.of(ctx).copyWith(
                    textScaler: const TextScaler.linear(2),
                    disableAnimations: true,
                  ),
                  child: child!,
                ),
                home: Scaffold(
                  body: Column(
                    children: [
                      MentiAvatarRenderer(
                        profile: MentiIdentityProfile(),
                        size: 100,
                      ),
                      Builder(
                        builder: (ctx) => TextButton(
                          onPressed: () => Navigator.push(
                            ctx,
                            MaterialPageRoute<void>(
                              builder: (_) => const CompleteLooksPage(),
                            ),
                          ),
                          child: const Text('open'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          Future<void> tapKey(String key) async {
            final finder = find.byKey(ValueKey(key));
            if (finder.evaluate().isEmpty) {
              tester
                  .state<ScrollableState>(find.byType(Scrollable).last)
                  .position
                  .jumpTo(0);
              await tester.pumpAndSettle();
            }
            if (finder.evaluate().isEmpty) {
              await tester.scrollUntilVisible(
                finder,
                220,
                maxScrolls: 150,
                scrollable: find.byType(Scrollable).last,
              );
            }
            await tester.ensureVisible(finder);
            await tester.pumpAndSettle();
            await tester.tap(finder);
            await tester.pumpAndSettle();
          }

          await tester.tap(find.text('open'));
          await tester.pumpAndSettle();
          await tapKey('complete-girl-base-v1');
          expect(await snapshot(), original);
          await tapKey('complete-cancel');
          expect(find.byType(AlertDialog), findsOneWidget);
          final s = locale == 'hu'
              ? 'Elvetés és vissza'
              : 'Discard and go back';
          await tester.tap(find.text(s));
          await tester.pumpAndSettle();
          expect(await snapshot(), original);
          await tester.tap(find.text('open'));
          await tester.pumpAndSettle();
          for (final look in [
            ...CompleteLook.all.where(
              (l) => l.minXp == 0 && l.id != 'neutral-base-v1',
            ),
            CompleteLook.find('neutral-base-v1')!,
          ]) {
            await tapKey('complete-${look.id}');
            expect(tester.takeException(), isNull);
          }
          final scroll = tester.state<ScrollableState>(
            find.byType(Scrollable).last,
          );
          scroll.position.jumpTo(0);
          await tester.pumpAndSettle();
          await tapKey('complete-enlarge');
          expect(find.byType(InteractiveViewer), findsOneWidget);
          expect(
            tester
                .widget<InteractiveViewer>(find.byType(InteractiveViewer))
                .maxScale,
            3,
          );
          final enlarged = tester.widget<CompleteLookArtwork>(
            find.descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(CompleteLookArtwork),
            ),
          );
          expect(enlarged.look.id, 'neutral-base-v1');
          final zoomImage = tester.widget<Image>(
            find.descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(Image),
            ),
          );
          // At 320 px the magnifier must decode more than the low-res preview;
          // otherwise actual 3x touch zoom blurs the face.
          expect(
            (zoomImage.image as ResizeImage).width,
            greaterThanOrEqualTo(600),
          );
          final strings = AppLocalizations.of(
            tester.element(find.byType(AlertDialog)),
          )!;
          await tester.ensureVisible(find.text(strings.avatarClosePreview));
          await tester.tap(find.text(strings.avatarClosePreview));
          await tester.pumpAndSettle();
          await tapKey('complete-girl-base-v1');
          // Keyboard/inset cannot hide scrollable Save/Cancel.
          tester.view.viewInsets = const FakeViewPadding(bottom: 300);
          await tester.pumpAndSettle();
          await tapKey('complete-save');
          tester.view.resetViewInsets();
          await tester.pumpAndSettle();
          expect(store.selection.lookId, 'girl-base-v1');
          expect(store.selection.active, true);
          final artwork = tester.widget<CompleteLookArtwork>(
            find.byType(CompleteLookArtwork),
          );
          expect(artwork.look.id, 'girl-base-v1');
          final reload = CompleteLookStore();
          await reload.load();
          expect(reload.selection.lookId, 'girl-base-v1');
          reload.dispose();
          await tester.tap(find.text('open'));
          await tester.pumpAndSettle();
          await tapKey('complete-legacy');
          await tapKey('complete-save');
          expect(store.selection.active, false);
          expect(find.byType(CompleteLookArtwork), findsNothing);
          final after = await snapshot();
          after.remove(CompleteLookStore.key);
          expect(after, original);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          store.dispose();
        },
      );
    }
  }
}
