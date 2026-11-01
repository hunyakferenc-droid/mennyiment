import 'support/adult_access_fixture.dart';
import 'package:mennyiment/menti_identity/menti_reference_rig.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:mennyiment/data_backup.dart';
import 'package:mennyiment/data_restore.dart';
import 'package:mennyiment/daily_menti.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';
import 'package:mennyiment/main.dart';
import 'package:mennyiment/menti_evolution.dart';
import 'package:mennyiment/menti_experience_settings.dart';
import 'package:mennyiment/menti_identity/menti_avatar_renderer.dart';
import 'package:mennyiment/menti_identity/menti_identity.dart';
import 'package:mennyiment/menti_identity/menti_identity_controller.dart';
import 'package:mennyiment/menti_identity/menti_identity_store.dart';
import 'package:mennyiment/menti_motion.dart';
import 'package:mennyiment/menti_progress.dart';
import 'package:mennyiment/menti_reactions.dart';
import 'package:mennyiment/personal_hub.dart';
import 'package:mennyiment/personal_hub_data.dart';

final chosen = MentiIdentityProfile(name: 'Mira', visual: MentiVisualProfile({
  'family': 'girl', 'age': 'veteran', 'outfit': 'creative-alt', 'hair': 'girl-braid',
  'headwear': 'none', 'glasses': 'round-glasses', 'held': 'flower', 'background': 'ocean',
}), reaction: MentiReactionProfile({'style': 'funny'}));
Map<String, Object> saved() => {adultAccessKey: adultAccessValue,
  MentiIdentityStore.key: MentiIdentityDocument(profile: chosen,
    presets: [MentiPreset(id: 'p1', name: 'Kedvenc', profile: chosen, favorite: true)],
    extras: {'future': {'x': true}}).encode(),
  'mennyiment_character_style_v2': 'boy', 'mennyiment_outfit_v2': 'basic',
  'mennyiment_character_name_v1': 'Régi név',
  'mennyiment_menti_xp_v2': '{"xp":150,"days":[],"completed":[]}',
  'mennyiment_locale_v1': 'en',
};
Widget host(Widget child, MentiIdentityController controller) => MaterialApp(
  locale: const Locale('en'), localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MentiIdentityScope(controller: controller,
    child: MentiMotionScope(child: child!)), home: child);
class FailingIdentityPrefs extends InMemorySharedPreferencesStore {
  FailingIdentityPrefs(super.data, {this.persist = false, this.throwing = false}) : super.withData();
  final bool persist;
  final bool throwing;
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (key == 'flutter.${MentiIdentityStore.key}') {
      if (persist) await super.setValue(type, key, value);
      if (throwing) throw StateError('write acknowledgement lost');
      return false;
    }
    return super.setValue(type, key, value);
  }
}
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues(saved()));
  test('hub reads v22 profile without legacy name or outfit overriding it', () {
    final data = PersonalHubSnapshot.fromValues(saved(), DateTime(2026, 11, 1));
    expect(data.profile.status, HubReadStatus.ready);
    expect(data.profile.value!.identity!.visual.value('outfit'), 'creative-alt');
    expect(data.profile.value!.name, 'Mira');
  });
  test('corrupt v22 is a hub error rather than guessed legacy profile', () {
    final data = PersonalHubSnapshot.fromValues({...saved(), MentiIdentityStore.key: '{bad'}, DateTime(2026, 11, 1));
    expect(data.profile.status, HubReadStatus.error);
    expect(data.profile.value, isNull);
  });
  test('restore preview and denied confirmation do not change current identity', () async {
    final text = (await BackupExporter().capture()).json;
    final other = MentiIdentityDocument(profile: MentiIdentityProfile(name: 'Other')).encode();
    final p = await SharedPreferences.getInstance(); await p.setString(MentiIdentityStore.key, other);
    final restorer = BackupRestorer(); final plan = await restorer.prepare(text);
    expect(p.getString(MentiIdentityStore.key), other);
    await expectLater(restorer.restore(plan, confirmed: false), throwsStateError);
    expect(p.getString(MentiIdentityStore.key), other);
  });
  test('confirmed restore keeps identity presets unknown fields XP and legacy values', () async {
    final original = saved(); final text = (await BackupExporter().capture()).json;
    SharedPreferences.setMockInitialValues({adultAccessKey: adultAccessValue,'foreign': 'keep'});
    final restorer = BackupRestorer(); final plan = await restorer.prepare(text);
    await restorer.restore(plan, confirmed: true);
    final p = await SharedPreferences.getInstance(); await p.reload();
    expect(p.getString(MentiIdentityStore.key), original[MentiIdentityStore.key]);
    expect(p.getString('mennyiment_menti_xp_v2'), original['mennyiment_menti_xp_v2']);
    expect(p.getString('mennyiment_outfit_v2'), 'basic');
    final store = MentiIdentityStore(); await store.load();
    expect(store.document.presets.single.favorite, isTrue);
    expect(store.document.toJson()['future'], {'x': true});
  });
  for (final persist in [false, true]) {
    for (final throwing in [false, true]) {
      test('unconfirmed identity write persist=$persist throw=$throwing never reports success', () async {
        await SharedPreferences.getInstance();
        final originalPlatform = SharedPreferencesStorePlatform.instance;
        addTearDown(() => SharedPreferencesStorePlatform.instance = originalPlatform);
        SharedPreferencesStorePlatform.instance = FailingIdentityPrefs({
          for (final e in saved().entries) 'flutter.${e.key}': e.value,
        }, persist: persist, throwing: throwing);
        final c = MentiIdentityController(); addTearDown(c.dispose); await c.load();
        c.rename('Unconfirmed'); expect(await c.save(), isFalse);
        expect(c.profile.name, 'Mira');
        final prefs = await SharedPreferences.getInstance(); await prefs.reload();
        final actual = MentiIdentityDocument.decode(prefs.get(MentiIdentityStore.key));
        expect(actual.profile.name, persist ? 'Unconfirmed' : 'Mira');
        expect(prefs.get('mennyiment_menti_xp_v2'), saved()['mennyiment_menti_xp_v2']);
        if (persist) {
          expect(await c.save(), isFalse);
          expect(c.error, 'conflict');
          await c.load(); expect(c.profile.name, 'Unconfirmed');
        }
      });
    }
  }
  for (final entry in <String, Widget>{
    'daily': DailyMentiPage(characterName: 'Legacy', assetPath: 'assets/images/menti_open.png', clock: () => DateTime(2026,11,1)),
    'hub': PersonalHubPage(clock: () => DateTime(2026,11,1)),
    'progress': const MentiProgressPage(),
    'evolution': const Scaffold(body: MentiEvolution(size: 100)),
    'reaction': const Scaffold(body: MentiReactionCard(mood: MentiMood.weeklyCompleted)),
  }.entries) {
    testWidgets('${entry.key} uses saved layered identity with conflicting old profile', (tester) async {
      tester.view.physicalSize = const Size(1000, 2400); tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
      final c = MentiIdentityController(); addTearDown(c.dispose); await c.load();
      await tester.pumpWidget(host(entry.value, c)); await tester.pumpAndSettle();
      final avatars = tester.widgetList<MentiAvatarRenderer>(find.byType(MentiAvatarRenderer)).toList();
      expect(avatars, isNotEmpty);
      for (final avatar in avatars) {
        expect(avatar.profile.visual.value('family'), 'girl');
        expect(avatar.profile.visual.value('age'), 'veteran');
        expect(avatar.profile.name, 'Mira');
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets('root home shows saved new name and avatar after recovery', (tester) async {
    tester.view.physicalSize = const Size(1000,2400); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MennyiMentApp()); await tester.pumpAndSettle();
    expect(find.textContaining('Mira'), findsWidgets);
    final avatar = tester.widget<MentiAvatarRenderer>(find.byType(MentiAvatarRenderer).first);
    expect(avatar.profile.visual.value('outfit'), 'creative-alt');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('reaction preference removes visual motif while retaining selected identity', (tester) async {
    final c = MentiIdentityController(); addTearDown(c.dispose); await c.load();
    final settings = MentiExperienceSettings(); addTearDown(settings.dispose); await settings.load();
    await settings.setReactions(false);
    await tester.pumpWidget(host(MentiExperienceScope(settings: settings,
      child: MentiReactionRenderer(profile: chosen, mood: 'celebrating')), c));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('assets/images/menti_2_2/reactions/celebrating.svg')), findsNothing);
    expect(find.byWidgetPredicate((w)=>w is MentiReferencePlate && w.rig.family=='girl' && w.rig.age=='veteran'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
