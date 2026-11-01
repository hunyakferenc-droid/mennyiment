import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/main.dart';
import 'package:mennyiment/avatar.dart';
import 'package:mennyiment/menti_identity/menti_avatar_renderer.dart';
import 'package:mennyiment/menti_identity/menti_identity.dart';
import 'package:mennyiment/menti_identity/menti_identity_store.dart';
import 'package:mennyiment/menti_character_catalog.dart';
import 'package:mennyiment/menti_character_setup.dart';
import 'package:mennyiment/menti_evolution.dart';
import 'package:mennyiment/menti_profile_storage.dart';
import 'package:mennyiment/menti_xp_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const familyKey = MentiCharacterProfile.styleKey;
  const outfitKey = MentiCharacterProfile.outfitKey;
  Future<void> frames(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
  }

  String asset(WidgetTester tester) =>
      tester.widget<MentiEvolution>(find.byType(MentiEvolution)).assetPath;

  testWidgets(
    'All 18 legacy profiles agree on home and wardrobe, refresh after selection and restart',
    (tester) async {
      tester.view.physicalSize = const Size(1100, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final family in MentiCharacterFamily.values) {
        for (final outfit in MentiOutfit.values) {
          SharedPreferences.setMockInitialValues({
            familyKey: family.label,
            outfitKey: outfit.label,
            MentiCharacterProfile.completedKey: true,
            'mennyiment_menti_xp_v2': jsonEncode({
              'xp': 250,
              'days': [],
              'completed': [],
            }),
          });
          final prefs = await SharedPreferences.getInstance();
          await tester.pumpWidget(const MennyiMentApp());
          await frames(tester);
          MentiAvatarRenderer homeAvatar() => tester.widget<MentiAvatarRenderer>(find.descendant(
            of: find.byType(MentiEvolution), matching: find.byType(MentiAvatarRenderer)).first);
          expect(homeAvatar().profile.visual.value('family'), family.id);
          expect(homeAvatar().profile.visual.value('outfit'), outfit.id);
          await tester.tap(find.text('Saját Menti kiválasztása'));
          await tester.pumpAndSettle();
          final studio = tester.widget<MentiAvatarRenderer>(find.byKey(const ValueKey('studio-live-preview')));
          expect(studio.profile.visual.value('family'), family.id);
          expect(studio.profile.visual.value('outfit'), outfit.id);
          final nextFamily = MentiCharacterFamily.values[(family.index + 1) % 3];
          final nextOutfit = MentiOutfit.values[(outfit.index + 1) % 6];
          final familyOption = find.byKey(ValueKey('option-family-${nextFamily.id}'));
          await tester.ensureVisible(familyOption); await tester.tap(familyOption); await tester.pumpAndSettle();
          final tab = find.byKey(const ValueKey('studio-tab-2'));
          await tester.ensureVisible(tab); await tester.tap(tab); await tester.pumpAndSettle();
          final outfitOption = find.byKey(ValueKey('option-outfit-${nextOutfit.id}'));
          await tester.ensureVisible(outfitOption); await tester.tap(outfitOption); await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('studio-save'))); await tester.pumpAndSettle();
          await tester.tap(find.byType(BackButton)); await tester.pumpAndSettle();
          expect(homeAvatar().profile.visual.value('family'), nextFamily.id);
          expect(homeAvatar().profile.visual.value('outfit'), nextOutfit.id);
          final saved = MentiIdentityDocument.decode(prefs.get(MentiIdentityStore.key));
          expect(saved.profile.visual.value('family'), nextFamily.id);
          expect(saved.profile.visual.value('outfit'), nextOutfit.id);
          expect(prefs.get(familyKey), family.label); // Legacy keys are retained, not overwritten.
          expect(prefs.get(outfitKey), outfit.label);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          // A fresh preference instance and app tree simulate cold reload.
          SharedPreferences.setMockInitialValues({
            for (final k in prefs.getKeys()) k: prefs.get(k)!,
          });
          await tester.pumpWidget(const MennyiMentApp());
          await frames(tester);
          expect(homeAvatar().profile.visual.value('family'), nextFamily.id);
          expect(homeAvatar().profile.visual.value('outfit'), nextOutfit.id);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        }
      }
    },
  );

  testWidgets(
    'All 18 identities remain fixed during idle, tap and reaction animations',
    (tester) async {
      for (final family in MentiCharacterFamily.values) {
        for (final outfit in MentiOutfit.values) {
          final path = family.assetFor(outfit);
          Future<void> show(int reaction) => tester.pumpWidget(
            MaterialApp(
              home: MentiEvolution(
                key: const ValueKey('character'),
                assetPath: path,
                reaction: reaction,
                size: 126,
              ),
            ),
          );
          await show(0);
          await tester.pump(const Duration(seconds: 6));
          expect(asset(tester), path);
          await tester.tap(find.byType(MentiEvolution));
          await tester.pump(const Duration(milliseconds: 400));
          expect(asset(tester), path);
          await show(1);
          await tester.pump(const Duration(milliseconds: 900));
          expect(asset(tester), path);
          final image = tester.widget<Image>(find.byType(Image));
          final provider = image.image as ResizeImage;
          expect((provider.imageProvider as AssetImage).assetName, path);
          expect(provider.width, (126 * tester.view.devicePixelRatio).ceil());
          expect(tester.takeException(), isNull);
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets('Compact home keeps selected PNG and fits its layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      familyKey: 'girl',
      outfitKey: 'party',
      MentiCharacterProfile.completedKey: true,
    });
    await tester.pumpWidget(const MennyiMentApp());
    await frames(tester);
    expect(
      asset(tester),
      MentiCharacterFamily.girl.assetFor(MentiOutfit.party),
    );
    expect(
      tester.widget<MentiEvolution>(find.byType(MentiEvolution)).size,
      100,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  test('Level boundaries and rewards use the existing 50 XP rule', () {
    for (final entry in {0: 1, 49: 1, 50: 2, 99: 2, 100: 3, 250: 6}.entries) {
      final state = MentiXpState(xp: entry.key, days: {}, completed: {});
      expect(state.level, entry.value);
      expect(state.levelXp, entry.key % 50);
      expect(state.progress, (entry.key % 50) / 50);
    }
  });

  testWidgets('Studio reads authoritative XP instead of legacy total', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1100, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final legacy = jsonEncode({'xp': 900});
    SharedPreferences.setMockInitialValues({
      familyKey: 'neutral',
      outfitKey: 'legendary',
      'mennyiment_menti_xp_v2': jsonEncode({
        'xp': 150,
        'days': [],
        'completed': [],
      }),
      'mennyiment_menti_progress_v1': legacy,
    });
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(const MaterialApp(home: AvatarPage()));
    await frames(tester);
    final studio = tester.widget<MentiAvatarRenderer>(find.byKey(const ValueKey('studio-live-preview')));
    expect(studio.profile.visual.value('family'), 'neutral');
    expect(studio.profile.visual.value('outfit'), 'legendary');
    // Level four can pick business/festival, but cannot newly pick level-five legendary variant.
    final outfitTab = find.byKey(const ValueKey('studio-tab-2'));
    await tester.ensureVisible(outfitTab); await tester.tap(outfitTab); await tester.pumpAndSettle();
    final row = find.byKey(const ValueKey('choices-outfit'));
    await tester.drag(row, const Offset(-900, 0)); await tester.pumpAndSettle();
    expect(prefs.getString('mennyiment_menti_progress_v1'), legacy);
    expect(prefs.getString('mennyiment_menti_xp_v2'), contains('150'));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  test(
    'Existing legacy migration and repeated loads retain the legacy total',
    () async {
      final legacy = jsonEncode({'xp': 350, 'completed': []});
      SharedPreferences.setMockInitialValues({
        'mennyiment_menti_progress_v1': legacy,
      });
      final prefs = await SharedPreferences.getInstance();
      expect((await MentiXpStore.load()).xp, 350);
      expect((await MentiXpStore.load()).xp, 350);
      expect(prefs.getString('mennyiment_menti_progress_v1'), legacy);
      expect(MentiProfileStorage.studioBackground(prefs), 0);
    },
  );
}
