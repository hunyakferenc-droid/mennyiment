import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/menti_access.dart';
import 'package:mennyiment/data_restore.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'fresh installs fail closed until explicit durable age declaration',
    () async {
      SharedPreferences.setMockInitialValues({});
      final s = MentiAccessSettings();
      await s.load();
      expect(s.complete, false);
      expect(s.adult, false);
      expect(s.existing, false);
      expect(await s.finish(isAdult: false), true);
      final loaded = MentiAccessSettings();
      await loaded.load();
      expect(loaded.complete, true);
      expect(loaded.adult, false);
    },
  );
  test('a legacy profile with only appearance keys is never treated as a new profile', () async {
    SharedPreferences.setMockInitialValues({
      'mennyiment_character_name_v1': 'Original',
      'mennyiment_character_style_v2': 'girl',
    });
    final s = MentiAccessSettings();
    await s.load();
    expect(s.existing, true);
    expect(await s.finish(isAdult: false), true);
    expect(
      (await SharedPreferences.getInstance()).getString(
        'mennyiment_character_name_v1',
      ),
      'Original',
    );
  });
  test(
    'adult declaration preserves all existing application records',
    () async {
      final records = <String, Object>{
        'mennyiment_drinks_v1': '[]',
        'mennyiment_identity_v22': 'preserved',
        'mennyiment_menti_xp_v2': '{"xp":41}',
      };
      SharedPreferences.setMockInitialValues(records);
      final s = MentiAccessSettings();
      await s.load();
      expect(s.existing, true);
      expect(await s.finish(isAdult: true), true);
      final p = await SharedPreferences.getInstance();
      for (final entry in records.entries) {
        expect(p.get(entry.key), entry.value);
      }
      final loaded = MentiAccessSettings();
      await loaded.load();
      expect(loaded.adult, true);
    },
  );
  test(
    'malformed and future declarations remain untouched and never authorize',
    () async {
      for (final value in [
        'not json',
        '{"version":2,"audience":"adult","complete":true}',
        3,
      ]) {
        SharedPreferences.setMockInitialValues({
          MentiAccessSettings.key: value,
        });
        final s = MentiAccessSettings();
        await s.load();
        expect(s.adult, false);
        expect(s.writable, false);
        expect(await s.finish(isAdult: true), false);
        expect(
          (await SharedPreferences.getInstance()).get(MentiAccessSettings.key),
          value,
        );
      }
    },
  );
  test('concurrent declaration cannot be silently overwritten', () async {
    SharedPreferences.setMockInitialValues({});
    final a = MentiAccessSettings(), b = MentiAccessSettings();
    await a.load();
    await b.load();
    expect(await a.finish(isAdult: false), true);
    expect(await b.finish(isAdult: true), false);
    expect(b.adult, false);
  });
  test('restore validates declaration shape and retains extension fields', () {
    final raw = jsonEncode({
      'version': 1,
      'audience': 'minor',
      'complete': true,
      'future': {'x': 1},
    });
    validateRestoreValue(MentiAccessSettings.key, raw);
    expect(MentiAccessSettings.decode(raw)['future'], {'x': 1});
    expect(
      () => validateRestoreValue(MentiAccessSettings.key, '{}'),
      throwsFormatException,
    );
  });
}
