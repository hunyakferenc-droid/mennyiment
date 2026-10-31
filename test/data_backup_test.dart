import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Platform fault injection, as in the journal regression tests.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/types.dart';
import 'package:mennyiment/data_backup.dart';

class _ChangingStore extends InMemorySharedPreferencesStore {
  _ChangingStore() : super.withData({});
  int reads = 0;
  int writes = 0;
  @override
  Future<Map<String, Object>> getAllWithParameters(
    GetAllParameters parameters,
  ) async => {'flutter.mennyiment_changed': ++reads};
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    writes++;
    return super.setValue(type, key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  final time = DateTime.utc(2026, 10, 31, 12, 34, 56);
  Future<BackupDocument> capture() =>
      BackupExporter(clock: () => time).capture();
  Map<String, dynamic> root(BackupDocument doc) =>
      jsonDecode(doc.json) as Map<String, dynamic>;

  test('Every supported preference type is preserved without writes or normalization', () async {
    const broken = '  [{"unreadable":true}  '; // Deliberately not repaired.
    final original = <String, Object>{
      'mennyiment_drinks_v1': broken,
      'mennyiment_character_style_v2': 'Lány Menti',
      'mennyiment_outfit_v2': 'Legendás szett',
      'mennyiment_menti_xp_v2': '{ "xp": 123, "unknown": 1 }',
      'mennyiment_reduce_motion_v1': true,
      'mennyiment_locale_v1': 'en',
      'mennyiment_count': 9007199254740993,
      'mennyiment_ratio': -0.0,
      'mennyiment_favorites_v1': <String>['ő', '🍹', 'duplicate', 'duplicate'],
      'foreign_setting': 'do not export',
    };
    SharedPreferences.setMockInitialValues(original);
    final prefs = await SharedPreferences.getInstance();
    final doc = await capture();
    final entries = root(doc)['entries'] as Map;
    expect(doc.createdAt, time);
    expect(doc.entryCount, original.length - 1);
    expect(entries['mennyiment_drinks_v1'], {
      'type': 'string',
      'value': broken,
    });
    expect(entries['mennyiment_count'], {
      'type': 'int',
      'value': '9007199254740993',
    });
    expect(entries['mennyiment_ratio'], {'type': 'double', 'value': '-0.0'});
    expect(entries['mennyiment_reduce_motion_v1'], {
      'type': 'bool',
      'value': true,
    });
    expect(entries['mennyiment_favorites_v1'], {
      'type': 'stringList',
      'value': original['mennyiment_favorites_v1'],
    });
    expect(entries.containsKey('foreign_setting'), false);
    expect({for (final key in prefs.getKeys()) key: prefs.get(key)}, original);
    expect(BackupDocument.decode(utf8.decode(doc.bytes)).json, doc.json);
    expect(doc.fileName, 'mennyiment-backup-20261031T123456000Z.json');
  });

  test(
    'All current source keys and unknown future app keys are covered',
    () async {
      final keys = <String>{};
      for (final file in Directory(
        'lib',
      ).listSync().whereType<File>().where((f) => f.path.endsWith('.dart'))) {
        keys.addAll(
          RegExp(r'''['"](mennyiment_[a-z0-9_]+)['"]''')
              .allMatches(file.readAsStringSync())
              .map((m) => m[1]!),
        );
      }
      expect(keys.length, greaterThanOrEqualTo(31));
      keys.add('mennyiment_future_data');
      SharedPreferences.setMockInitialValues({
        for (final key in keys) key: 'raw $key',
      });
      final doc = await capture();
      expect((root(doc)['entries'] as Map).keys.toSet(), keys);
    },
  );

  test(
    'Empty store produces a valid empty backup without creating defaults',
    () async {
      final doc = await capture();
      expect(doc.entryCount, 0);
      expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
    },
  );
  for (final value in <Object>[2, 'Semleges Menti']) {
    test(
      'Colliding historic style value $value retains its exact type',
      () async {
        SharedPreferences.setMockInitialValues({
          'mennyiment_menti_style_v1': value,
        });
        final entry =
            (root(await capture())['entries']
                as Map)['mennyiment_menti_style_v1'];
        expect(
          entry,
          value is int
              ? {'type': 'int', 'value': '2'}
              : {'type': 'string', 'value': value},
        );
      },
    );
  }
  test(
    'Repeated export is deterministic for unchanged data and clock',
    () async {
      SharedPreferences.setMockInitialValues({
        'mennyiment_z': 3,
        'mennyiment_a': 'ő',
      });
      expect((await capture()).json, (await capture()).json);
    },
  );
  test(
    'Concurrent changes abort export rather than silently mixing snapshots',
    () async {
      await SharedPreferences.getInstance();
      final original = SharedPreferencesStorePlatform.instance;
      addTearDown(() => SharedPreferencesStorePlatform.instance = original);
      final store = _ChangingStore();
      SharedPreferencesStorePlatform.instance = store;
      await expectLater(capture(), throwsStateError);
      expect(store.writes, 0);
    },
  );
  test('Unreadable preferences fail without creating an export', () async {
    await expectLater(
      BackupExporter(openPreferences: () => throw StateError('unreadable'))
          .capture(),
      throwsStateError,
    );
  });
  test('Non-finite local double is rejected without removing it', () async {
    SharedPreferences.setMockInitialValues({'mennyiment_unknown': double.nan});
    await expectLater(capture(), throwsFormatException);
    expect(
      (await SharedPreferences.getInstance())
          .getDouble('mennyiment_unknown')!
          .isNaN,
      true,
    );
  });

  final invalidEntries = <Object?>[
    null,
    [],
    {'type': 'unknown', 'value': 'x'},
    {'type': 'bool', 'value': 'true'},
    {'type': 'string', 'value': 1},
    {'type': 'int', 'value': '01'},
    {'type': 'int', 'value': 1},
    {'type': 'double', 'value': 'NaN'},
    {'type': 'double', 'value': 'Infinity'},
    {
      'type': 'stringList',
      'value': [1],
    },
    {'type': 'string', 'value': 'x', 'extra': true},
  ];
  for (var i = 0; i < invalidEntries.length; i++) {
    test('Malformed typed entry $i is rejected', () async {
      final data = root(await capture());
      data['entries'] = {'mennyiment_bad': invalidEntries[i]};
      expect(
        () => BackupDocument.decode(jsonEncode(data)),
        throwsFormatException,
      );
    });
  }
  for (final change in <Map<String, Object?>>[
    {'version': 2},
    {'version': '1'},
    {'format': 'other'},
    {'entries': []},
    {'createdAt': '2026-02-31T00:00:00.000Z'},
    {'extra': true},
    {
      'entries': {
        'foreign_key': {'type': 'string', 'value': 'no'},
      },
    },
    {
      'entries': {
        'mennyiment_': {'type': 'string', 'value': 'no'},
      },
    },
  ]) {
    test('Unsupported or malformed envelope $change is rejected', () async {
      final data = root(await capture())..addAll(change);
      expect(
        () => BackupDocument.decode(jsonEncode(data)),
        throwsFormatException,
      );
    });
  }
  test('Truncated JSON is rejected', () {
    expect(() => BackupDocument.decode('{'), throwsFormatException);
  });
  test('Oversized input is rejected before parsing', () {
    expect(
      () => BackupDocument.decode(' ' * (BackupDocument.maxBytes + 1)),
      throwsFormatException,
    );
  });
}
