import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/data_backup.dart';
import 'package:mennyiment/menti_character_catalog.dart';
import 'package:mennyiment/menti_identity/menti_identity.dart';
import 'package:mennyiment/menti_identity/menti_identity_store.dart';
import 'package:mennyiment/menti_profile_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final family in MentiCharacterFamily.values) {
    for (final outfit in MentiOutfit.values) {
      test('legacy ${family.id}/${outfit.id}: identity and permanent outfit retained', () {
        final data = MentiIdentityDocument.fromLegacy({
          MentiProfileStorage.characterStyleKey: family.label,
          MentiProfileStorage.outfitKey: outfit.label,
        });
        expect(data.profile.visual.value('family'), family.id);
        expect(data.profile.visual.value('outfit'), outfit.id);
        expect(data.unlocks.unlocked, contains('outfit:${outfit.id}'));
        expect(MentiIdentityDocument.decode(data.encode()).encode(), data.encode());
      });
    }
  }
  for (final item in {'Fiatalos': 'young', 'Felnőttes': 'adult', 'Veterán': 'veteran'}.entries) {
    test('legacy appearance ${item.key} takes precedence over age range', () {
      final data = MentiIdentityDocument.fromLegacy({
        'mennyiment_menti_age_style_v1': item.key, 'mennyiment_age_group_v1': '45+',
      });
      expect(data.profile.visual.value('age'), item.value);
    });
  }
  for (final item in {'18–24': 'young', '25–34': 'young', '35–44': 'adult', '45+': 'veteran'}.entries) {
    test('legacy age range ${item.key}', () {
      final data = MentiIdentityDocument.fromLegacy({'mennyiment_age_group_v1': item.key});
      expect(data.profile.visual.value('age'), item.value);
    });
  }
  for (final item in {0: 'violet', 1: 'forest', 2: 'amber', 3: 'midnight'}.entries) {
    test('legacy integer Studio background ${item.key}', () {
      final data = MentiIdentityDocument.fromLegacy({MentiProfileStorage.legacyStyleKey: item.key});
      expect(data.profile.visual.value('background'), item.value);
      expect(data.profile.visual.value('family'), 'boy');
    });
  }
  for (final item in {'Narancs': 'sunrise', 'Lila': 'violet', 'Kék': 'ocean', 'Zöld': 'forest',
      'Arany': 'starlight', 'Rózsaszín': 'rose'}.entries) {
    test('legacy aura ${item.key}', () {
      final data = MentiIdentityDocument.fromLegacy({'mennyiment_menti_aura_v1': item.key});
      expect(data.profile.visual.value('aura'), item.value);
    });
  }
  test('missing visual fields have safe rendering defaults without writing defaults', () {
    final data = MentiIdentityDocument.decode('{"version":1,"profile":{}}');
    expect(data.profile.visual.value('eyes'), 'round');
    expect(data.profile.toJson(), isEmpty);
  });
  test('unknown identifiers and nested extension fields roundtrip losslessly', () {
    final raw = {'version': 1, 'future': [1, {'secret': 'kept'}],
      'profile': {'name': 'M', 'future': true, 'visual': {'eyes': 'future-eye', 'x': {'v': 2}},
        'reaction': {'style': 'future-style', 'x': [3]}},
      'unlocks': {'unlocked': ['future:reward'], 'seen': [], 'future': 9},
      'presets': [{'id': 'p', 'name': 'P', 'profile': {}, 'favorite': true, 'future': 8}]};
    final data = MentiIdentityDocument.decode(jsonEncode(raw));
    expect(data.profile.visual.value('eyes'), 'future-eye');
    expect(data.toJson(), raw);
  });
  final corrupt = <Object?>[null, 1, true, [], '{}', '[]', '{',
    '{"version":2,"profile":{}}', '{"version":1.0,"profile":{}}',
    '{"version":1,"version":1,"profile":{}}',
    '{"version":1,"profile":{"visual":{"eyes":3}}}',
    '{"version":1,"profile":{"name":""}}',
    '{"version":1,"profile":{"reaction":{"style":false}}}',
    '{"version":1,"profile":{},"unlocks":{"unlocked":[1]}}',
    '{"version":1,"profile":{},"presets":{}}',
    '{"version":1,"profile":{},"presets":[{"id":"p","name":"p"}]}',
    '{"version":1,"profile":{},"presets":[{"id":"p","name":"p","profile":{}},{"id":"p","name":"q","profile":{}}]}',
  ];
  for (var i = 0; i < corrupt.length; i++) {
    test('malformed identity $i is rejected', () {
      expect(() => MentiIdentityDocument.decode(corrupt[i]), throwsFormatException);
    });
  }
  test('unlock union and acknowledgement preserve unknown future rewards', () {
    final state = MentiUnlockState(unlocked: ['future:1']).grant(['outfit:basic']);
    expect(state.newlyAcquired, {'future:1', 'outfit:basic'});
    final seen = state.acknowledge(['outfit:basic', 'unearned']);
    expect(seen.newlyAcquired, {'future:1'});
    expect(seen.seen, {'outfit:basic'});
  });
  test('caller mutation cannot change stored profile or encoded document', () {
    final source = <String, dynamic>{'family': 'girl', 'x': [1]};
    final visual = MentiVisualProfile(source);
    source['family'] = 'boy';
    (source['x'] as List).add(2);
    final copy = visual.toJson();
    (copy['x'] as List).add(3);
    expect(visual.toJson(), {'family': 'girl', 'x': [1]});
  });
  test('preset duplicate has independent id and keeps extension metadata', () {
    final preset = MentiPreset(id: 'p1', name: 'Első', profile: MentiIdentityProfile(),
      favorite: true, extras: {'x': 2});
    final copy = preset.copyWith(id: 'p2', name: 'Második', favorite: false);
    expect(copy.id, 'p2');
    expect(copy.toJson()['x'], 2);
    expect(preset.favorite, isTrue);
  });
  test('migration is read-only, preserves all original prefs and XP bytes', () async {
    final original = <String, Object>{'mennyiment_menti_xp_v2': '{"xp":130}',
      MentiProfileStorage.legacyStyleKey: 'Lány Menti',
      'mennyiment_menti_rewards_v1': <String>['future:reward', 'outfit:festival'],
      'mennyiment_character_name_v1': 'Csillag', 'mennyiment_menti_future': '{"x":1}'};
    SharedPreferences.setMockInitialValues(original);
    final store = MentiIdentityStore();
    await store.load();
    final prefs = await SharedPreferences.getInstance();
    expect({for (final k in prefs.getKeys()) k: prefs.get(k)}, original);
    expect(store.document.profile.name, 'Csillag');
    expect(store.document.profile.visual.value('family'), 'girl');
    expect(store.document.unlocks.unlocked, containsAll(['future:reward', 'outfit:festival']));
    expect(store.migrated, isTrue);
    expect(await store.save(store.document), isTrue);
    expect(prefs.get('mennyiment_menti_xp_v2'), original['mennyiment_menti_xp_v2']);
    expect(store.document.toJson()['migration'], isNotNull);
  });
  test('valid new identity always overrides conflicting legacy selection', () async {
    final data = MentiIdentityDocument(profile: MentiIdentityProfile(
      visual: MentiVisualProfile({'family': 'neutral', 'outfit': 'legendary'})));
    SharedPreferences.setMockInitialValues({MentiIdentityStore.key: data.encode(),
      MentiProfileStorage.characterStyleKey: 'boy'});
    final store = MentiIdentityStore();
    await store.load();
    expect(store.migrated, isFalse);
    expect(store.document.profile.visual.value('family'), 'neutral');
  });
  for (final raw in ['{broken', '{"version":99,"profile":{}}', 42]) {
    test('unreadable stored identity ($raw) blocks save without data loss', () async {
      SharedPreferences.setMockInitialValues({MentiIdentityStore.key: raw});
      final store = MentiIdentityStore();
      await store.load();
      expect(store.writable, isFalse);
      expect(store.error, 'unreadable');
      expect(await store.save(store.document), isFalse);
      expect((await SharedPreferences.getInstance()).get(MentiIdentityStore.key), raw);
    });
  }
  test('stale store cannot overwrite a concurrent edit', () async {
    final first = MentiIdentityStore(), second = MentiIdentityStore();
    await first.load(); await second.load();
    expect(await first.save(first.document.copyWith(profile: MentiIdentityProfile(name: 'First'))), isTrue);
    expect(await second.save(second.document.copyWith(profile: MentiIdentityProfile(name: 'Stale'))), isFalse);
    expect(second.error, 'conflict');
    await second.load();
    expect(second.document.profile.name, 'First');
  });
  test('reset appearance cannot revoke old unlocks or unknown fields', () async {
    final data = MentiIdentityDocument(profile: MentiIdentityProfile(
      visual: MentiVisualProfile({'futureVisual': {'v': 2}}), extras: {'future': 1}),
      unlocks: MentiUnlockState(unlocked: ['outfit:legendary'], extras: {'x': 8}),
      extras: {'futureRoot': 3});
    SharedPreferences.setMockInitialValues({MentiIdentityStore.key: data.encode()});
    final store = MentiIdentityStore();
    await store.load();
    expect(await store.save(MentiIdentityDocument(profile: MentiIdentityProfile())), isTrue);
    expect(store.document.unlocks.unlocked, {'outfit:legendary'});
    expect(store.document.profile.visual.toJson()['futureVisual'], {'v': 2});
    expect(store.document.toJson()['futureRoot'], 3);
  });
  test('backup envelope captures identity and presets exactly without schema changes', () async {
    final data = MentiIdentityDocument(profile: MentiIdentityProfile(name: 'Éva'),
      presets: [MentiPreset(id: 'p1', name: 'Kedvenc', favorite: true, profile: MentiIdentityProfile())],
      extras: {'future': {'x': 9}}).encode();
    SharedPreferences.setMockInitialValues({MentiIdentityStore.key: data});
    final backup = await BackupExporter().capture();
    final entries = (jsonDecode(backup.json) as Map)['entries'] as Map;
    expect(entries[MentiIdentityStore.key], {'type': 'string', 'value': data});
    expect(MentiIdentityDocument.decode((entries[MentiIdentityStore.key] as Map)['value']).presets.single.favorite, isTrue);
  });
  test('XP and reward changes after migration read do not block appearance save', () async {
    SharedPreferences.setMockInitialValues({MentiProfileStorage.legacyStyleKey: 'Lány Menti'});
    final store = MentiIdentityStore(); await store.load();
    final prefs = await SharedPreferences.getInstance();
    await MentiProfileStorage.migrate(prefs);
    await prefs.setString('mennyiment_menti_xp_v2', '{"xp":50}');
    await prefs.setStringList('mennyiment_menti_rewards_v1', ['future:new']);
    expect(await store.save(store.document), isTrue);
    expect(store.document.unlocks.unlocked, contains('future:new'));
    expect(prefs.getString('mennyiment_menti_xp_v2'), '{"xp":50}');
  });
  test('actual legacy appearance edit after load blocks first migration save', () async {
    final store = MentiIdentityStore(); await store.load();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(MentiProfileStorage.characterStyleKey, 'girl');
    expect(await store.save(store.document), isFalse);
    expect(store.error, 'conflict');
    expect(prefs.containsKey(MentiIdentityStore.key), isFalse);
  });

  test('partial preset applies its effective defaults without reviving previous visual values', () async {
    final old = MentiIdentityDocument(profile: MentiIdentityProfile(name: 'Previous',
      visual: MentiVisualProfile({'family': 'girl', 'outfit': 'legendary', 'future': 7})));
    SharedPreferences.setMockInitialValues({MentiIdentityStore.key: old.encode()});
    final store = MentiIdentityStore(); await store.load();
    final partialPreset = MentiIdentityProfile.fromJson(<String, dynamic>{});
    expect(await store.save(store.document.copyWith(profile: partialPreset)), isTrue);
    expect(store.document.profile.name, 'Menti');
    expect(store.document.profile.visual.value('family'), 'boy');
    expect(store.document.profile.visual.value('outfit'), 'basic');
    expect(store.document.profile.visual.toJson()['future'], 7);
  });
  test('missing hair defaults to the selected family without writing a value', () {
    final p = MentiVisualProfile({'family': 'girl'});
    expect(p.value('hair'), 'girl-crop');
    expect(p.toJson().containsKey('hair'), isFalse);
  });

}
