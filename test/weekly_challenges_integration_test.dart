import 'support/adult_access_fixture.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/app_language.dart';
import 'package:mennyiment/daily_menti_store.dart';
import 'package:mennyiment/menti_character_setup.dart';
import 'package:mennyiment/menti_motion.dart';
import 'package:mennyiment/menti_profile_storage.dart';
import 'package:mennyiment/menti_rewards.dart';
import 'package:mennyiment/menti_xp_store.dart';
import 'package:mennyiment/main.dart';
import 'package:mennyiment/weekly_challenges.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';

const xpKey = 'mennyiment_menti_xp_v2';
Map<String, dynamic> item(DateTime date, {String status = 'active'}) => {
  'title': 'Séta / walk', 'goal': 3, 'status': status,
  'days': [challengeDate(date)],
};
Future<MentiXpState> morning(DateTime date) => DailyMentiStore.save(
  date: date, mood: 3, energy: 4, goal: 'Séta', evening: '',
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final day = DateTime(2026, 10, 25, 8);
  setUp(() => SharedPreferences.setMockInitialValues({adultAccessKey: adultAccessValue,
    xpKey: jsonEncode({'xp': 40, 'days': [], 'completed': [], 'future': 42}),
    'mennyiment_drinks_v1': '[]',
    MentiProfileStorage.characterStyleKey: 'girl',
    MentiProfileStorage.outfitKey: 'legendary',
    MentiRewards.preferenceKey: ['outfit:legendary', 'future:accessory'],
    'mennyiment_personal_goals_v1': '{"reflectionDays":["2026-10-24"]}',
  }));
  Future<Set<String>> rewards() async => MentiRewards.load(
    level: (await MentiXpStore.load()).level,
    assets: await MentiRewards.bundledAssets(),
  );
  test('A/B/C concurrent actions award one daily XP and retain durable unlocks', () async {
    final store = ChallengeStore();
    await store.load();
    await Future.wait<Object?>([
      morning(day), morning(day), MentiXpStore.checkInToday(now: day),
      store.put(day, 'reflection', item(day)),
      MentiXpStore.completeWeekly('goal'), MentiXpStore.completeWeekly('goal'),
    ]);
    final state = await MentiXpStore.load();
    expect(state.xp, 70); // 40 + daily 10 + existing weekly goal 20; C adds zero.
    expect(state.days, {'2026-10-25'});
    expect(state.completed.length, 1);
    expect(await rewards(), containsAll(['outfit:legendary', 'outfit:business', 'future:accessory']));
    expect(await store.put(day, 'custom', item(day, status: 'stopped')), true);
    expect(await store.put(day, 'habit', item(day, status: 'skipped')), true);
    expect((await MentiXpStore.load()).xp, 70);
    final prefs = await SharedPreferences.getInstance();
    expect(jsonDecode(prefs.getString(xpKey)!)['future'], 42);
    expect(prefs.getString('mennyiment_drinks_v1'), '[]');
    expect(prefs.getString('mennyiment_personal_goals_v1'), '{"reflectionDays":["2026-10-24"]}');
    expect(prefs.getString(MentiProfileStorage.outfitKey), 'legendary');
    SharedPreferences.setMockInitialValues({adultAccessKey: adultAccessValue,for (final k in prefs.getKeys()) k: prefs.get(k)!});
    final restored = ChallengeStore();
    await restored.load();
    expect(restored.week(day)['custom']['status'], 'stopped');
    expect((await morning(day)).xp, 70);
    expect(await rewards(), contains('outfit:legendary'));
  });
  test('Empty drink journal and challenge completion do not create daily XP or sober claims', () async {
    final store = ChallengeStore();
    await store.load();
    for (final id in ['reflection', 'journal', 'habit', 'custom']) {
      expect(await store.put(day, id, item(day)), true);
    }
    final prefs = await SharedPreferences.getInstance();
    expect((await MentiXpStore.load()).xp, 40);
    expect((await MentiXpStore.load()).days, isEmpty);
    expect(prefs.getString('mennyiment_drinks_v1'), '[]');
    expect(prefs.getKeys().any((k) => k.contains('alcohol_free') || k.contains('sober')), false);
  });
  test('Repeated Budapest hour and Monday rollover keep A once-per-day and C weeks separate', () async {
    final first = DateTime.utc(2026, 10, 25, 0, 30);
    final repeated = DateTime.utc(2026, 10, 25, 1, 30);
    if (Platform.environment['TZ'] == 'Europe/Budapest') {
      expect(first.toLocal().hour, 2);
      expect(repeated.toLocal().hour, 2);
      expect(first.toLocal().timeZoneOffset, const Duration(hours: 2));
      expect(repeated.toLocal().timeZoneOffset, const Duration(hours: 1));
    }
    final store = ChallengeStore();
    await store.load();
    await Future.wait<Object?>([
      morning(first), morning(repeated),
      store.put(first.toLocal(), 'habit', item(first.toLocal())),
    ]);
    expect((await MentiXpStore.load()).xp, 50);
    final monday = DateTime(2026, 10, 26);
    expect(store.week(monday), isEmpty);
    expect((await morning(monday)).xp, 60);
    expect(store.week(first.toLocal())['habit']['days'], ['2026-10-25']);
  });
  for (final locale in ['hu', 'en']) {
    testWidgets('$locale home → personal goals → challenges preserves morning XP/profile', (tester) async {
      tester.view.physicalSize = const Size(1100, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(MentiCharacterProfile.completedKey, true);
      await prefs.setBool(MentiMotionSettings.preferenceKey, true);
      await prefs.setString(AppLanguage.preferenceKey, locale);
      await morning(DateTime.now());
      final before = (await MentiXpStore.load()).xp;
      await tester.pumpWidget(const MennyiMentApp());
      await tester.pumpAndSettle();
      final s = appStrings(tester.element(find.byType(HomePage)));
      await tester.scrollUntilVisible(find.byKey(const ValueKey('home-more-features')),300,scrollable:find.byType(Scrollable).first,maxScrolls:40);
      await tester.tap(find.byKey(const ValueKey('home-more-features')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(s.personalGoals));
      await tester.tap(find.text(s.personalGoals));
      await tester.pumpAndSettle();
      await tester.tap(find.text(s.challengeTitle));
      await tester.pumpAndSettle();
      expect(find.byType(WeeklyChallengesPage), findsOneWidget);
      await tester.tap(find.text(s.challengeSkip).first);
      await tester.pumpAndSettle();
      expect(find.text(s.challengeSkipped), findsOneWidget);
      expect((await MentiXpStore.load()).xp, before);
      expect(prefs.getString(MentiProfileStorage.outfitKey), 'legendary');
      expect(prefs.getString('mennyiment_drinks_v1'), '[]');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
    testWidgets('$locale open goal dialog cannot write into the next week', (tester) async {
      var now = DateTime(2026, 10, 25, 23, 59);
      await tester.pumpWidget(MaterialApp(
        locale: Locale(locale),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: WeeklyChallengesPage(clock: () => now),
      ));
      await tester.pumpAndSettle();
      final s = appStrings(tester.element(find.byType(WeeklyChallengesPage)));
      await tester.tap(find.text(s.challengeChoose).first);
      await tester.pumpAndSettle();
      now = DateTime(2026, 10, 26, 0, 1);
      await tester.tap(find.text(s.challengeSave));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 400));
      expect((await SharedPreferences.getInstance()).getString(ChallengeStore.key), isNull);
      expect(find.text('2026-10-26 – 2026-11-01'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }
}
