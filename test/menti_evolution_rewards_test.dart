import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/menti_xp_store.dart';
import 'package:mennyiment/menti_rewards.dart';
import 'package:mennyiment/menti_character_catalog.dart';
import 'package:mennyiment/menti_profile_storage.dart';
import 'package:mennyiment/menti_progress.dart';
import 'package:mennyiment/menti_motion.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const xpKey = 'mennyiment_menti_xp_v2';
  Set<String> allAssets() => {
    for (final family in MentiCharacterFamily.values)
      for (final outfit in MentiOutfit.values) family.assetFor(outfit),
  };
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('XP boundaries, remainder and large existing totals survive reopening', () async {
    for (final xp in [0, 49, 50, 99, 100, 199, 200, 10000050]) {
      SharedPreferences.setMockInitialValues({
        xpKey: jsonEncode({'xp': xp, 'days': [], 'completed': []}),
      });
      final state = await MentiXpStore.load();
      expect(state.xp, xp);
      expect(state.level, 1 + xp ~/ 50);
      expect(state.remainingXp, 50 - xp % 50);
      final prefs = await SharedPreferences.getInstance();
      SharedPreferences.setMockInitialValues({
        for (final key in prefs.getKeys()) key: prefs.get(key)!,
      });
      expect((await MentiXpStore.load()).xp, xp);
    }
  });

  test('Legacy XP maximum is migrated once without duplicating daily reflection', () async {
    final today = MentiXpStore.dayKey(DateTime.now());
    final legacy = jsonEncode({'xp': 350, 'lastCheckin': today, 'completed': []});
    SharedPreferences.setMockInitialValues({
      'mennyiment_menti_progress_v1': legacy,
      'mennyiment_reflection_days_v1': [today],
    });
    expect((await MentiXpStore.load()).xp, 350);
    expect((await MentiXpStore.checkInToday()).xp, 350);
    expect((await MentiXpStore.load()).xp, 350);
    expect((await SharedPreferences.getInstance()).getString('mennyiment_menti_progress_v1'), legacy);
  });

  test('Daily and weekly events grant once; drinks and spending do not grant XP', () async {
    final first = await MentiXpStore.checkInToday();
    expect(first.xp, 10);
    expect((await MentiXpStore.checkInToday()).xp, 10);
    expect((await MentiXpStore.completeWeekly('goal')).xp, 30);
    expect((await MentiXpStore.completeWeekly('goal')).xp, 30);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mennyiment_drinks_v1',
      jsonEncode([{'ml': 500, 'percent': 40, 'priceFt': 999999}]));
    expect((await MentiXpStore.load()).xp, 30);
    expect(() => MentiXpStore.completeWeekly('drink'), throwsArgumentError);
  });

  test('Missed days never remove XP, events or acquired outfits', () async {
    SharedPreferences.setMockInitialValues({
      xpKey: jsonEncode({'xp': 190, 'days': ['2020-01-01'], 'completed': ['2020-01-06:goal']}),
    });
    final state = await MentiXpStore.load();
    expect(state.xp, 190);
    expect(state.days, {'2020-01-01'});
    expect(state.completed, {'2020-01-06:goal'});
  });

  test('Unlock thresholds and next reward are explicit', () async {
    final assets = allAssets();
    for (final level in [1, 2, 3, 4, 5]) {
      SharedPreferences.setMockInitialValues({});
      final unlocked = await MentiRewards.load(level: level, assets: assets);
      expect(unlocked, {
        for (final outfit in MentiOutfit.values)
          if (outfit.requiredLevel <= level) 'outfit:${outfit.id}',
      });
      final next = MentiRewards.next(unlocked, assets);
      expect(next?.requiredLevel, switch (level) { 1 => 2, 2 => 3, 3 || 4 => 5, _ => null });
    }
  });

  test('All 18 legacy equipped outfits stay unlocked after switching and cold reload', () async {
    for (final family in MentiCharacterFamily.values) {
      for (final outfit in MentiOutfit.values) {
        SharedPreferences.setMockInitialValues({
          MentiProfileStorage.characterStyleKey: family.label,
          MentiProfileStorage.outfitKey: outfit.label,
          MentiRewards.preferenceKey: ['future:accessory'],
        });
        final assets = allAssets();
        final unlocked = await MentiRewards.load(level: 1, assets: assets);
        expect(unlocked, contains('outfit:${outfit.id}'));
        expect(unlocked, contains('future:accessory'));
        final prefs = await SharedPreferences.getInstance();
        expect(MentiProfileStorage.assetPath(prefs), family.assetFor(outfit));
        await prefs.setString(MentiProfileStorage.outfitKey, 'basic');
        SharedPreferences.setMockInitialValues({
          for (final key in prefs.getKeys()) key: prefs.get(key)!,
        });
        expect(await MentiRewards.load(level: 1, assets: assets), contains('outfit:${outfit.id}'));
      }
    }
  });

  test('Missing artwork never unlocks or advertises a new reward', () async {
    final assets = allAssets()..remove(MentiCharacterFamily.girl.assetFor(MentiOutfit.business));
    final unlocked = await MentiRewards.load(level: 2, assets: assets);
    expect(unlocked, isNot(contains('outfit:business')));
    expect(MentiRewards.next(unlocked, assets)?.outfit, MentiOutfit.festival);
    final actual = await MentiRewards.bundledAssets();
    expect(MentiRewards.catalog.every((reward) => reward.available(actual)), isTrue);
  });

  test('Unreadable rewards are preserved rather than replaced', () async {
    SharedPreferences.setMockInitialValues({MentiRewards.preferenceKey: 'future-format'});
    await expectLater(MentiRewards.load(level: 5, assets: allAssets()), throwsStateError);
    expect((await SharedPreferences.getInstance()).get(MentiRewards.preferenceKey), 'future-format');
  });

  for (final locale in ['hu', 'en']) {
    testWidgets('$locale progress, badge rules and reduced motion survive reopening', (tester) async {
      tester.view.physicalSize = const Size(400, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({
        xpKey: jsonEncode({
          'xp': 100,
          'days': ['2020-01-01', '2020-02-01', '2020-03-01', '2020-04-01', '2020-05-01', '2020-06-01', '2020-07-01'],
          'completed': ['2020-01-06:goal'],
        }),
        MentiMotionSettings.preferenceKey: true,
      });
      Future<void> open() async {
        await tester.pumpWidget(MaterialApp(
          locale: Locale(locale),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const MentiMotionScope(child: MentiProgressPage()),
        ));
        await tester.pumpAndSettle();
      }
      await open();
      expect(find.text(locale == 'en' ? '50 XP to the next level' : 'Még 50 XP a következő szintig'), findsOneWidget);
      expect(find.text(locale == 'en' ? 'Legendary outfit' : 'Legendás szett'), findsOneWidget);
      await tester.scrollUntilVisible(find.text(locale == 'en' ? 'Achievement badges' : 'Teljesítményjelvények'),
        400, scrollable: find.byType(Scrollable).first);
      expect(find.text(locale == 'en' ? 'Earned' : 'Megszerzett'), findsNWidgets(3));
      expect(tester.hasRunningAnimations, isFalse);
      expect(tester.takeException(), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect((await MentiXpStore.load()).xp, 100);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      SharedPreferences.setMockInitialValues({
        for (final key in prefs.getKeys()) key: prefs.get(key)!,
      });
      await open();
      expect(find.text(locale == 'en' ? '50 XP to the next level' : 'Még 50 XP a következő szintig'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }
}
