import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:mennyiment/daily_menti.dart';
import 'package:mennyiment/daily_menti_store.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';
import 'package:mennyiment/menti_motion.dart';
import 'package:mennyiment/menti_xp_store.dart';

class _FailedWrites extends InMemorySharedPreferencesStore {
  _FailedWrites(super.data, this.failedKey) : super.withData();
  final String failedKey;
  @override
  Future<bool> setValue(String type, String key, Object value) async =>
      key == 'flutter.$failedKey' ? false : super.setValue(type, key, value);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const xpKey = 'mennyiment_menti_xp_v2';
  final day = DateTime(2026, 10, 31, 8);

  Future<MentiXpState> save(DateTime date, {int? mood, int? energy,
      String goal = '', String evening = ''}) => DailyMentiStore.save(
    date: date, mood: mood, energy: energy, goal: goal, evening: evening,
  );

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Daily and existing check-ins share one reward under concurrent calls', () async {
    await Future.wait([
      save(day, mood: 2),
      MentiXpStore.checkInToday(now: day),
      save(day, energy: 4),
      MentiXpStore.checkInToday(now: day),
    ]);
    final state = await MentiXpStore.load();
    expect(state.xp, 10);
    expect(state.days, {'2026-10-31'});
    expect((await save(day)).xp, 10);
  });

  test('Weekly reward and daily reward cannot overwrite each other', () async {
    await Future.wait([
      MentiXpStore.checkInToday(now: day),
      MentiXpStore.completeWeekly('review'),
      MentiXpStore.completeWeekly('review'),
    ]);
    expect((await MentiXpStore.load()).xp, 25);
  });

  test('Reopening retains answers and evening updates do not reward twice', () async {
    await save(day, mood: 2, energy: 4, goal: 'Pihenő');
    final prefs = await SharedPreferences.getInstance();
    SharedPreferences.setMockInitialValues({
      for (final k in prefs.getKeys()) k: prefs.get(k)!,
    });
    expect(await DailyMentiStore.load(day), {
      'mood': 2, 'energy': 4, 'goal': 'Pihenő', 'evening': '',
    });
    expect((await save(day, mood: 2, energy: 4, goal: 'Pihenő',
      evening: 'Jól esett a séta')).xp, 10);
  });

  test('Local midnight starts a new day; missed days never deduct XP', () async {
    await save(DateTime(2026, 10, 31, 23, 59));
    await save(DateTime(2026, 11, 1, 0, 1));
    expect((await save(DateTime(2026, 11, 5))).xp, 30);
    expect((await MentiXpStore.load()).days.length, 3);
    expect(await DailyMentiStore.load(day), containsPair('mood', null));
  });

  test('UTC instants and equivalent local instants use the same day', () async {
    // Run in CI under UTC and Europe/Budapest, including the DST transition.
    if (Platform.environment['TZ'] == 'Europe/Budapest') {
      expect(MentiXpStore.dayKey(DateTime.utc(2026, 10, 24, 22, 30).toLocal()),
        '2026-10-25');
      expect(DateTime.utc(2026, 10, 25, 0, 30).toLocal().hour, 2);
      expect(DateTime.utc(2026, 10, 25, 1, 30).toLocal().hour, 2);
    }
    for (final instant in [DateTime.utc(2026, 10, 24, 22, 30),
        DateTime.utc(2026, 10, 25, 0, 30), DateTime.utc(2026, 10, 25, 1, 30)]) {
      final local = instant.toLocal();
      expect(DailyMentiStore.key(instant), DailyMentiStore.key(local));
      final first = await MentiXpStore.checkInToday(now: instant);
      final second = await MentiXpStore.checkInToday(now: local);
      expect(second.xp, first.xp);
      expect(second.checkedOn(local), isTrue);
    }
  });

  test('Skipping every answer still permits an explicit check-in', () async {
    expect((await save(day)).xp, 10);
    final data = await DailyMentiStore.load(day);
    expect(data['mood'], isNull);
    expect(data['energy'], isNull);
    expect(data['goal'], '');
  });

  test('Legacy XP, journal, wellbeing and profile values are preserved', () async {
    final old = <String, Object>{
      'mennyiment_drinks_v1': '[{"legacy":"untouched"}]',
      'mennyiment_wellbeing_v1': '[{"day":"2026-10-30","mood":2}]',
      'mennyiment_character_style_v2': 'Lány Menti',
      'mennyiment_outfit_v2': 'Legendás szett',
      'mennyiment_character_name_v1': 'Régi Menti',
      'mennyiment_menti_progress_v1': '{"xp":350}',
      'mennyiment_reflection_days_v1': ['2026-10-31'],
    };
    SharedPreferences.setMockInitialValues(old);
    expect((await save(day)).xp, 350);
    final prefs = await SharedPreferences.getInstance();
    for (final key in old.keys.where((k) => !k.contains('reflection_days'))) {
      expect(prefs.get(key), old[key]);
    }
    expect(prefs.getStringList('mennyiment_reflection_days_v1'), ['2026-10-31']);
  });

  test('Unknown daily fields survive and other days remain byte-for-byte intact', () async {
    final previous = DailyMentiStore.key(day.subtract(const Duration(days: 1)));
    SharedPreferences.setMockInitialValues({
      previous: '{"future": true}',
      DailyMentiStore.key(day): '{"future":{"keep":42},"mood":4}',
    });
    await save(day, mood: 3);
    expect((await DailyMentiStore.load(day))['future'], {'keep': 42});
    expect((await SharedPreferences.getInstance()).getString(previous), '{"future": true}');
  });

  test('Malformed daily records are protected from overwrite and XP', () async {
    for (final raw in ['broken', '[]', '{"mood":9}', '{"energy":"3"}']) {
      SharedPreferences.setMockInitialValues({DailyMentiStore.key(day): raw});
      await expectLater(save(day), throwsFormatException);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.get(DailyMentiStore.key(day)), raw);
      expect(prefs.get(xpKey), isNull);
    }
  });

  for (final failedKey in [DailyMentiStore.key(day), xpKey]) {
    test('Failed $failedKey writes allow safe retry without duplicate XP', () async {
      final original = SharedPreferencesStorePlatform.instance;
      addTearDown(() => SharedPreferencesStorePlatform.instance = original);
      // Initialize the XP document before injecting a write failure.
      await MentiXpStore.load();
      final prefs = await SharedPreferences.getInstance();
      final initial = {for (final k in prefs.getKeys()) 'flutter.$k': prefs.get(k)!};
      SharedPreferencesStorePlatform.instance = _FailedWrites(initial, failedKey);
      await expectLater(save(day, mood: 2), throwsStateError);
      await prefs.reload();
      expect((jsonDecode(prefs.getString(xpKey)!) as Map)['xp'], 0);
      if (failedKey == xpKey) {
        expect((await DailyMentiStore.load(day))['mood'], 2);
      }
      SharedPreferencesStorePlatform.instance = InMemorySharedPreferencesStore.withData({
        for (final k in prefs.getKeys()) 'flutter.$k': prefs.get(k)!,
      });
      expect((await save(day, mood: 2)).xp, 10);
      expect((await save(day, mood: 2)).xp, 10);
    });
  }

  Future<void> open(WidgetTester tester, {String locale = 'hu',
      DateTime Function()? clock}) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      locale: Locale(locale),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: MentiMotionScope(child: DailyMentiPage(
        characterName: 'Régi Menti',
        assetPath: 'assets/images/menti_open.png',
        clock: clock ?? () => day,
      )),
    ));
    await tester.pumpAndSettle();
  }

  for (final locale in ['hu', 'en']) {
    testWidgets('$locale: optional answers, profile image, feedback and reduced motion', (tester) async {
      SharedPreferences.setMockInitialValues({MentiMotionSettings.preferenceKey: true});
      await open(tester, locale: locale);
      expect(find.textContaining('Régi Menti'), findsOneWidget);
      expect((tester.widget<Image>(find.byType(Image)).image as AssetImage).assetName,
        'assets/images/menti_open.png');
      await tester.tap(find.byKey(const ValueKey('mood-1')));
      await tester.pumpAndSettle();
      expect(find.textContaining(locale == 'hu' ? 'Ma nehezebbnek' : 'Does today feel'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('mood-skip')));
      await tester.tap(find.byKey(const ValueKey('energy-5')));
      await tester.tap(find.byKey(const ValueKey('energy-skip')));
      await tester.ensureVisible(find.byKey(const ValueKey('daily-save')));
      await tester.tap(find.byKey(const ValueKey('daily-save')));
      await tester.pumpAndSettle();
      expect((await MentiXpStore.load()).xp, 10);
      expect((await DailyMentiStore.load(day))['mood'], isNull);
      expect(tester.hasRunningAnimations, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }

  testWidgets('Leaving without saving writes no answers and awards no XP', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) =>
      TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => DailyMentiPage(characterName: 'Menti',
          assetPath: 'assets/images/menti_open.png', clock: () => day),
      )), child: const Text('Open')),
    )));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Most kihagyom'));
    await tester.tap(find.text('Most kihagyom'));
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
    expect((await MentiXpStore.load()).xp, 0);
    expect((await SharedPreferences.getInstance()).get(DailyMentiStore.key(day)), isNull);
  });

  testWidgets('A page left open over midnight loads the new local day before saving', (tester) async {
    var now = DateTime(2026, 10, 31, 23, 59);
    await save(now, mood: 4);
    await open(tester, clock: () => now);
    now = DateTime(2026, 11, 1, 0, 1);
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    expect(tester.widget<ChoiceChip>(find.byKey(const ValueKey('mood-4'))).selected, isFalse);
    await tester.ensureVisible(find.byKey(const ValueKey('daily-save')));
    await tester.tap(find.byKey(const ValueKey('daily-save')));
    await tester.pumpAndSettle();
    expect((await MentiXpStore.load()).xp, 20);
    expect((await DailyMentiStore.load(day))['mood'], 4);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
