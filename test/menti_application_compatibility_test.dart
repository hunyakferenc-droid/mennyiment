import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/avatar.dart';
import 'package:mennyiment/main.dart';
import 'package:mennyiment/menti_character_catalog.dart';
import 'package:mennyiment/menti_character_setup.dart';
import 'package:mennyiment/menti_evolution.dart';
import 'package:mennyiment/menti_profile_storage.dart';
import 'package:mennyiment/menti_progress.dart';
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

  void largeView(WidgetTester tester) {
    tester.view.physicalSize = const Size(1100, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  for (final family in MentiCharacterFamily.values) {
    testWidgets(
      '${family.id}: home, Studio and XP page accept all outfit IDs without rewriting them',
      (tester) async {
        largeView(tester);
        for (final outfit in MentiOutfit.values) {
          SharedPreferences.setMockInitialValues({
            familyKey: family.id,
            outfitKey: outfit.id,
            MentiCharacterProfile.completedKey: true,
            MentiCharacterProfile.nameKey: 'Teszt Menti',
            MentiProfileStorage.studioBackgroundKey: 1,
            'mennyiment_menti_xp_v2': jsonEncode({
              'xp': 150,
              'days': <String>[],
              'completed': <String>[],
            }),
          });
          final prefs = await SharedPreferences.getInstance();
          await tester.pumpWidget(const MennyiMentApp());
          await frames(tester);
          expect(find.text('Teszt Menti • 4. szint'), findsOneWidget);
          // Home intentionally retains its original artwork in this catalog task.
          expect(
            tester
                .widget<MentiEvolution>(find.byType(MentiEvolution))
                .assetPath,
            'assets/images/menti_open.png',
          );
          expect(find.byType(MentiCharacterSetupPage), findsNothing);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();

          await tester.pumpWidget(const MaterialApp(home: AvatarPage()));
          await frames(tester);
          final mint = find.ancestor(
            of: find.text('Mentazöld'),
            matching: find.byType(InkWell),
          );
          expect(
            find.descendant(of: mint, matching: find.text('Kiválasztva')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();

          await tester.pumpWidget(const MaterialApp(home: MentiProgressPage()));
          await frames(tester);
          expect(find.text('Menti • 4. szint'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          expect(prefs.get(familyKey), family.id);
          expect(prefs.get(outfitKey), outfit.id);
          expect(prefs.get(MentiProfileStorage.studioBackgroundKey), 1);
        }
      },
    );
  }

  testWidgets(
    'Home reloads the profile after saving stable IDs in the selector',
    (tester) async {
      largeView(tester);
      SharedPreferences.setMockInitialValues({
        familyKey: 'girl',
        outfitKey: 'legendary',
        MentiCharacterProfile.completedKey: true,
        MentiCharacterProfile.nameKey: 'Régi név',
      });
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(const MennyiMentApp());
      await frames(tester);
      await tester.tap(find.text('Saját Menti kiválasztása'));
      await frames(tester);
      expect(find.text('Lány Menti  •  Legendás szett'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Friss név');
      await tester.ensureVisible(find.text('Saját Menti mentése'));
      await tester.tap(find.text('Saját Menti mentése'));
      await frames(tester);
      expect(find.byType(MentiCharacterSetupPage), findsNothing);
      expect(find.text('Friss név • 1. szint'), findsOneWidget);
      expect(prefs.get(familyKey), 'girl');
      expect(prefs.get(outfitKey), 'legendary');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  test(
    'XP actions preserve every family/outfit ID and keep existing reward rules',
    () async {
      for (final family in MentiCharacterFamily.values) {
        for (final outfit in MentiOutfit.values) {
          SharedPreferences.setMockInitialValues({
            familyKey: family.id,
            outfitKey: outfit.id,
          });
          final prefs = await SharedPreferences.getInstance();
          expect((await MentiXpStore.load()).xp, 0);
          expect((await MentiXpStore.checkInToday()).xp, 10);
          expect((await MentiXpStore.checkInToday()).xp, 10);
          expect((await MentiXpStore.completeWeekly('review')).xp, 25);
          expect((await MentiXpStore.completeWeekly('review')).xp, 25);
          expect((await MentiXpStore.load()).xp, 25);
          expect(prefs.get(familyKey), family.id);
          expect(prefs.get(outfitKey), outfit.id);
        }
      }
    },
  );

  for (final value in <Object>['future-choice', 42, true]) {
    testWidgets('Unrecognized $value survives an unrelated profile save', (
      tester,
    ) async {
      largeView(tester);
      SharedPreferences.setMockInitialValues({
        familyKey: value,
        outfitKey: value,
      });
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MentiCharacterSetupPage(),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Új név');
      await tester.ensureVisible(find.text('Saját Menti mentése'));
      await tester.tap(find.text('Saját Menti mentése'));
      await tester.pumpAndSettle();
      expect(prefs.get(familyKey), value);
      expect(prefs.get(outfitKey), value);
      expect(prefs.get(MentiCharacterProfile.nameKey), 'Új név');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Explicit selections replace only their own unrecognized preference',
    (tester) async {
      largeView(tester);
      SharedPreferences.setMockInitialValues({
        familyKey: 'future-family',
        outfitKey: 'future-outfit',
      });
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MentiCharacterSetupPage(),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      Future<void> open() async {
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
      }

      Future<void> save() async {
        await tester.ensureVisible(find.text('Saját Menti mentése'));
        await tester.tap(find.text('Saját Menti mentése'));
        await tester.pumpAndSettle();
      }

      await open();
      await tester.tap(find.text('Lány Menti'));
      await tester.pump();
      await save();
      expect(prefs.get(familyKey), 'girl');
      expect(prefs.get(outfitKey), 'future-outfit');
      await open();
      await tester.ensureVisible(find.text('Buli szett'));
      await tester.tap(find.text('Buli szett'));
      await tester.pump();
      await save();
      expect(prefs.get(familyKey), 'girl');
      expect(prefs.get(outfitKey), 'party');
      expect(tester.takeException(), isNull);
    },
  );
}
