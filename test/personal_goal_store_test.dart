import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:mennyiment/personal_goal_store.dart';

class _FaultWrites extends InMemorySharedPreferencesStore {
  _FaultWrites(super.data, {this.throwing = false, this.persistThenFail = false})
      : super.withData();
  final bool throwing;
  final bool persistThenFail;
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (key == 'flutter.${PersonalGoalStore.key}') {
      if (persistThenFail) await super.setValue(type, key, value);
      if (throwing) throw StateError('Injected write failure');
      return false;
    }
    return super.setValue(type, key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Legacy partial document, unknown fields and duplicate historical days survive edits', () async {
    final initial = {'reflectionDays': ['2026-10-24', '2026-10-24', 'historical-unknown'],
      'future': {'nested': [1, true, 'keep']}};
    SharedPreferences.setMockInitialValues({PersonalGoalStore.key: jsonEncode(initial),
      'mennyiment_menti_xp_v2': 'xp sentinel', 'mennyiment_outfit_v2': 'legacy outfit'});
    final store = PersonalGoalStore();
    await store.load();
    expect(store.reflectionGoal, 4);
    expect(await store.update({'weeklyBudget': 0}), true);
    final prefs = await SharedPreferences.getInstance();
    expect(jsonDecode(prefs.getString(PersonalGoalStore.key)!), {...initial, 'weeklyBudget': 0});
    expect(prefs.getString('mennyiment_menti_xp_v2'), 'xp sentinel');
    expect(prefs.getString('mennyiment_outfit_v2'), 'legacy outfit');
    expect(() => store.reflectionDays.add('new'), throwsUnsupportedError);
  });

  test('Missing document is read-only until an explicit update', () async {
    final store = PersonalGoalStore();
    await store.load();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(PersonalGoalStore.key), false);
    expect(store.reflectionGoal, 4);
    expect(await store.update({'reflectionGoal': 3}), true);
    expect(jsonDecode(prefs.getString(PersonalGoalStore.key)!), {'reflectionGoal': 3});
  });

  for (final raw in <Object>['broken', '[]', '{"reflectionGoal":0}',
    '{"reflectionGoal":2.5}', '{"weeklyBudget":-1}', '{"reflectionDays":[42]}', 123]) {
    test('Unreadable data is not rewritten: $raw', () async {
      SharedPreferences.setMockInitialValues({PersonalGoalStore.key: raw});
      final store = PersonalGoalStore();
      await expectLater(store.load(), throwsA(anything));
      expect(store.writable, false);
      expect(await store.update({'reflectionGoal': 4}), false);
      expect((await SharedPreferences.getInstance()).get(PersonalGoalStore.key), raw);
    });
  }

  test('Stale pages cannot overwrite another page and can recover by reloading', () async {
    final a = PersonalGoalStore();
    final b = PersonalGoalStore();
    await a.load();
    await b.load();
    expect(await a.update({'weeklyBudget': 1000}), true);
    expect(await b.update({'reflectionGoal': 2}), false);
    expect(b.writable, false);
    await b.load();
    expect(await b.update({'reflectionGoal': 2}), true);
    await a.load();
    expect(a.weeklyBudget, 1000);
    expect(a.reflectionGoal, 2);
  });

  for (final throwing in [false, true]) {
    for (final persist in [false, true]) {
      test('Unconfirmed write never publishes optimistic state (throw=$throwing, persisted=$persist)', () async {
        const original = '{"reflectionGoal":2,"reflectionDays":[],"future":"keep"}';
        SharedPreferences.setMockInitialValues({PersonalGoalStore.key: original});
        final prefs = await SharedPreferences.getInstance();
        final store = PersonalGoalStore();
        await store.load();
        final platform = SharedPreferencesStorePlatform.instance;
        addTearDown(() => SharedPreferencesStorePlatform.instance = platform);
        SharedPreferencesStorePlatform.instance = _FaultWrites({
          for (final k in prefs.getKeys()) 'flutter.$k': prefs.get(k)!,
        }, throwing: throwing, persistThenFail: persist);
        expect(await store.update({'reflectionDays': ['2026-10-25']}), false);
        expect(store.reflectionDays, isEmpty);
        expect(store.busy, false);
        if (persist) {
          // An ambiguous storage outcome requires a fresh read before any success claim.
          expect(await store.update({'weeklyBudget': 10}), false);
          expect(store.writable, false);
          await store.load();
          expect(store.reflectionDays, ['2026-10-25']);
        } else {
          expect(prefs.getString(PersonalGoalStore.key), original);
          SharedPreferencesStorePlatform.instance = platform;
          expect(await store.update({'reflectionDays': ['2026-10-25']}), true);
        }
      });
    }
  }
}
