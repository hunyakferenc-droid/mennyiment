import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:mennyiment/menti_adventure_store.dart';
import 'package:mennyiment/menti_access.dart';
import 'package:mennyiment/data_backup.dart';
import 'package:mennyiment/data_restore.dart';

class FaultStorage extends InMemorySharedPreferencesStore {
  FaultStorage(
    super.data, {
    this.throwing = false,
    this.persist = false,
    this.gate,
    this.replaceAfterWrite = false,
  }) : super.withData();
  final bool throwing, persist, replaceAfterWrite;
  final Completer<void>? gate;
  int writes = 0;
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (key != 'flutter.${AdventureStore.key}') {
      return super.setValue(type, key, value);
    }
    writes++;
    await gate?.future;
    if (persist) await super.setValue(type, key, value);
    if (replaceAfterWrite) {
      await super.setValue(type, key, '{"version":2,"future":"external"}');
      return true;
    }
    if (throwing) throw StateError('Injected write failure');
    return gate != null;
  }
}

const adult = '{"version":1,"audience":"adult","complete":true}';
const sentinels = {
  'mennyiment_drinks_v1': '[{"future":"raw"}]',
  'mennyiment_menti_xp_v2': '{"xp":150,"days":[],"completed":[]}',
  'mennyiment_identity_v22': '{"future":"profile"}',
  'mennyiment_menti_rewards_v1': <String>['outfit-business'],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DateTime now;
  late AdventureStore store;
  setUp(() {
    now = DateTime(2026, 11, 12, 10);
    SharedPreferences.setMockInitialValues({
      ...sentinels,
      MentiAccessSettings.key: adult,
    });
    store = AdventureStore(clock: () => now);
  });
  Future<void> finish(AdventureTask task, {String? note}) async {
    expect(await store.select(now, task), isNotNull);
    expect((await store.complete(now, task, note: note))?.completed, true);
  }

  Future<FaultStorage> inject({
    bool throwing = false,
    bool persist = false,
    Completer<void>? gate,
    bool replaceAfterWrite = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final original = SharedPreferencesStorePlatform.instance;
    addTearDown(() => SharedPreferencesStorePlatform.instance = original);
    final platform = FaultStorage(
      {for (final k in prefs.getKeys()) 'flutter.$k': prefs.get(k)!},
      throwing: throwing,
      persist: persist,
      gate: gate,
      replaceAfterWrite: replaceAfterWrite,
    );
    SharedPreferencesStorePlatform.instance = platform;
    return platform;
  }

  test(
    'Opening an old profile creates no state and does not infer past rewards',
    () async {
      await store.load();
      expect(store.document.completedCount(now), 0);
      expect(store.document.badges, isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(AdventureStore.key), false);
      for (final e in sentinels.entries) {
        expect(prefs.get(e.key), e.value);
      }
    },
  );

  test('Three occupied slots; cancelling frees one, a completed mission keeps its slot', () async {
    await store.load();
    await finish(AdventureTask.movement);
    expect(await store.select(now, AdventureTask.rest), isNotNull);
    expect(await store.select(now, AdventureTask.decision), isNotNull);
    expect(await store.select(now, AdventureTask.wellbeing), isNull);
    expect(store.failure, AdventureFailure.capacity);
    expect(await store.cancel(now, AdventureTask.rest), isNotNull);
    expect(store.document.status(now, AdventureTask.rest), 'cancelled');
    expect(await store.select(now, AdventureTask.wellbeing), isNotNull);
    expect((await store.cancel(now, AdventureTask.movement))?.completed, false);
    expect(store.document.status(now, AdventureTask.movement), 'completed');
    expect(store.document.occupied(now), 3);
  });

  test('Complete once, repeat, cancel and restart never duplicate progress or badges', () async {
    await store.load();
    await finish(AdventureTask.movement);
    final encoded = store.document.encode();
    final firstDate = store.document.badges['first'];
    now = now.add(const Duration(hours: 1));
    expect(
      (await store.complete(now, AdventureTask.movement))?.completed,
      false,
    );
    await store.cancel(now, AdventureTask.movement);
    await store.select(now, AdventureTask.movement);
    final again = AdventureStore(clock: () => now);
    await again.load();
    expect(
      (await again.complete(now, AdventureTask.movement))?.completed,
      false,
    );
    expect(again.document.encode(), encoded);
    expect(again.document.badges['first'], firstDate);
    expect(again.document.tasks(now)['movement']['reactionConsumed'], true);
  });

  test('Three different actual missions finish station one and grant dated badges once', () async {
    await store.load();
    await finish(AdventureTask.movement);
    await finish(AdventureTask.rest);
    expect(await store.select(now, AdventureTask.decision), isNotNull);
    final result = await store.complete(
      now,
      AdventureTask.decision,
      note: '  A quiet break  ',
    );
    expect(result?.station, true);
    expect(store.document.completedStations(now), 1);
    expect(store.document.badges.keys.toSet(), {'first', 'variety', 'station'});
    expect(
      store.document.badges.values.every((date) => date == now.toUtc()),
      true,
    );
    expect(store.document.tasks(now)['decision']['note'], 'A quiet break');
    final prefs = await SharedPreferences.getInstance();
    for (final e in sentinels.entries) {
      expect(prefs.get(e.key), e.value);
    }
    expect(prefs.get(MentiAccessSettings.key), adult);
  });

  test('All five stations derive from actual completed days, never a stored display counter', () async {
    await store.load();
    for (var i = 0; i < 7; i++) {
      now = DateTime(2026, 11, 12 + i, 10);
      await finish(AdventureTask.movement);
      await finish(AdventureTask.rest);
      await finish(AdventureTask.decision, note: 'Today’s choice');
    }
    expect(store.document.completedCount(now), 21);
    expect(store.document.completedStations(now), 5);
    expect(
      AdventureDocument.decode(store.document.encode()).completedStations(now),
      5,
    );
  });

  for (final day in [
    DateTime(2026, 3, 28, 23, 59),
    DateTime(2026, 10, 24, 23, 59),
    DateTime(2026, 12, 31, 23, 59),
  ]) {
    test('Calendar rollover and skipped days retain history at $day', () async {
      now = day;
      await store.load();
      await finish(AdventureTask.movement);
      await store.select(now, AdventureTask.rest);
      final yesterday = now;
      now = DateTime(now.year, now.month, now.day + 1, 0, 1);
      expect(await store.complete(yesterday, AdventureTask.rest), isNull);
      expect(store.failure, AdventureFailure.dayChanged);
      expect(store.document.occupied(now), 0);
      await finish(AdventureTask.rest);
      now = DateTime(now.year, now.month, now.day + 10);
      await store.load();
      expect(store.document.completedCount(now), 2);
      expect(store.document.status(yesterday, AdventureTask.rest), 'active');
      expect(store.document.badges['first'], yesterday.toUtc());
    });
  }

  test('Budapest DST uses local calendar keys on 23/25 hour days', () {
    final spring = DateTime(2026, 3, 29);
    final fall = DateTime(2026, 10, 25);
    if (spring.timeZoneOffset != const Duration(hours: 1)) {
      // The same suite also runs in UTC; the CI DST job uses Europe/Budapest.
      expect(adventureDay(spring), '2026-03-29');
    } else {
      expect(DateTime(2026, 3, 30).difference(spring).inHours, 23);
      expect(DateTime(2026, 10, 26).difference(fall).inHours, 25);
    }
  });

  test('Evidence is read from the existing wellbeing journal; opening is insufficient', () async {
    await store.load();
    await store.select(now, AdventureTask.wellbeing);
    expect(await store.complete(now, AdventureTask.wellbeing), isNull);
    expect(store.failure, AdventureFailure.evidence);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'mennyiment_wellbeing_v1',
      jsonEncode([
        {
          'day': '2026-11-11T00:00:00.000',
          'mood': 3,
          'sleep': 4,
          'hangover': 0,
        },
      ]),
    );
    expect(await store.complete(now, AdventureTask.wellbeing), isNull);
    final raw = jsonEncode([
      {
        'day': '2026-11-12T00:00:00.000',
        'mood': 3,
        'sleep': 4,
        'hangover': 0,
        'future': 'keep',
      },
    ]);
    await prefs.setString('mennyiment_wellbeing_v1', raw);
    expect(
      (await store.complete(now, AdventureTask.wellbeing))?.completed,
      true,
    );
    expect(prefs.getString('mennyiment_wellbeing_v1'), raw);
  });

  test('A decision needs actual nonempty text and cannot exceed the existing note bound', () async {
    await store.load();
    await store.select(now, AdventureTask.decision);
    for (final note in [null, '', '  ', 'x' * 501]) {
      expect(
        await store.complete(now, AdventureTask.decision, note: note),
        isNull,
      );
      expect(store.document.completedCount(now), 0);
    }
    expect(
      (await store.complete(
        now,
        AdventureTask.decision,
        note: 'x' * 500,
      ))?.completed,
      true,
    );
  });

  for (final access in <Object?>[
    null,
    'bad',
    '{"version":2}',
    '{"version":1,"audience":"minor","complete":true}',
    '{"version":1,"audience":"adult","complete":false}',
  ]) {
    test(
      'General tasks remain available, adult goal task fails closed for $access',
      () async {
        final prefs = await SharedPreferences.getInstance();
        if (access == null) {
          await prefs.remove(MentiAccessSettings.key);
        } else {
          await prefs.setString(MentiAccessSettings.key, access as String);
        }
        await store.load();
        expect(await store.select(now, AdventureTask.goal), isNull);
        expect(store.failure, AdventureFailure.access);
        await finish(AdventureTask.rest);
        expect(prefs.get(MentiAccessSettings.key), access);
      },
    );
  }

  test('Adult goal review is an explicit report and receives no XP', () async {
    await store.load();
    await finish(AdventureTask.goal);
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.get('mennyiment_menti_xp_v2'),
      sentinels['mennyiment_menti_xp_v2'],
    );
    expect(prefs.containsKey('mennyiment_personal_goals_v1'), false);
  });

  for (final raw in <Object>[
    'broken',
    '[]',
    123,
    '{"version":2,"days":{},"badges":{}}',
    '{"version":1,"days":{"2026-02-30":{}},"badges":{}}',
    '{"version":1,"days":{"2026-11-12":{"unknown":{}}},"badges":{}}',
    '{"version":1,"days":{},"badges":{"first":"2026-11-12T00:00:00.000Z"}}',
    '{"version":1,"days":{"2026-11-12":{"rest":{"status":"completed"}}},"badges":{}}',
  ]) {
    test('Corrupt or future state is never overwritten: $raw', () async {
      SharedPreferences.setMockInitialValues({
        ...sentinels,
        AdventureStore.key: raw,
      });
      await expectLater(store.load(), throwsA(anything));
      expect(store.writable, false);
      expect(await store.select(now, AdventureTask.rest), isNull);
      expect(
        (await SharedPreferences.getInstance()).get(AdventureStore.key),
        raw,
      );
    });
  }

  test('Unknown nested fields survive selection and completion; returned snapshots are isolated', () async {
    const raw =
        '{"version":1,"days":{"2026-11-12":{"rest":{"status":"active",'
        '"selectedAt":"2026-11-12T00:00:00.000Z","future":{"keep":[1,null]}}}},'
        '"badges":{},"future":{"do":"not change"}}';
    SharedPreferences.setMockInitialValues({AdventureStore.key: raw});
    await store.load();
    await store.complete(now, AdventureTask.rest);
    final value = store.document.toJson();
    expect(value['future'], {'do': 'not change'});
    expect(value['days']['2026-11-12']['rest']['future'], {
      'keep': [1, null],
    });
    value['days'].clear();
    expect(store.document.completedCount(now), 1);
  });

  test(
    'A stale second store cannot overwrite the first and recovers by reloading',
    () async {
      await store.load();
      final second = AdventureStore(clock: () => now);
      await second.load();
      await store.select(now, AdventureTask.rest);
      expect(await second.select(now, AdventureTask.movement), isNull);
      expect(second.failure, AdventureFailure.stale);
      expect(second.writable, false);
      await second.load();
      expect(await second.select(now, AdventureTask.movement), isNotNull);
      await store.load();
      expect(store.document.occupied(now), 2);
    },
  );

  for (final throwing in [false, true]) {
    for (final persist in [false, true]) {
      test(
        'Unconfirmed write has no optimistic completion: throw=$throwing persist=$persist',
        () async {
          await store.load();
          await store.select(now, AdventureTask.rest);
          final before = store.document.encode();
          await inject(throwing: throwing, persist: persist);
          expect(await store.complete(now, AdventureTask.rest), isNull);
          expect(store.document.encode(), before);
          expect(store.document.badges, isEmpty);
          if (persist) {
            expect(await store.complete(now, AdventureTask.rest), isNull);
            expect(store.failure, AdventureFailure.stale);
            await store.load();
            expect(
              (await store.complete(now, AdventureTask.rest))?.completed,
              false,
            );
            expect(store.document.completedCount(now), 1);
          } else {
            expect(
              (await SharedPreferences.getInstance()).getString(
                AdventureStore.key,
              ),
              before,
            );
          }
        },
      );
    }
  }

  test('Double activation during a deferred write persists once and publishes afterwards', () async {
    await store.load();
    await store.select(now, AdventureTask.rest);
    final gate = Completer<void>();
    final platform = await inject(gate: gate, persist: true);
    final first = store.complete(now, AdventureTask.rest);
    expect(await store.complete(now, AdventureTask.rest), isNull);
    expect(store.document.completedCount(now), 0);
    gate.complete();
    expect((await first)?.completed, true);
    expect(platform.writes, 1);
    expect(store.document.completedCount(now), 1);
  });

  test('A successful platform return with a replaced post-write snapshot is not success', () async {
    await store.load();
    await store.select(now, AdventureTask.rest);
    await inject(replaceAfterWrite: true);
    expect(await store.complete(now, AdventureTask.rest), isNull);
    expect(store.failure, AdventureFailure.stale);
    expect(store.document.completedCount(now), 0);
    expect(
      (await SharedPreferences.getInstance()).getString(AdventureStore.key),
      '{"version":2,"future":"external"}',
    );
  });

  test('Recovery journal blocks writes without altering app data', () async {
    await store.load();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(BackupRestorer.recoveryKey, 'recovery sentinel');
    expect(await store.select(now, AdventureTask.rest), isNull);
    expect(prefs.containsKey(AdventureStore.key), false);
    expect(prefs.getString(BackupRestorer.recoveryKey), 'recovery sentinel');
  });

  test('Export and transactional restore round-trip adventures, raw extras and other profile keys', () async {
    // Use supported existing documents for the restore validator.
    SharedPreferences.setMockInitialValues({
      MentiAccessSettings.key: adult,
      'mennyiment_drinks_v1': '[]',
      'mennyiment_locale_v1': 'en',
    });
    await store.load();
    await finish(AdventureTask.rest);
    final encoded = store.document.encode();
    final backup = await BackupExporter().capture();
    expect(backup.json, contains(AdventureStore.key));
    SharedPreferences.setMockInitialValues({MentiAccessSettings.key: adult});
    final restorer = BackupRestorer();
    final plan = await restorer.prepare(backup.json);
    await restorer.restore(plan, confirmed: true);
    await store.load();
    expect(store.document.encode(), encoded);
    expect(
      (await SharedPreferences.getInstance()).getString('mennyiment_locale_v1'),
      'en',
    );
    final older = jsonDecode(backup.json) as Map;
    (older['entries'] as Map).remove(AdventureStore.key);
    await restorer.restore(
      await restorer.prepare(jsonEncode(older)),
      confirmed: true,
    );
    await store.load();
    expect(store.document.encode(), encoded);
  });

  test(
    'Restore rejects a future adventure document without writing any key',
    () async {
      SharedPreferences.setMockInitialValues({'mennyiment_drinks_v1': '[]'});
      await store.load();
      await finish(AdventureTask.rest);
      final before = (await SharedPreferences.getInstance()).getString(
        AdventureStore.key,
      );
      final backup = jsonDecode((await BackupExporter().capture()).json) as Map;
      backup['entries'][AdventureStore.key]['value'] = '{"version":2}';
      await expectLater(
        BackupRestorer().prepare(jsonEncode(backup)),
        throwsA(anything),
      );
      expect(
        (await SharedPreferences.getInstance()).getString(AdventureStore.key),
        before,
      );
    },
  );

  test('Midnight during asynchronous preferences opening does not file yesterday’s action', () async {
    final gate = Completer<void>();
    var hold = false;
    store = AdventureStore(
      clock: () => now,
      open: () async {
        if (hold) await gate.future;
        return SharedPreferences.getInstance();
      },
    );
    await store.load();
    now = DateTime(2026, 3, 28, 23, 59);
    hold = true;
    final write = store.select(now, AdventureTask.rest);
    now = DateTime(2026, 3, 29);
    gate.complete();
    expect(await write, isNull);
    expect(store.failure, AdventureFailure.dayChanged);
    expect(
      (await SharedPreferences.getInstance()).containsKey(AdventureStore.key),
      false,
    );
  });

  test(
    'Malformed, future and normalized wellbeing dates cannot verify a task',
    () async {
      await store.load();
      await store.select(now, AdventureTask.wellbeing);
      final prefs = await SharedPreferences.getInstance();
      for (final raw in [
        'broken',
        '[{"day":"2026-11-12T00:00:00.000"}]',
        '[{"day":"2026-11-13T00:00:00.000","mood":3,"sleep":3,"hangover":0}]',
        '[{"day":"2026-11-12T00:00:00.000","mood":99,"sleep":3,"hangover":0}]',
      ]) {
        await prefs.setString('mennyiment_wellbeing_v1', raw);
        expect(await store.complete(now, AdventureTask.wellbeing), isNull);
        expect(store.failure, AdventureFailure.evidence);
        expect(prefs.getString('mennyiment_wellbeing_v1'), raw);
      }
      expect(store.document.completedCount(now), 0);
    },
  );

  test(
    'An age-mode change after selection prevents completing an adult goal',
    () async {
      await store.load();
      await store.select(now, AdventureTask.goal);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        MentiAccessSettings.key,
        '{"version":1,"audience":"minor","complete":true}',
      );
      expect(await store.complete(now, AdventureTask.goal), isNull);
      expect(store.failure, AdventureFailure.access);
      expect(store.document.completedCount(now), 0);
      expect(store.document.badges, isEmpty);
    },
  );
}
