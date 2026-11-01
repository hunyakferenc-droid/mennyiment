import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/daily_menti_store.dart';
import 'package:mennyiment/data_backup.dart';
import 'package:mennyiment/data_restore.dart';
import 'package:mennyiment/menti_character_catalog.dart';
import 'package:mennyiment/menti_completion.dart';
import 'package:mennyiment/menti_reactions.dart';
import 'package:mennyiment/menti_xp_store.dart';
import 'package:mennyiment/personal_goal_store.dart';
import 'package:mennyiment/personal_hub_data.dart';
import 'package:mennyiment/weekly_challenges.dart';

import 'personal_hub_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 10, 25, 12);
  Map<String, Object?> snapshot(SharedPreferences prefs) => {
    for (final key in prefs.getKeys()) key: prefs.get(key),
  };
  test('Existing models are read without any writes, migrations, XP or unlocks', () async {
    final initial = hubValues(now);
    SharedPreferences.setMockInitialValues(initial);
    final prefs = await SharedPreferences.getInstance();
    final before = snapshot(prefs);
    final hub = await PersonalHubReader().load(() => now);
    expect(hub.xp.value!.state.xp, 150);
    expect(hub.xp.value!.state.level, 4);
    expect(hub.xp.value!.state.remainingXp, 50);
    expect(hub.dailyAnswersRecorded, true);
    expect(hub.personalCount, 1);
    expect(hub.personalTarget, 2);
    expect(hub.personalCompleted, false);
    expect(hub.budget, 0);
    expect(hub.weeklyDrinks.length, 2);
    expect(hub.knownCost, 0);
    expect(hub.unknownPrices, 1);
    expect(hub.weeklyChallenges.singleWhere((c) => c.id == 'journal').completed, true);
    expect(hub.weeklyChallenges.singleWhere((c) => c.id == 'habit').completed, false);
    expect(snapshot(prefs), before);
    expect(() => hub.weeklyDrinks.clear(), throwsUnsupportedError);
  });
  test('Missing, corrupt and explicitly recorded zero remain different states', () {
    final missing = PersonalHubSnapshot.fromValues({}, now);
    expect(missing.journal.status, HubReadStatus.missing);
    expect(missing.xp.status, HubReadStatus.missing);
    final zero = PersonalHubSnapshot.fromValues({
      'mennyiment_drinks_v1': '[]', MentiXpStore.currentKey: '{"xp":0,"days":[]}',
      PersonalGoalStore.key: '{"reflectionGoal":2,"reflectionDays":[]}',
    }, now);
    expect(zero.journal.status, HubReadStatus.ready);
    expect(zero.weeklyDrinks, isEmpty);
    expect(zero.xp.value!.state.xp, 0);
    expect(zero.personalCount, 0);
    final broken = PersonalHubSnapshot.fromValues({
      ...hubValues(now), 'mennyiment_drinks_v1': '{bad',
      MentiXpStore.currentKey: '{"xp":1.5}', ChallengeStore.key: '{"version":99,"weeks":{}}',
    }, now);
    expect(broken.journal.status, HubReadStatus.error);
    expect(broken.xp.status, HubReadStatus.error);
    expect(broken.challenges.status, HubReadStatus.error);
    expect(broken.goals.status, HubReadStatus.ready);
  });
  test('Invalid historic price is unknown, never silently converted to zero or rewritten', () async {
    final values = hubValues(now);
    final records = jsonDecode(values['mennyiment_drinks_v1'] as String) as List;
    (records[0] as Map)['priceFt'] = -1;
    values['mennyiment_drinks_v1'] = jsonEncode(records);
    SharedPreferences.setMockInitialValues(values);
    final hub = await PersonalHubReader().load(() => now);
    expect(hub.unknownPrices, 2);
    expect(hub.knownCost, 0);
    expect((await SharedPreferences.getInstance()).getString('mennyiment_drinks_v1'), values['mennyiment_drinks_v1']);
  });
  test('Incomplete profile and missing goal evidence are not guessed', () {
    final hub = PersonalHubSnapshot.fromValues({
      'mennyiment_character_style_v2': 'future-style',
      PersonalGoalStore.key: '{"weeklyBudget":0}',
      ChallengeStore.key: hubValues(now)[ChallengeStore.key],
    }, now);
    expect(hub.profile.status, HubReadStatus.error);
    expect(hub.personalTarget, isNull);
    expect(hub.personalCount, isNull);
    expect(hub.weeklyChallenges.singleWhere((c) => c.id == 'journal').count, isNull);
    expect(hub.weeklyChallenges.singleWhere((c) => c.id == 'journal').completed, false);
  });
  test('Daily answers and XP confirmation are independent, partial saves are honest', () {
    final values = hubValues(now)..[MentiXpStore.currentKey] = '{"xp":150,"days":[]}';
    final hub = PersonalHubSnapshot.fromValues(values, now);
    expect(hub.dailyAnswersRecorded, true);
    expect(hub.xp.value!.state.checkedOn(now), false);
    final noAnswer = PersonalHubSnapshot.fromValues({
      ...values, DailyMentiStore.key(now): '{}', MentiXpStore.currentKey: '{"xp":0}',
    }, now);
    expect(noAnswer.dailyAnswersRecorded, false);
    expect(noAnswer.xp.value!.hasDays, false);
  });
  test('All 18 selected family/outfit combinations retain the original asset', () {
    for (final family in MentiCharacterFamily.values) {
      for (final outfit in MentiOutfit.values) {
        final hub = PersonalHubSnapshot.fromValues({
          ...hubValues(now), 'mennyiment_character_style_v2': family.id,
          'mennyiment_outfit_v2': outfit.id,
        }, now);
        expect(hub.profile.value!.asset, family.assetFor(outfit));
      }
    }
  });
  test('Legacy XP remains untouched instead of being migrated by overview reads', () async {
    final initial = {'mennyiment_menti_progress_v1': '{"xp":70}',
      'mennyiment_reflection_days_v1': <String>['2026-10-25']};
    SharedPreferences.setMockInitialValues(initial);
    final hub = await PersonalHubReader().load(() => now);
    expect(hub.xp.status, HubReadStatus.missing);
    expect(snapshot(await SharedPreferences.getInstance()), initial);
  });
  test('Reactions require new evidence, never opening, repeating, target edits or clock-only changes', () {
    final initial = hubValues(now);
    final before = PersonalHubSnapshot.fromValues(initial, now);
    expect(before.reactionSince(null), isNull);
    expect(before.reactionSince(before), isNull);
    final complete = {...initial, PersonalGoalStore.key: jsonEncode({
      'reflectionGoal': 2, 'reflectionDays': ['2026-10-24', '2026-10-25'],
    })};
    final after = PersonalHubSnapshot.fromValues(complete, now);
    expect(after.reactionSince(before), MentiMood.personalGoalCompleted);
    expect(after.reactionSince(after), isNull);
    final lowered = PersonalHubSnapshot.fromValues({...initial,
      PersonalGoalStore.key: '{"reflectionGoal":1,"reflectionDays":["2026-10-24"]}'}, now);
    expect(lowered.reactionSince(before), isNull);
    final monday = PersonalHubSnapshot.fromValues(complete, DateTime(2026, 10, 26, 1));
    expect(monday.reactionSince(before), isNull);
    final future = {...initial, PersonalGoalStore.key:
      '{"reflectionGoal":2,"reflectionDays":["2026-10-24","2026-10-25"]}'};
    final yesterday = PersonalHubSnapshot.fromValues(future, DateTime(2026, 10, 24, 12));
    expect(PersonalHubSnapshot.fromValues(future, now).reactionSince(yesterday), isNull);
  });
  test('A future wellbeing date becoming current by the clock alone is not new evidence', () {
    final values = hubValues(now);
    values[ChallengeStore.key] = jsonEncode({'version': 1, 'weeks': {
      '2026-10-19': {'journal': {'title': '', 'status': 'active', 'goal': 2, 'days': []}},
    }});
    values['mennyiment_wellbeing_v1'] = jsonEncode([
      {'day': '2026-10-24T00:00:00.000'}, {'day': '2026-10-25T00:00:00.000'},
    ]);
    final before = PersonalHubSnapshot.fromValues(values, DateTime(2026, 10, 24, 12));
    final after = PersonalHubSnapshot.fromValues(values, now);
    expect(before.weeklyChallenges.single.count, 1);
    expect(after.weeklyChallenges.single.count, 2);
    expect(after.reactionSince(before), isNull);
  });
  test('Budget and missing prices never create a completion event', () {
    final initial = PersonalHubSnapshot.fromValues(hubValues(now), now);
    final after = PersonalHubSnapshot.fromValues({...hubValues(now),
      PersonalGoalStore.key: '{"weeklyBudget":10000,"reflectionGoal":2,"reflectionDays":["2026-10-24"]}',
      'mennyiment_drinks_v1': '[]'}, now);
    expect(after.reactionSince(initial), isNull);
  });
  test('Backup/restore still round trips hub reads without changing any unknown fields', () async {
    final values = hubValues(now);
    SharedPreferences.setMockInitialValues(values);
    final backup = (await BackupExporter().capture()).json;
    final prefs = await SharedPreferences.getInstance();
    final before = snapshot(prefs);
    await PersonalHubReader().load(() => now);
    expect(snapshot(prefs), before);
    SharedPreferences.setMockInitialValues({'foreign': true});
    final restorer = BackupRestorer();
    await restorer.restore(await restorer.prepare(backup), confirmed: true);
    await PersonalHubReader().load(() => now);
    expect(snapshot(await SharedPreferences.getInstance()), before);
  });
  test('Local DST and ISO year boundaries select calendar weeks and daily keys', () {
    for (final day in [DateTime(2026, 3, 29, 12), now, DateTime(2027, 1, 3, 12)]) {
      final hub = PersonalHubSnapshot.fromValues(hubValues(day), day);
      expect(hub.week.weekday, DateTime.monday);
      expect(hub.end.hour, 0);
      expect(hub.weeklyDrinks.length, 2);
      expect(hub.dailyAnswersRecorded, true);
      if (day.year == 2027) expect(mentiDateKey(hub.week), '2026-12-28');
      if (Platform.environment['TZ'] == 'Europe/Budapest' && day.year == 2026) {
        expect(hub.end.difference(hub.week).inHours, day.month == 3 ? 167 : 169);
      }
    }
    if (Platform.environment['TZ'] == 'Europe/Budapest') {
      final first = DateTime.utc(2026, 10, 25, 0, 30);
      final second = DateTime.utc(2026, 10, 25, 1, 30);
      final values = hubValues(first.toLocal());
      expect(PersonalHubSnapshot.fromValues(values, first).dailyAnswersRecorded, true);
      expect(PersonalHubSnapshot.fromValues(values, second).dailyAnswersRecorded, true);
    }
  });
}
