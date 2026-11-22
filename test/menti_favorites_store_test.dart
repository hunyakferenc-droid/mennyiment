import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:mennyiment/menti_favorites_store.dart';

class FavoriteBackend extends InMemorySharedPreferencesStore {
  FavoriteBackend(
    super.data, {
    this.gate,
    this.fail = false,
    this.persistOnFailure = false,
  }) : super.withData();
  final Completer<void>? gate;
  final bool fail, persistOnFailure;
  int writes = 0;
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (key == 'flutter.${MentiFavoritesStore.key}') {
      writes++;
      if (gate != null) await gate!.future;
      if (fail) {
        if (persistOnFailure) await super.setValue(type, key, value);
        return false;
      }
    }
    return super.setValue(type, key, value);
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'Historical dynamically typed string lists load without rewriting IDs',
    () async {
      SharedPreferencesStorePlatform.instance = FavoriteBackend({
        'flutter.${MentiFavoritesStore.key}': <dynamic>['old-id', 'future-id'],
      });
      final store = MentiFavoritesStore();
      await store.load();
      expect(store.ready, true);
      expect(store.values, {'old-id', 'future-id'});
      expect(await store.toggle('new-id'), true);
      final p = await SharedPreferences.getInstance();
      expect(p.getStringList(MentiFavoritesStore.key), [
        'old-id',
        'future-id',
        'new-id',
      ]);
    },
  );

  test('Missing favorites are read-only until a confirmed toggle; cold reload and all other data preserved', () async {
    final p = await SharedPreferences.getInstance();
    await p.setString('mennyiment_drinks_v1', 'raw journal');
    await p.setString('mennyiment_menti_xp_v2', 'raw XP');
    final s = MentiFavoritesStore();
    await s.load();
    expect(s.ready, true);
    expect(p.containsKey(MentiFavoritesStore.key), false);
    expect(await s.toggle('Sör_500_5'), true);
    final cold = MentiFavoritesStore();
    await cold.load();
    expect(cold.values, {'Sör_500_5'});
    expect(p.getString('mennyiment_drinks_v1'), 'raw journal');
    expect(p.getString('mennyiment_menti_xp_v2'), 'raw XP');
    expect(await cold.toggle('Sör_500_5'), true);
    expect(p.getStringList(MentiFavoritesStore.key), isEmpty);
  });
  test('Unknown favorite IDs and untouched duplicate raw values survive selected toggle', () async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(MentiFavoritesStore.key, [
      'future',
      'future',
      'old/unknown',
    ]);
    final s = MentiFavoritesStore();
    await s.load();
    expect(await s.toggle('Sör_500_5'), true);
    expect(p.getStringList(MentiFavoritesStore.key), [
      'future',
      'future',
      'old/unknown',
      'Sör_500_5',
    ]);
  });
  test('Unknown historical favorite storage is not overwritten', () async {
    final p = await SharedPreferences.getInstance();
    await p.setString(MentiFavoritesStore.key, 'future schema');
    final s = MentiFavoritesStore();
    await s.load();
    expect(s.ready, false);
    expect(await s.toggle('beer'), false);
    expect(p.getString(MentiFavoritesStore.key), 'future schema');
  });
  test(
    'External snapshot mismatch refuses overwrite; explicit reload recovers',
    () async {
      final p = await SharedPreferences.getInstance();
      final s = MentiFavoritesStore();
      await s.load();
      await p.setStringList(MentiFavoritesStore.key, ['another window']);
      expect(await s.toggle('beer'), false);
      expect(s.ready, false);
      expect(p.getStringList(MentiFavoritesStore.key), ['another window']);
      await s.load();
      expect(await s.toggle('beer'), true);
      expect(p.getStringList(MentiFavoritesStore.key), [
        'another window',
        'beer',
      ]);
    },
  );
  for (final persist in [false, true]) {
    test(
      'False native write never reports success or changes displayed favorites; persisted=$persist',
      () async {
        final io = FavoriteBackend({}, fail: true, persistOnFailure: persist);
        SharedPreferencesStorePlatform.instance = io;
        final s = MentiFavoritesStore();
        await s.load();
        expect(await s.toggle('beer'), false);
        expect(s.values, isEmpty);
        expect(io.writes, 1);
        if (persist) {
          expect(await s.toggle('wine'), false);
          expect(io.writes, 1);
        }
        await s.load();
        expect(s.values, persist ? {'beer'} : isEmpty);
      },
    );
  }
  test(
    'Double tap and another loaded store cannot perform parallel writes',
    () async {
      final gate = Completer<void>();
      final io = FavoriteBackend({}, gate: gate);
      SharedPreferencesStorePlatform.instance = io;
      final a = MentiFavoritesStore(), b = MentiFavoritesStore();
      await a.load();
      await b.load();
      final first = a.toggle('beer');
      expect(await a.toggle('wine'), false);
      expect(await b.toggle('wine'), false);
      gate.complete();
      expect(await first, true);
      expect(io.writes, 1);
      expect(await b.toggle('wine'), false);
      expect(io.writes, 1);
    },
  );
}
