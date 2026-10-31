import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Test-only fault injection follows the existing journal regression tests.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:mennyiment/main.dart';
import 'package:mennyiment/app_language.dart';
import 'package:mennyiment/menti_evolution.dart';
import 'package:mennyiment/menti_motion.dart';

class _FailedJournalWrites extends InMemorySharedPreferencesStore {
  _FailedJournalWrites(super.data) : super.withData();
  @override
  Future<bool> setValue(String type, String key, Object value) async =>
      key == 'flutter.mennyiment_drinks_v1'
      ? false
      : super.setValue(type, key, value);
}

void main() {
  const journalKey = 'mennyiment_drinks_v1';
  const familyKey = 'mennyiment_character_style_v2';
  const outfitKey = 'mennyiment_outfit_v2';
  const xpKey = 'mennyiment_menti_xp_v2';
  final xp = jsonEncode({'xp': 150, 'days': [], 'completed': []});
  Map<String, Object> record() => {
    'name': 'Régi ital',
    'ml': 250,
    'percent': 4,
    'time': DateTime.now().toIso8601String(),
    'priceFt': 0,
    'legacy': {'preserve': true},
  };
  Future<void> frames(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
  }

  Future<SharedPreferences> open(
    WidgetTester tester,
    String journal, {
    String? locale,
    bool reduced = false,
  }) async {
    tester.view.physicalSize = const Size(1100, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      journalKey: journal,
      xpKey: xp,
      familyKey: 'Lány Menti',
      outfitKey: 'Legendás szett',
      'mennyiment_character_setup_complete_v1': true,
      AppLanguage.preferenceKey: ?locale,
      MentiMotionSettings.preferenceKey: reduced,
    });
    await tester.pumpWidget(const MennyiMentApp());
    await frames(tester);
    return SharedPreferences.getInstance();
  }

  MentiMotionSettings motion(WidgetTester tester) =>
      MentiMotionScope.settingsOf(tester.element(find.byType(MentiEvolution)))!;
  void profile(WidgetTester tester, SharedPreferences prefs) {
    expect(prefs.getString(familyKey), 'Lány Menti');
    expect(prefs.getString(outfitKey), 'Legendás szett');
    expect(prefs.getString(xpKey), xp);
    expect(
      tester.widget<MentiEvolution>(find.byType(MentiEvolution)).assetPath,
      'assets/images/menti_outfits_642/lany/legendas.png',
    );
  }

  Future<void> language(WidgetTester tester, String value) async {
    await tester.tap(find.byKey(const ValueKey('language-menu')));
    await frames(tester);
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is CheckedPopupMenuItem<String> && w.value == value,
      ),
    );
    await frames(tester);
  }

  Future<void> details(WidgetTester tester) async {
    await tester.ensureVisible(find.text('LOG A DRINK'));
    await tester.tap(find.text('LOG A DRINK'));
    await frames(tester);
    await tester.tap(find.text('Sör (általános)'));
    await frames(tester);
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  testWidgets(
    'HU/EN switching preserves motion scope, legacy profile and hardened journal save across restart',
    (tester) async {
      final old = record();
      final saved = jsonEncode([old]);
      final prefs = await open(tester, saved);
      expect(find.text('Kezdőlap'), findsOneWidget);
      await tester.tap(find.byTooltip('Menti és profil'));
      await frames(tester);
      await tester.ensureVisible(
        find.byKey(const ValueKey('menti-reduce-motion')),
      );
      await tester.tap(find.byKey(const ValueKey('menti-reduce-motion')));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      final sharedMotion = motion(tester);
      expect(sharedMotion.manual, true);
      await language(tester, 'en');
      expect(find.text('Home'), findsOneWidget);
      expect(identical(motion(tester), sharedMotion), isTrue);
      expect(tester.hasRunningAnimations, isFalse);
      expect(prefs.getString(journalKey), saved);
      profile(tester, prefs);
      await details(tester);
      final submit = tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Mentés a naplóba'),
          )
          .onPressed!;
      submit();
      submit();
      await frames(tester);
      final records = jsonDecode(prefs.getString(journalKey)!) as List;
      expect(records.length, 2);
      expect(records.last, old);
      profile(tester, prefs);
      await language(tester, 'hu');
      expect(find.text('Kezdőlap'), findsOneWidget);
      expect(identical(motion(tester), sharedMotion), isTrue);
      await language(tester, 'en');
      final persisted = {for (final k in prefs.getKeys()) k: prefs.get(k)!};
      await dispose(tester);
      SharedPreferences.setMockInitialValues(persisted);
      await tester.pumpWidget(const MennyiMentApp());
      await frames(tester);
      await tester.pumpAndSettle();
      final reloaded = await SharedPreferences.getInstance();
      expect(find.text('Home'), findsOneWidget);
      expect(motion(tester).manual, true);
      expect(tester.hasRunningAnimations, isFalse);
      expect((jsonDecode(reloaded.getString(journalKey)!) as List).length, 2);
      profile(tester, reloaded);
      expect(tester.takeException(), isNull);
      await dispose(tester);
    },
  );

  testWidgets(
    'Language changes cannot unlock or rewrite corrupt journal data',
    (tester) async {
      const broken = '[{"name":"broken"}]';
      final prefs = await open(tester, broken, reduced: true);
      for (final locale in ['en', 'auto', 'hu']) {
        await language(tester, locale);
        expect(find.byKey(const ValueKey('journal-error')), findsOneWidget);
        final label = appStrings(tester.element(find.byType(HomePage)))
            .addDrink;
        expect(
          tester
              .widget<FilledButton>(find.widgetWithText(FilledButton, label))
              .onPressed,
          isNull,
        );
        expect(prefs.getString(journalKey), broken);
        expect(prefs.getString(AppLanguage.preferenceKey), locale);
        expect(motion(tester).manual, true);
        profile(tester, prefs);
      }
      expect(tester.takeException(), isNull);
      await dispose(tester);
    },
  );

  testWidgets(
    'Automatic locale and live system reduction coexist with the manual setting',
    (tester) async {
      final dispatcher = tester.binding.platformDispatcher;
      addTearDown(dispatcher.clearLocalesTestValue);
      addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
      dispatcher.localesTestValue = const [Locale('en')];
      dispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      final prefs = await open(tester, '[]', locale: 'auto');
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
      final sharedMotion = motion(tester);
      dispatcher.localesTestValue = const [Locale('hu')];
      await tester.pumpAndSettle();
      expect(find.text('Kezdőlap'), findsOneWidget);
      expect(identical(motion(tester), sharedMotion), isTrue);
      expect(tester.hasRunningAnimations, isFalse);
      await sharedMotion.setReduced(true);
      dispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures();
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
      await language(tester, 'en');
      expect(identical(motion(tester), sharedMotion), isTrue);
      await sharedMotion.setReduced(false);
      await frames(tester);
      expect(tester.hasRunningAnimations, isTrue);
      profile(tester, prefs);
      expect(prefs.getString(journalKey), '[]');
      expect(tester.takeException(), isNull);
      await dispose(tester);
    },
  );

  testWidgets(
    'Failed journal writes remain protected in English with reduced motion',
    (tester) async {
      final saved = jsonEncode([record()]);
      final prefs = await open(tester, saved, locale: 'en', reduced: true);
      final store = SharedPreferencesStorePlatform.instance;
      addTearDown(() => SharedPreferencesStorePlatform.instance = store);
      SharedPreferencesStorePlatform.instance = _FailedJournalWrites({
        for (final k in prefs.getKeys()) 'flutter.$k': prefs.get(k)!,
      });
      await details(tester);
      await tester.tap(find.text('Mentés a naplóba'));
      await frames(tester);
      await prefs.reload();
      expect(prefs.getString(journalKey), saved);
      expect(find.byKey(const ValueKey('journal-error')), findsOneWidget);
      expect(find.textContaining('mentve a naplóba'), findsNothing);
      expect(find.text('Home'), findsOneWidget);
      expect(motion(tester).manual, true);
      profile(tester, prefs);
      expect(tester.takeException(), isNull);
      await dispose(tester);
    },
  );
}
