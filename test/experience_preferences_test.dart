import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:mennyiment/data_backup.dart';
import 'package:mennyiment/data_restore.dart';
import 'package:mennyiment/menti_experience_settings.dart';

import 'personal_hub_fixtures.dart';

class _ExperienceFaults extends InMemorySharedPreferencesStore {
  _ExperienceFaults(super.data, {this.throwing = false, this.persist = false}) : super.withData();
  final bool throwing;
  final bool persist;
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (key == 'flutter.${MentiExperienceSettings.reactionsKey}' ||
        key == 'flutter.${MentiExperienceSettings.introKey}') {
      if (persist) await super.setValue(type, key, value);
      if (throwing) throw StateError('Injected presentation preference failure');
      return false;
    }
    return super.setValue(type, key, value);
  }
}

Map<String, Object?> experienceSnapshot(SharedPreferences prefs) => {
  for (final key in prefs.getKeys()) key:
    prefs.get(key) is List ? List.of(prefs.get(key) as List) : prefs.get(key),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('Defaults are read without writes; existing and unknown app data suppress first-run invite', () async {
    var prefs = await SharedPreferences.getInstance();
    expect(MentiExperienceSettings.shouldOfferIntro(prefs), true);
    final settings = MentiExperienceSettings();
    await settings.load();
    expect(settings.ready, true);
    expect(settings.reactions, true);
    expect(settings.introSeen, false);
    expect(experienceSnapshot(prefs), isEmpty);
    settings.dispose();
    for (final values in [
      {'mennyiment_future_data': 'do not inspect'},
      {'mennyiment_menti_xp_v2': '{broken'},
      {MentiExperienceSettings.introKey: true},
      {MentiExperienceSettings.introKey: 'future-format'},
    ]) {
      SharedPreferences.setMockInitialValues(values);
      prefs = await SharedPreferences.getInstance();
      expect(MentiExperienceSettings.shouldOfferIntro(prefs), false);
      expect(experienceSnapshot(prefs), values);
    }
  });
  test('Only explicit choices write flags; unrelated and unknown fields remain exact', () async {
    final initial = hubValues(DateTime(2026, 10, 25));
    SharedPreferences.setMockInitialValues(initial);
    final prefs = await SharedPreferences.getInstance();
    final settings = MentiExperienceSettings();
    await settings.load();
    expect(await settings.setReactions(false), true);
    expect(await settings.markIntroSeen(), true);
    expect(await settings.markIntroSeen(), true);
    expect(experienceSnapshot(prefs), {...initial,
      MentiExperienceSettings.reactionsKey: false, MentiExperienceSettings.introKey: true});
    settings.dispose();
  });
  test('Malformed flags fail closed without overwriting unknown values', () async {
    for (final key in [MentiExperienceSettings.reactionsKey, MentiExperienceSettings.introKey]) {
      SharedPreferences.setMockInitialValues({key: 'unknown', 'mennyiment_menti_xp_v2': 'keep'});
      final settings = MentiExperienceSettings();
      await settings.load();
      expect(settings.ready, false);
      expect(settings.error, 'load');
      expect(await settings.setReactions(false), false);
      expect(await settings.markIntroSeen(), false);
      expect(experienceSnapshot(await SharedPreferences.getInstance()), {key: 'unknown', 'mennyiment_menti_xp_v2': 'keep'});
      settings.dispose();
    }
  });
  test('A stale settings instance cannot overwrite a newer choice', () async {
    final a = MentiExperienceSettings();
    final b = MentiExperienceSettings();
    await a.load();
    await b.load();
    expect(await a.setReactions(false), true);
    expect(await b.setReactions(true), false);
    expect(b.ready, false);
    await b.load();
    expect(b.reactions, false);
    a.dispose();
    b.dispose();
  });
  test('Already-seen intro is rechecked before an idempotent success is reported', () async {
    SharedPreferences.setMockInitialValues({MentiExperienceSettings.introKey: true});
    final settings = MentiExperienceSettings();
    await settings.load();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(MentiExperienceSettings.introKey, false);
    expect(await settings.markIntroSeen(), false);
    expect(settings.ready, false);
    expect(prefs.getBool(MentiExperienceSettings.introKey), false);
    settings.dispose();
  });
  for (final throwing in [false, true]) {
    for (final persist in [false, true]) {
      test('Unconfirmed writes never publish a saved choice (throw=$throwing persist=$persist)', () async {
        final initial = {...hubValues(DateTime(2026, 10, 25)), MentiExperienceSettings.reactionsKey: true};
        SharedPreferences.setMockInitialValues(initial);
        final prefs = await SharedPreferences.getInstance();
        final settings = MentiExperienceSettings();
        await settings.load();
        final platform = SharedPreferencesStorePlatform.instance;
        addTearDown(() => SharedPreferencesStorePlatform.instance = platform);
        SharedPreferencesStorePlatform.instance = _ExperienceFaults({
          for (final k in prefs.getKeys()) 'flutter.$k': prefs.get(k)!,
        }, throwing: throwing, persist: persist);
        expect(await settings.setReactions(false), false);
        expect(settings.reactions, true);
        expect(settings.saving, false);
        expect(settings.error, 'save');
        if (persist) {
          expect(await settings.setReactions(true), false);
          expect(settings.ready, false);
          await settings.load();
          expect(settings.reactions, false);
        } else {
          expect(experienceSnapshot(prefs), initial);
        }
        settings.dispose();
      });
    }
  }
  test('Restoring an older backup keeps local presentation choices absent from the file', () async {
    final initial = hubValues(DateTime(2026, 10, 25));
    SharedPreferences.setMockInitialValues(initial);
    final backup = (await BackupExporter().capture()).json;
    SharedPreferences.setMockInitialValues({...initial,
      MentiExperienceSettings.reactionsKey: false, MentiExperienceSettings.introKey: true});
    final restore = BackupRestorer();
    await restore.restore(await restore.prepare(backup), confirmed: true);
    final settings = MentiExperienceSettings();
    await settings.load();
    expect(settings.reactions, false);
    expect(settings.introSeen, true);
    // Existing restore unions/sorts permanent unlock IDs; their exact set survives.
    expect(experienceSnapshot(await SharedPreferences.getInstance()), {...initial,
      'mennyiment_menti_rewards_v1': (List<String>.from(initial['mennyiment_menti_rewards_v1'] as List)..sort()),
      MentiExperienceSettings.reactionsKey: false, MentiExperienceSettings.introKey: true});
    settings.dispose();
  });
  test('Presentation flags participate in existing backup/restore without a schema migration', () async {
    final initial = {...hubValues(DateTime(2026, 10, 25)),
      MentiExperienceSettings.reactionsKey: false, MentiExperienceSettings.introKey: true,
      'mennyiment_future_presentation': <String>['unknown', 'keep']};
    SharedPreferences.setMockInitialValues(initial);
    final backup = (await BackupExporter().capture()).json;
    SharedPreferences.setMockInitialValues({'foreign': true});
    final restore = BackupRestorer();
    await restore.restore(await restore.prepare(backup), confirmed: true);
    final settings = MentiExperienceSettings();
    await settings.load();
    expect(settings.reactions, false);
    expect(settings.introSeen, true);
    expect(experienceSnapshot(await SharedPreferences.getInstance()), initial);
    settings.dispose();
  });
}
