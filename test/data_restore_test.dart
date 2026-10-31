import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:mennyiment/data_backup.dart';
import 'package:mennyiment/data_restore.dart';
import 'package:mennyiment/daily_menti_store.dart';
import 'package:mennyiment/menti_xp_store.dart';
import 'package:mennyiment/weekly_challenges.dart';

class FaultStore extends InMemorySharedPreferencesStore {
  FaultStore(super.data) : super.withData();
  int writes = 0;
  Set<int> failAt = {};
  bool throwing = false;
  bool persistThenFail = false;
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    writes++;
    if (failAt.contains(writes)) {
      if (persistThenFail) { await super.setValue(type, key, value); }
      if (throwing) throw StateError('disk failure');
      return false;
    }
    return super.setValue(type, key, value);
  }
  @override
  Future<bool> remove(String key) async {
    writes++;
    if (failAt.contains(writes)) return false;
    return super.remove(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<String> backup(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return (await BackupExporter().capture()).json;
  }
  Future<Map<String, Object?>> snapshot() async {
    final p = await SharedPreferences.getInstance();
    await p.reload();
    return {for (final k in p.getKeys()) k: p.get(k)};
  }
  const dailyKey = 'mennyiment_daily_menti_v1_2026-10-25';
  final source = <String, Object>{
    'mennyiment_drinks_v1': '[{"name":"Víz","ml":250,"percent":0,"time":"2026-10-25T02:30:00.000+02:00","future":true}]',
    dailyKey: '{ "mood":4,"energy":3,"goal":"Séta","evening":"Jó","future":42 }',
    'mennyiment_menti_xp_v2': '{"xp":230,"days":["2026-10-25"],"completed":["2026-10-19:review"],"future":1}',
    'mennyiment_menti_rewards_v1': <String>['outfit:sport', 'future:hat'],
    'mennyiment_weekly_challenges_v1': '{"version":1,"weeks":{"2026-10-19":{"walk":{"goal":3,"days":["2026-10-25"],"title":"Séta","status":"active","future":1}}}}',
    'mennyiment_character_style_v2': 'lany',
    'mennyiment_outfit_v2': 'sport',
    'mennyiment_locale_v1': 'en',
    'mennyiment_reduce_motion_v1': true,
    'mennyiment_future_int': 9007199254740993,
    'mennyiment_future_double': -0.0,
  };
  test('6.8 A/B/C and all preference types round trip without migration or XP awards', () async {
    final text = await backup(source);
    SharedPreferences.setMockInitialValues({'foreign': 'keep', 'mennyiment_newer': 'keep'});
    final service = BackupRestorer();
    final plan = await service.prepare(text);
    expect(plan.added, source.length);
    expect((await snapshot()).length, 2); // Preview never writes.
    await service.restore(plan, confirmed: true);
    expect(await snapshot(), {...source, 'foreign': 'keep', 'mennyiment_newer': 'keep'});
    expect((await MentiXpStore.load()).xp, 230);
    final store = ChallengeStore();
    await store.load();
    expect(store.week(DateTime(2026, 10, 25))['walk']['future'], 1);
    expect((await snapshot())[dailyKey], source[dailyKey]);
  });
  test('older backup keeps all absent 6.8 data and unions permanent unlocks', () async {
    final text = await backup({'mennyiment_locale_v1': 'hu',
      'mennyiment_menti_rewards_v1': <String>['outfit:basic']});
    SharedPreferences.setMockInitialValues(source);
    final service = BackupRestorer();
    final plan = await service.prepare(text);
    await service.restore(plan, confirmed: true);
    final result = await snapshot();
    expect(result[dailyKey], source[dailyKey]);
    expect(result['mennyiment_menti_xp_v2'], source['mennyiment_menti_xp_v2']);
    expect(result['mennyiment_weekly_challenges_v1'], source['mennyiment_weekly_challenges_v1']);
    expect(result['mennyiment_menti_rewards_v1'], ['future:hat', 'outfit:basic', 'outfit:sport']);
  });
  test('duplicate, escaped duplicate and over-nested JSON are rejected', () async {
    for (final text in ['{"a":1,"a":2}', r'{"a":1,"\u0061":2}',
      '${'[' * 129}0${']' * 129}']) {
      expect(() => decodeBackupJson(text), throwsFormatException);
    }
    final text = await backup({'mennyiment_menti_xp_v2': '{"xp":20,"xp":30}'});
    SharedPreferences.setMockInitialValues(source);
    await expectLater(BackupRestorer().prepare(text), throwsFormatException);
    expect(await snapshot(), source);
  });
  test('confirmation is required by the service', () async {
    final text = await backup(source);
    SharedPreferences.setMockInitialValues({});
    final service = BackupRestorer();
    final plan = await service.prepare(text);
    await expectLater(service.restore(plan, confirmed: false), throwsStateError);
    expect(await snapshot(), isEmpty);
  });
  test('stale preview rejects changes, including newly added unrelated app keys', () async {
    final text = await backup(source);
    SharedPreferences.setMockInitialValues({});
    final service = BackupRestorer();
    final plan = await service.prepare(text);
    final p = await SharedPreferences.getInstance();
    await p.setString('mennyiment_concurrent', 'new');
    await expectLater(service.restore(plan, confirmed: true), throwsStateError);
    expect(await snapshot(), {'mennyiment_concurrent': 'new'});
  });
  for (final corrupt in <String, Object>{
    'mennyiment_drinks_v1': '[{"name":"x","ml":1,"percent":0,"time":"2026-02-31T00:00:00"}]',
    dailyKey: '{"mood":9}',
    'mennyiment_menti_xp_v2': '{"xp":"bad"}',
    'mennyiment_weekly_challenges_v1': '{"version":2,"weeks":{}}',
    'mennyiment_menti_rewards_v1': '[]',
    'mennyiment_reduce_motion_v1': 'false',
  }.entries) {
    test('invalid embedded ${corrupt.key} cannot overwrite data', () async {
      final text = await backup({corrupt.key: corrupt.value});
      SharedPreferences.setMockInitialValues(source);
      await expectLater(BackupRestorer().prepare(text), throwsFormatException);
      expect(await snapshot(), source);
    });
  }
  for (final throwing in [false, true]) {
    test('partial write ${throwing ? "exception" : "false"} rolls back exact types and removes new keys', () async {
      final text = await backup({'mennyiment_a_new': true, 'mennyiment_b': <String>['new']});
      SharedPreferences.setMockInitialValues({'mennyiment_b': 42, 'foreign': 'keep'});
      await SharedPreferences.getInstance();
      final original = SharedPreferencesStorePlatform.instance;
      addTearDown(() => SharedPreferencesStorePlatform.instance = original);
      final store = FaultStore({'flutter.mennyiment_b': 42, 'flutter.foreign': 'keep'})
        ..failAt = {3} ..throwing = throwing;
      SharedPreferencesStorePlatform.instance = store;
      final service = BackupRestorer();
      final plan = await service.prepare(text);
      await expectLater(service.restore(plan, confirmed: true), throwsA(isA<RestoreFailure>()
        .having((e) => e.recoveryRequired, 'recovered', false)));
      expect(await snapshot(), {'mennyiment_b': 42, 'foreign': 'keep'});
    });
  }
  test('rollback failure retains durable journal; next startup recovers before editing', () async {
    final text = await backup({'mennyiment_a': 'new', 'mennyiment_b': 'new'});
    SharedPreferences.setMockInitialValues({'mennyiment_a': 'old', 'mennyiment_b': 'old'});
    await SharedPreferences.getInstance();
    final original = SharedPreferencesStorePlatform.instance;
    addTearDown(() => SharedPreferencesStorePlatform.instance = original);
    final store = FaultStore({'flutter.mennyiment_a': 'old', 'flutter.mennyiment_b': 'old'})
      ..failAt = {3, 4};
    SharedPreferencesStorePlatform.instance = store;
    final service = BackupRestorer();
    await expectLater(service.restore(await service.prepare(text), confirmed: true),
      throwsA(isA<RestoreFailure>().having((e) => e.recoveryRequired, 'blocked', true)));
    expect((await snapshot()).containsKey(BackupRestorer.recoveryKey), true);
    await expectLater(service.prepare(text), throwsA(isA<RestoreFailure>()));
    store.failAt = {};
    await BackupRestorer().recover();
    expect(await snapshot(), {'mennyiment_a': 'old', 'mennyiment_b': 'old'});
  });
  test('failure to persist rollback image causes zero user-data writes', () async {
    final text = await backup({'mennyiment_a': 'new'});
    SharedPreferences.setMockInitialValues({'mennyiment_a': 'old'});
    await SharedPreferences.getInstance();
    final original = SharedPreferencesStorePlatform.instance;
    addTearDown(() => SharedPreferencesStorePlatform.instance = original);
    final store = FaultStore({'flutter.mennyiment_a': 'old'})..failAt = {1};
    SharedPreferencesStorePlatform.instance = store;
    final service = BackupRestorer();
    await expectLater(service.restore(await service.prepare(text), confirmed: true), throwsStateError);
    expect(await snapshot(), {'mennyiment_a': 'old'});
    expect(store.writes, 1);
  });
  test('ambiguous pre-image persistence plus failed cleanup blocks editing until recovery', () async {
    final text = await backup({'mennyiment_a': 'new'});
    SharedPreferences.setMockInitialValues({'mennyiment_a': 'old'});
    await SharedPreferences.getInstance();
    final original = SharedPreferencesStorePlatform.instance;
    addTearDown(() => SharedPreferencesStorePlatform.instance = original);
    final store = FaultStore({'flutter.mennyiment_a': 'old'})
      ..persistThenFail = true ..failAt = {1, 2};
    SharedPreferencesStorePlatform.instance = store;
    final service = BackupRestorer();
    await expectLater(service.restore(await service.prepare(text), confirmed: true),
      throwsA(isA<RestoreFailure>().having((e) => e.recoveryRequired, 'blocked', true)));
    expect((await snapshot())['mennyiment_a'], 'old');
    expect((await snapshot()).containsKey(BackupRestorer.recoveryKey), true);
    store.failAt = {};
    await service.recover();
    expect(await snapshot(), {'mennyiment_a': 'old'});
  });
  test('interrupted process recovery removes added keys and preserves foreign preferences', () async {
    final text = await backup({'mennyiment_a': 5});
    SharedPreferences.setMockInitialValues({
      'mennyiment_a': 'partial', 'mennyiment_new': false, 'foreign': 'safe',
      BackupRestorer.recoveryKey: jsonEncode({'backup': text, 'keys': ['mennyiment_a', 'mennyiment_new']}),
    });
    await BackupRestorer().recover();
    expect(await snapshot(), {'mennyiment_a': 5, 'foreign': 'safe'});
  });
  test('Budapest DST repeated hour and midnight keep daily/week keys and timestamps verbatim', () async {
    if (Platform.environment['TZ'] == 'Europe/Budapest') {
      expect(DateTime.utc(2026, 10, 25, 0, 30).toLocal().hour, 2);
      expect(DateTime.utc(2026, 10, 25, 1, 30).toLocal().hour, 2);
      expect(DateTime.utc(2026, 3, 29, 1, 30).toLocal().hour, 3);
      expect(DailyMentiStore.key(DateTime.utc(2026, 10, 24, 22, 30)), dailyKey);
    }
    final text = await backup(source);
    SharedPreferences.setMockInitialValues({});
    final service = BackupRestorer();
    await service.restore(await service.prepare(text), confirmed: true);
    expect(await snapshot(), source);
    expect(challengeDate(challengeMonday(DateTime(2026, 10, 25))), '2026-10-19');
  });
}
