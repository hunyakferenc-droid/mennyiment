import 'dart:convert';
import 'dart:io';
import 'package:mennyiment/l10n/generated/app_localizations.dart';
import 'package:mennyiment/app_language.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/weekly_challenges.dart';

Map<String, dynamic> challenge({int goal = 4, String status = 'active'}) => {
  'title': 'Saját cél', 'goal': goal, 'status': status,
  'days': ['2026-10-25'],
};

class FailedChallengeWrites extends InMemorySharedPreferencesStore {
  FailedChallengeWrites(super.data) : super.withData();
  @override
  Future<bool> setValue(String type, String key, Object value) async =>
      key == 'flutter.${ChallengeStore.key}' ? false : super.setValue(type, key, value);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({
    'mennyiment_personal_goals_v1': '{"reflectionGoal":4}',
    'mennyiment_menti_xp_v2': 'unchanged',
  }));
  test('Calendar weeks cross DST, year boundary and Sunday correctly', () {
    for (final date in [DateTime(2026, 3, 29), DateTime(2026, 10, 25), DateTime(2027, 1, 3)]) {
      final monday = challengeMonday(date);
      expect(monday.weekday, DateTime.monday);
      expect(challengeDay(monday, 6), challengeDay(date));
      expect(challengeMonday(challengeDay(date, 1)), challengeDay(monday, 7));
      expect(challengeDay(monday, 7).hour, 0);
    }
  });
  test('Editing, stopping and skipping preserve history and legacy data', () async {
    final store = ChallengeStore();
    await store.load();
    final sunday = DateTime(2026, 10, 25);
    expect(await store.put(sunday, 'custom', challenge()), true);
    expect(await store.put(sunday, 'custom', challenge(goal: 2, status: 'stopped')), true);
    final next = challengeDay(sunday, 1);
    expect(store.week(next), isEmpty);
    expect(await store.put(next, 'custom', challenge(status: 'skipped')), true);
    final restored = ChallengeStore();
    await restored.load();
    expect(restored.week(sunday)['custom']['days'], ['2026-10-25']);
    expect(restored.week(sunday)['custom']['goal'], 2);
    expect(restored.week(next)['custom']['status'], 'skipped');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('mennyiment_personal_goals_v1'), '{"reflectionGoal":4}');
    expect(prefs.getString('mennyiment_menti_xp_v2'), 'unchanged');
  });
  test('Corrupt and future data stay protected', () async {
    final prefs = await SharedPreferences.getInstance();
    for (final raw in ['broken', jsonEncode({'version': 2, 'weeks': {}})]) {
      await prefs.setString(ChallengeStore.key, raw);
      final store = ChallengeStore();
      await expectLater(store.load(), throwsA(anything));
      expect(await store.put(DateTime(2026), 'custom', challenge()), false);
      expect(prefs.getString(ChallengeStore.key), raw);
    }
  });
  test('Failed storage access retains confirmed state', () async {
    var fail = false;
    final store = ChallengeStore(open: () {
      if (fail) throw StateError('write failure');
      return SharedPreferences.getInstance();
    });
    await store.load();
    fail = true;
    expect(await store.put(DateTime(2026), 'custom', challenge()), false);
    expect(store.week(DateTime(2026)), isEmpty);
    expect(store.busy, false);
  });
  test('False write result reloads phantom cache and retries without data loss', () async {
    final store = ChallengeStore();
    await store.load();
    final prefs = await SharedPreferences.getInstance();
    final platform = SharedPreferencesStorePlatform.instance;
    addTearDown(() => SharedPreferencesStorePlatform.instance = platform);
    SharedPreferencesStorePlatform.instance = FailedChallengeWrites({
      for (final key in prefs.getKeys()) 'flutter.$key': prefs.get(key)!,
    });
    expect(await store.put(DateTime(2026), 'custom', challenge()), false);
    expect(store.week(DateTime(2026)), isEmpty);
    expect(prefs.getString(ChallengeStore.key), isNull);
    SharedPreferencesStorePlatform.instance = platform;
    expect(await store.put(DateTime(2026), 'custom', challenge()), true);
  });
  test('Two stale stores cannot erase one another and can recover by reloading', () async {
    final a = ChallengeStore();
    final b = ChallengeStore();
    await a.load();
    await b.load();
    expect(await a.put(DateTime(2026), 'reflection', challenge()), true);
    expect(await b.put(DateTime(2026), 'custom', challenge()), false);
    await b.load();
    expect(await b.put(DateTime(2026), 'custom', challenge()), true);
    await a.load();
    expect(a.week(DateTime(2026)).keys, containsAll(['reflection', 'custom']));
  });
  test('Budapest DST weeks have seven dates despite 167 or 169 elapsed hours', () {
    if (Platform.environment['TZ'] != 'Europe/Budapest') return;
    for (final pair in [(DateTime(2026, 3, 23), 167), (DateTime(2026, 10, 19), 169)]) {
      expect(challengeDay(pair.$1, 7).difference(pair.$1).inHours, pair.$2);
      expect({for (var i = 0; i < 7; i++) challengeDate(challengeDay(pair.$1, i))}.length, 7);
    }
  });
  for (final locale in ['hu', 'en']) {
    testWidgets('$locale narrow challenge page does not infer alcohol-free days', (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
        locale: Locale(locale),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: WeeklyChallengesPage(clock: () => DateTime(2026, 10, 25)),
      ));
      await tester.pumpAndSettle();
      final strings = appStrings(tester.element(find.byType(WeeklyChallengesPage)));
      expect(find.text(strings.challengeTitle), findsOneWidget);
      await tester.ensureVisible(find.text(strings.challengeCaution));
      await tester.pumpAndSettle();
      expect(find.text('${strings.challengeJournalDays}: 0 / 7'), findsOneWidget);
      expect((await SharedPreferences.getInstance()).getString(ChallengeStore.key), isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }
}
