import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:mennyiment/menti_animation_settings.dart';
import 'package:mennyiment/menti_reaction_engine.dart';
import 'package:mennyiment/data_backup.dart';
import 'package:mennyiment/data_restore.dart';
import 'package:mennyiment/menti_xp_store.dart';
import 'package:mennyiment/menti_life_events.dart';
import 'package:mennyiment/menti_access.dart';

class LifePreferenceFault extends InMemorySharedPreferencesStore {
  LifePreferenceFault(
    super.data, {
    this.persist = false,
    this.throwing = false,
    this.gate,
  }) : super.withData();
  final bool persist, throwing;
  final Completer<void>? gate;
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (key == 'flutter.${MentiAnimationSettings.key}') {
      await gate?.future;
      if (gate != null) return super.setValue(type, key, value);
      if (persist) await super.setValue(type, key, value);
      if (throwing) throw StateError('disk error');
      return false;
    }
    return super.setValue(type, key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('Missing animation preference is read-only and does not classify a new user as old', () async {
    final p = await SharedPreferences.getInstance(),
        s = MentiAnimationSettings();
    await s.load();
    expect(s.ready, true);
    expect(p.getKeys(), isEmpty);
    expect(
      await s.save(enabled: false, frequency: MentiAnimationFrequency.low),
      true,
    );
    final access = MentiAccessSettings();
    await access.load();
    expect(access.existing, false);
    expect(access.complete, false);
    access.dispose();
    s.dispose();
  });
  test(
    'Unknown extras survive a confirmed save; every preference reloads',
    () async {
      final raw = jsonEncode({
        'version': 1,
        'enabled': true,
        'frequency': 'normal',
        'future': {
          'a': [1, null],
        },
      });
      SharedPreferences.setMockInitialValues({
        MentiAnimationSettings.key: raw,
        'mennyiment_menti_xp_v2': '{"xp":200,"days":[]}',
      });
      final s = MentiAnimationSettings();
      await s.load();
      for (final f in MentiAnimationFrequency.values) {
        expect(await s.save(enabled: false, frequency: f), true);
        final r = MentiAnimationSettings();
        await r.load();
        expect(r.value.frequency, f);
        expect(r.value.enabled, false);
        expect(r.value.extras, {
          'future': {
            'a': [1, null],
          },
        });
        r.dispose();
      }
      expect(
        (await SharedPreferences.getInstance()).getString(
          'mennyiment_menti_xp_v2',
        ),
        '{"xp":200,"days":[]}',
      );
      s.dispose();
    },
  );
  for (final raw in <Object>[
    false,
    '{',
    '{"version":2,"enabled":true,"frequency":"normal","future":1}',
    '{"version":1,"enabled":true,"frequency":"unknown"}',
    '{"version":1,"version":1,"enabled":true,"frequency":"normal"}',
  ]) {
    test(
      'Unreadable/future settings preserved without automatic overwrite: $raw',
      () async {
        SharedPreferences.setMockInitialValues({
          MentiAnimationSettings.key: raw,
        });
        final s = MentiAnimationSettings();
        await s.load();
        expect(s.ready, false);
        expect(
          await s.save(enabled: true, frequency: MentiAnimationFrequency.low),
          false,
        );
        expect(
          (await SharedPreferences.getInstance()).get(
            MentiAnimationSettings.key,
          ),
          raw,
        );
        s.dispose();
      },
    );
  }
  for (final persist in [false, true]) {
    for (final throwing in [false, true]) {
      test(
        'Unconfirmed settings never appear saved: persist=$persist throw=$throwing',
        () async {
          final s = MentiAnimationSettings();
          await s.load();
          final platform = SharedPreferencesStorePlatform.instance;
          addTearDown(() => SharedPreferencesStorePlatform.instance = platform);
          SharedPreferencesStorePlatform.instance = LifePreferenceFault(
            {},
            persist: persist,
            throwing: throwing,
          );
          expect(
            await s.save(
              enabled: false,
              frequency: MentiAnimationFrequency.low,
            ),
            false,
          );
          expect(s.value.enabled, true);
          expect(s.error, 'save');
          expect(s.saving, false);
          s.dispose();
        },
      );
    }
  }
  test('Snapshot mismatch and overlapping writes do not overwrite a newer preference', () async {
    final a = MentiAnimationSettings(), b = MentiAnimationSettings();
    await a.load();
    await b.load();
    expect(
      await a.save(enabled: false, frequency: MentiAnimationFrequency.low),
      true,
    );
    expect(
      await b.save(enabled: true, frequency: MentiAnimationFrequency.frequent),
      false,
    );
    expect(b.ready, false);
    await b.load();
    expect(b.value.enabled, false);
    a.dispose();
    b.dispose();
  });
  test('Backup roundtrip restores preference; older backup keeps it; future input is rejected before writes', () async {
    final s = MentiAnimationSettings();
    await s.load();
    await s.save(enabled: false, frequency: MentiAnimationFrequency.low);
    final backup = await BackupExporter().capture();
    final root = jsonDecode(backup.json) as Map<String, dynamic>;
    final older = {...root, 'entries': <String, dynamic>{}};
    final p = await SharedPreferences.getInstance();
    await p.setString(
      MentiAnimationSettings.key,
      const MentiAnimationPreference().encode(),
    );
    final restorer = BackupRestorer();
    await restorer.restore(
      await restorer.prepare(backup.json),
      confirmed: true,
    );
    await s.load();
    expect(s.value.enabled, false);
    expect(s.value.frequency, MentiAnimationFrequency.low);
    final saved = p.getString(MentiAnimationSettings.key);
    await restorer.restore(
      await restorer.prepare(jsonEncode(older)),
      confirmed: true,
    );
    expect(p.getString(MentiAnimationSettings.key), saved);
    final invalid = jsonDecode(backup.json) as Map<String, dynamic>;
    invalid['entries'][MentiAnimationSettings.key]['value'] =
        '{"version":99,"enabled":true,"frequency":"normal"}';
    await expectLater(
      restorer.prepare(jsonEncode(invalid)),
      throwsFormatException,
    );
    expect(p.getString(MentiAnimationSettings.key), saved);
    s.dispose();
  });
  test('Confirmed XP milestone emits once; reopening does not replay or award new XP', () async {
    SharedPreferences.setMockInitialValues({
      MentiXpStore.currentKey: '{"xp":190,"days":[],"completed":[],"future":7}',
    });
    final signals = <MentiLifeSignal>[];
    void capture() {
      signals.add(MentiLifeEvents.instance.last!);
    }

    MentiLifeEvents.instance.addListener(capture);
    addTearDown(() => MentiLifeEvents.instance.removeListener(capture));
    final now = DateTime(2026, 11, 14);
    expect((await MentiXpStore.checkInToday(now: now)).xp, 200);
    expect(
      signals.where((e) => e.event == MentiLifeEvent.xpMilestone).length,
      1,
    );
    expect((await MentiXpStore.checkInToday(now: now)).xp, 200);
    await MentiXpStore.load();
    expect(signals.length, 1);
    expect(
      jsonDecode(
        (await SharedPreferences.getInstance()).getString(
          MentiXpStore.currentKey,
        )!,
      )['future'],
      7,
    );
  });
}
