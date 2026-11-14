import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:mennyiment/menti_complete_looks.dart';
import 'package:mennyiment/menti_xp_store.dart';
import 'package:mennyiment/menti_access.dart';
import 'package:mennyiment/data_backup.dart';
import 'package:mennyiment/data_restore.dart';

import 'menti_complete_looks_test.dart' show LookFaults, snapshot;

String xp(int amount) =>
    jsonEncode({'xp': amount, 'days': [], 'completed': []});
final legendary = CompleteLook.all.where((l) => l.minXp > 0).toList();
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final amount in [0, 199, 200, 201, 10000]) {
    test(
      'XP $amount unlocks at threshold without spending, only one durable notice',
      () async {
        final rawXp = xp(amount);
        SharedPreferences.setMockInitialValues({
          MentiXpStore.currentKey: rawXp,
        });
        final store = CompleteLookStore();
        await store.load();
        final expected = amount < 200
            ? <String>{}
            : legendary.map((l) => l.id).toSet();
        expect(store.selection.acquired, expected);
        expect(store.selection.announced, expected);
        expect(store.takeNewUnlocks().toSet(), expected);
        expect(store.takeNewUnlocks(), isEmpty);
        expect((await snapshot())[MentiXpStore.currentKey], rawXp);
        await store.load();
        expect(store.takeNewUnlocks(), isEmpty);
        store.dispose();
        final restarted = CompleteLookStore();
        await restarted.load();
        expect(restarted.selection.acquired, expected);
        expect(restarted.takeNewUnlocks(), isEmpty);
        restarted.dispose();
      },
    );
  }
  test('Unknown nested v1 fields and three-sample IDs survive explicit v2 selection', () async {
    for (final id in ['boy-base-v1', 'girl-base-v1', 'neutral-base-v1']) {
      final old = jsonEncode({
        'version': 1,
        'active': true,
        'look': id,
        'future': {
          'ids': [2, 'x'],
          'flag': false,
        },
      });
      SharedPreferences.setMockInitialValues({CompleteLookStore.key: old});
      final store = CompleteLookStore();
      await store.load();
      expect(store.ready, true);
      expect((await snapshot())[CompleteLookStore.key], old);
      expect(store.selection.lookId, id);
      expect(await store.save(store.selection.copyWith(active: false)), true);
      final saved = jsonDecode(
        (await snapshot())[CompleteLookStore.key]! as String,
      );
      expect(saved['version'], 2);
      expect(saved['future'], jsonDecode(old)['future']);
      expect(saved['look'], id);
      store.dispose();
    }
  });
  test(
    'No forged entitlement; acquired and unknown IDs cannot be dropped by UI',
    () async {
      final saved = CompleteLookSelection(
        acquired: {legendary.first.id, 'future-owned'},
        announced: {'future-owned'},
        extras: {
          'custom': [3, null],
        },
      ).encode();
      SharedPreferences.setMockInitialValues({CompleteLookStore.key: saved});
      final store = CompleteLookStore();
      await store.load();
      expect(
        await store.save(
          CompleteLookSelection(
            active: true,
            lookId: legendary.last.id,
            acquired: {legendary.last.id},
          ),
        ),
        false,
      );
      expect(
        await store.save(
          CompleteLookSelection(active: true, lookId: legendary.first.id),
        ),
        true,
      );
      expect(store.selection.acquired, {legendary.first.id, 'future-owned'});
      expect(store.selection.extras, {
        'custom': [3, null],
      });
      expect(store.selection.announced, {'future-owned'});
      store.dispose();
    },
  );
  for (final invalid in [
    '{',
    '{"xp":200.5}',
    '{"xp":-1}',
    '{"xp":200,"days":false}',
    'null',
  ]) {
    test('Invalid XP is preserved, no acquisition: $invalid', () async {
      SharedPreferences.setMockInitialValues({
        MentiXpStore.currentKey: invalid,
      });
      final store = CompleteLookStore();
      await store.load();
      expect(store.ready, true);
      expect(store.xp, isNull);
      expect(store.selection.acquired, isEmpty);
      expect(store.takeNewUnlocks(), isEmpty);
      expect(
        await store.save(
          const CompleteLookSelection(active: true, lookId: 'girl-base-v1'),
        ),
        true,
      );
      expect((await snapshot())[MentiXpStore.currentKey], invalid);
      store.dispose();
    });
  }
  test('Restore lower XP and older choice unions permanent collection and unknown metadata', () async {
    SharedPreferences.setMockInitialValues({
      MentiXpStore.currentKey: xp(20),
      CompleteLookStore.key: const CompleteLookSelection(
        active: true,
        lookId: 'girl-base-v1',
        extras: {'old': 2},
      ).encode(),
    });
    final backup = await BackupExporter().capture();
    final current = CompleteLookSelection(
      active: true,
      lookId: legendary.first.id,
      acquired: {legendary.first.id, 'future'},
      announced: {legendary.first.id},
      extras: {'new': 4},
    ).encode();
    final p = await SharedPreferences.getInstance();
    await p.setString(CompleteLookStore.key, current);
    await p.setString(MentiXpStore.currentKey, xp(200));
    final restorer = BackupRestorer();
    await restorer.restore(
      await restorer.prepare(backup.json),
      confirmed: true,
    );
    final store = CompleteLookStore();
    await store.load();
    expect(store.xp, 20);
    expect(store.selection.lookId, 'girl-base-v1');
    expect(store.selection.acquired, {legendary.first.id, 'future'});
    expect(store.selection.announced, {legendary.first.id});
    expect(store.selection.extras, {'new': 4, 'old': 2});
    expect(store.takeNewUnlocks(), isEmpty);
    expect(
      await store.save(store.selection.copyWith(lookId: legendary.first.id)),
      true,
    );
    store.dispose();
  });
  for (final persist in [false, true]) {
    test(
      'Failed acquisition never announces or publishes success, persisted=$persist',
      () async {
        SharedPreferences.setMockInitialValues({
          MentiXpStore.currentKey: xp(200),
        });
        final platform = SharedPreferencesStorePlatform.instance;
        addTearDown(() => SharedPreferencesStorePlatform.instance = platform);
        SharedPreferencesStorePlatform.instance = LookFaults({
          'flutter.${MentiXpStore.currentKey}': xp(200),
        }, persist: persist);
        final store = CompleteLookStore();
        await store.load();
        expect(store.selection.acquired, isEmpty);
        expect(store.takeNewUnlocks(), isEmpty);
        expect(store.error, 'save');
        store.dispose();
      },
    );
  }
  test('Acquisition checks XP snapshot before writing; external decrease is preserved', () async {
    SharedPreferences.setMockInitialValues({MentiXpStore.currentKey: xp(200)});
    var opens = 0;
    final p = await SharedPreferences.getInstance();
    final store = CompleteLookStore(
      open: () async {
        if (++opens == 2) await p.setString(MentiXpStore.currentKey, xp(199));
        return p;
      },
    );
    await store.load();
    expect(store.ready, false);
    expect(store.error, 'conflict');
    expect(store.takeNewUnlocks(), isEmpty);
    expect((await snapshot())[MentiXpStore.currentKey], xp(199));
    expect((await snapshot()).containsKey(CompleteLookStore.key), false);
    store.dispose();
  });
  test('Incomplete first creation survives partial character save/restart without granting adult access', () async {
    final access = MentiAccessSettings();
    await access.load();
    expect(await access.prepareCreation(), true);
    final p = await SharedPreferences.getInstance();
    await p.setString(
      CompleteLookStore.key,
      const CompleteLookSelection(
        active: true,
        lookId: 'girl-base-v1',
      ).encode(),
    );
    final restart = MentiAccessSettings();
    await restart.load();
    expect(restart.existing, false);
    expect(restart.complete, false);
    expect(restart.adult, false);
    expect(await restart.finish(isAdult: false), true);
    final done = MentiAccessSettings();
    await done.load();
    expect(done.complete, true);
    expect(done.adult, false);
    access.dispose();
    restart.dispose();
    done.dispose();
  });
  test('Simultaneous threshold loads write only once and retain XP', () async {
    SharedPreferences.setMockInitialValues({MentiXpStore.currentKey: xp(200)});
    final platform = SharedPreferencesStorePlatform.instance;
    addTearDown(() => SharedPreferencesStorePlatform.instance = platform);
    final gate = Completer<void>();
    final fault = LookFaults({
      'flutter.${MentiXpStore.currentKey}': xp(200),
    }, gate: gate);
    SharedPreferencesStorePlatform.instance = fault;
    final a = CompleteLookStore(), b = CompleteLookStore();
    final first = a.load();
    while (!a.saving) {
      await Future<void>.delayed(Duration.zero);
    }
    await b.load();
    expect(b.takeNewUnlocks(), isEmpty);
    gate.complete();
    await first;
    await b.load();
    expect(fault.writes, 1);
    expect(
      a.takeNewUnlocks().length + b.takeNewUnlocks().length,
      legendary.length,
    );
    expect(b.selection.acquired, a.selection.acquired);
    expect((await snapshot())[MentiXpStore.currentKey], xp(200));
    a.dispose();
    b.dispose();
  });
}
