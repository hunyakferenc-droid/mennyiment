import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:mennyiment/app_language.dart';
import 'package:mennyiment/daily_menti.dart';
import 'package:mennyiment/daily_menti_store.dart';
import 'package:mennyiment/main.dart';
import 'package:mennyiment/menti_character_catalog.dart';
import 'package:mennyiment/menti_character_setup.dart';
import 'package:mennyiment/menti_evolution.dart';
import 'package:mennyiment/menti_motion.dart';
import 'package:mennyiment/menti_profile_storage.dart';
import 'package:mennyiment/menti_progress.dart';
import 'package:mennyiment/menti_rewards.dart';
import 'package:mennyiment/menti_xp_store.dart';

class _FailedXpWrites extends InMemorySharedPreferencesStore {
  _FailedXpWrites(super.data) : super.withData();
  @override
  Future<bool> setValue(String type, String key, Object value) async =>
      key == 'flutter.mennyiment_menti_xp_v2'
          ? false : super.setValue(type, key, value);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const xpKey = 'mennyiment_menti_xp_v2';
  final day = DateTime(2026, 10, 31, 8);
  String xpDocument(int xp) => jsonEncode({
    'xp': xp, 'days': [], 'completed': [],
    'future': {'keep': 42},
  });
  Future<MentiXpState> save(DateTime date, {String evening = ''}) =>
      DailyMentiStore.save(date: date, mood: 3, energy: 4,
        goal: 'Séta', evening: evening);
  Future<Set<String>> rewards(MentiXpState state) async => MentiRewards.load(
    level: state.level, assets: await MentiRewards.bundledAssets(),
  );
  Future<void> coldReload() async {
    final prefs = await SharedPreferences.getInstance();
    SharedPreferences.setMockInitialValues({
      for (final key in prefs.getKeys()) key: prefs.get(key)!,
    });
  }
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Concurrent morning, daily and weekly events retain one daily reward and unlocks', () async {
    final journal = '[{"legacy":"unchanged","priceFt":0}]';
    SharedPreferences.setMockInitialValues({
      xpKey: xpDocument(40),
      MentiProfileStorage.characterStyleKey: 'Lány Menti',
      MentiProfileStorage.outfitKey: 'Legendás szett',
      'mennyiment_drinks_v1': journal,
      MentiRewards.preferenceKey: ['future:accessory'],
    });
    await rewards(await MentiXpStore.load());
    await Future.wait([
      save(day),
      MentiXpStore.checkInToday(now: day),
      MentiXpStore.completeWeekly('goal'),
      MentiXpStore.completeWeekly('goal'),
    ]);
    final state = await MentiXpStore.load();
    expect(state.xp, 70);
    expect(state.level, 2);
    expect(state.remainingXp, 30);
    expect(state.days, {'2026-10-31'});
    expect(state.completed.length, 1);
    expect(await rewards(state), containsAll([
      'outfit:business', 'outfit:legendary', 'future:accessory',
    ]));
    expect((await save(day, evening: 'Pihenés')).xp, 70);
    final prefs = await SharedPreferences.getInstance();
    expect(jsonDecode(prefs.getString(xpKey)!)['future'], {'keep': 42});
    expect(prefs.getString('mennyiment_drinks_v1'), journal);
    expect(prefs.getString(MentiProfileStorage.outfitKey), 'Legendás szett');
    await coldReload();
    expect((await MentiXpStore.load()).xp, 70);
    expect(await rewards(await MentiXpStore.load()), contains('outfit:legendary'));
    expect((await DailyMentiStore.load(day))['evening'], 'Pihenés');
  });

  test('Morning-first and progress-first both grant exactly ten XP per day', () async {
    for (final morningFirst in [true, false]) {
      SharedPreferences.setMockInitialValues({xpKey: xpDocument(40)});
      final first = morningFirst
        ? await save(day) : await MentiXpStore.checkInToday(now: day);
      final second = morningFirst
        ? await MentiXpStore.checkInToday(now: day) : await save(day);
      expect(first.xp, 50);
      expect(second.xp, 50);
      expect(second.days, {'2026-10-31'});
      expect(await rewards(second), contains('outfit:business'));
      // A free-text daily goal is not the separate weekly goal event.
      expect(second.completed, isEmpty);
    }
  });

  test('All 18 legacy profiles survive morning level-up, evening edits and cold reload', () async {
    for (final family in MentiCharacterFamily.values) {
      for (final outfit in MentiOutfit.values) {
        SharedPreferences.setMockInitialValues({
          xpKey: xpDocument(49),
          MentiProfileStorage.characterStyleKey: family.label,
          MentiProfileStorage.outfitKey: outfit.label,
          MentiCharacterProfile.nameKey: 'Régi Menti',
          'mennyiment_drinks_v1': '[{"future":true}]',
        });
        await rewards(await MentiXpStore.load());
        final state = await save(day);
        expect(state.xp, 59);
        expect(state.level, 2);
        expect(await rewards(state), contains('outfit:${outfit.id}'));
        expect((await save(day, evening: 'Kész')).xp, 59);
        await coldReload();
        final prefs = await SharedPreferences.getInstance();
        expect(MentiProfileStorage.assetPath(prefs), family.assetFor(outfit));
        expect(prefs.get(MentiProfileStorage.characterStyleKey), family.label);
        expect(prefs.get(MentiProfileStorage.outfitKey), outfit.label);
        expect(prefs.get(MentiCharacterProfile.nameKey), 'Régi Menti');
        expect(prefs.getString('mennyiment_drinks_v1'), '[{"future":true}]');
        expect((await MentiXpStore.load()).xp, 59);
        expect(await rewards(await MentiXpStore.load()), contains('outfit:${outfit.id}'));
      }
    }
  });

  test('Failed XP persistence preserves answers and unlocks only after a safe retry', () async {
    SharedPreferences.setMockInitialValues({xpKey: xpDocument(40)});
    final state = await MentiXpStore.load();
    expect(await rewards(state), isNot(contains('outfit:business')));
    final prefs = await SharedPreferences.getInstance();
    final original = SharedPreferencesStorePlatform.instance;
    addTearDown(() => SharedPreferencesStorePlatform.instance = original);
    SharedPreferencesStorePlatform.instance = _FailedXpWrites({
      for (final key in prefs.getKeys()) 'flutter.$key': prefs.get(key)!,
    });
    await expectLater(save(day), throwsStateError);
    expect((await DailyMentiStore.load(day))['goal'], 'Séta');
    expect((await MentiXpStore.load()).xp, 40);
    expect(await rewards(await MentiXpStore.load()), isNot(contains('outfit:business')));
    SharedPreferencesStorePlatform.instance = InMemorySharedPreferencesStore.withData({
      for (final key in prefs.getKeys()) 'flutter.$key': prefs.get(key)!,
    });
    final retried = await save(day);
    expect(retried.xp, 50);
    expect(await rewards(retried), contains('outfit:business'));
    expect((await save(day)).xp, 50);
    expect(jsonDecode(prefs.getString(xpKey)!)['future'], {'keep': 42});
  });

  test('Morning cannot overwrite corrupt XP or acquired reward data', () async {
    SharedPreferences.setMockInitialValues({
      xpKey: '{broken',
      MentiRewards.preferenceKey: ['outfit:legendary', 'future:item'],
    });
    await expectLater(save(day), throwsFormatException);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(xpKey), '{broken');
    expect(prefs.getStringList(MentiRewards.preferenceKey),
      ['outfit:legendary', 'future:item']);
    // Answers are intentionally committed first by 6.8-A.
    expect((await DailyMentiStore.load(day))['goal'], 'Séta');
  });

  test('DST repeated hour shares one daily reward, level-up and next local day', () async {
    SharedPreferences.setMockInitialValues({xpKey: xpDocument(49)});
    final first = DateTime.utc(2026, 10, 25, 0, 30);
    final repeated = DateTime.utc(2026, 10, 25, 1, 30);
    if (Platform.environment['TZ'] == 'Europe/Budapest') {
      expect(first.toLocal().hour, 2);
      expect(repeated.toLocal().hour, 2);
      expect(first.toLocal().timeZoneOffset, const Duration(hours: 2));
      expect(repeated.toLocal().timeZoneOffset, const Duration(hours: 1));
    }
    await Future.wait([
      save(first), MentiXpStore.checkInToday(now: first.toLocal()),
      save(repeated), MentiXpStore.checkInToday(now: repeated.toLocal()),
    ]);
    final state = await MentiXpStore.load();
    expect(state.xp, 59);
    expect(state.days.length, 1);
    expect(await rewards(state), contains('outfit:business'));
    expect((await save(DateTime(2026, 10, 26, 0, 1))).xp, 69);
    await coldReload();
    expect((await MentiXpStore.load()).xp, 69);
    expect(await rewards(await MentiXpStore.load()), contains('outfit:business'));
  });

  for (final locale in ['hu', 'en']) {
    testWidgets('$locale: home morning → progress → wardrobe → reopen shares XP and character', (tester) async {
      tester.view.physicalSize = const Size(1100, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({
        xpKey: xpDocument(40),
        AppLanguage.preferenceKey: locale,
        MentiMotionSettings.preferenceKey: true,
        MentiCharacterProfile.completedKey: true,
        MentiProfileStorage.characterStyleKey: 'girl',
        MentiProfileStorage.outfitKey: 'basic',
        'mennyiment_drinks_v1': '[]',
      });
      Future<void> openApp() async {
        await tester.pumpWidget(const MennyiMentApp());
        await tester.pumpAndSettle();
      }
      String character() => tester.widget<MentiEvolution>(
        find.byType(MentiEvolution).first).assetPath;
      await openApp();
      final s = appStrings(tester.element(find.byType(HomePage)));
      expect(character(), MentiCharacterFamily.girl.assetFor(MentiOutfit.basic));
      await tester.tap(find.text(s.dailyOpen));
      await tester.pumpAndSettle();
      expect(find.byType(DailyMentiPage), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('daily-save')));
      await tester.tap(find.byKey(const ValueKey('daily-save')));
      await tester.pumpAndSettle();
      expect((await MentiXpStore.load()).xp, 50);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text(s.dailyOpenSaved), findsOneWidget);
      expect(tester.widget<MentiEvolution>(find.byType(MentiEvolution)).level, 2);
      await tester.tap(find.text(s.mentiProgress).first);
      await tester.pumpAndSettle();
      expect(find.byType(MentiProgressPage), findsOneWidget);
      expect(find.text(s.evolutionRemaining(50)), findsOneWidget);
      expect(tester.widget<FilledButton>(find.widgetWithText(
        FilledButton, s.evolutionChecked)).onPressed, isNull);
      await tester.tap(find.text(s.evolutionWardrobe));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Üzleti szett'));
      await tester.tap(find.text('Üzleti szett'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Saját Menti mentése'));
      await tester.tap(find.text('Saját Menti mentése'));
      await tester.pumpAndSettle();
      expect(character(), MentiCharacterFamily.girl.assetFor(MentiOutfit.business));
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(character(), MentiCharacterFamily.girl.assetFor(MentiOutfit.business));
      // Reopening the morning form and editing answers cannot award a second daily XP.
      await tester.tap(find.text(s.dailyOpenSaved));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('daily-save')));
      await tester.tap(find.byKey(const ValueKey('daily-save')));
      await tester.pumpAndSettle();
      expect((await MentiXpStore.load()).xp, 50);
      expect(tester.hasRunningAnimations, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await coldReload();
      await openApp();
      expect(character(), MentiCharacterFamily.girl.assetFor(MentiOutfit.business));
      expect(tester.widget<MentiEvolution>(find.byType(MentiEvolution)).level, 2);
      expect((await MentiXpStore.load()).xp, 50);
      expect(tester.hasRunningAnimations, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }
}
