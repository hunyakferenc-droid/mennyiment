import 'support/adult_access_fixture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/main.dart';
import 'package:mennyiment/menti_character_catalog.dart';
import 'package:mennyiment/menti_evolution.dart';
import 'package:mennyiment/menti_motion.dart';
import 'package:mennyiment/menti_animation.dart';
import 'package:mennyiment/animated_avatar.dart';
import 'package:mennyiment/cartoon_avatar.dart';
import 'package:mennyiment/menti_goal_world.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MentiMotionSettings settings(WidgetTester tester) =>
      MentiMotionScope.settingsOf(tester.element(find.byType(MentiEvolution)))!;
  String imagePath(WidgetTester tester) {
    final provider = tester.widget<Image>(find.byType(Image).first).image;
    return ((provider is ResizeImage ? provider.imageProvider : provider)
            as AssetImage)
        .assetName;
  }

  List<String> transforms(WidgetTester tester) => tester
      .widgetList<Transform>(
        find.descendant(
          of: find.byType(MentiEvolution),
          matching: find.byType(Transform),
        ),
      )
      .map((w) => w.transform.storage.toString())
      .toList();

  for (final family in MentiCharacterFamily.values) {
    for (final outfit in MentiOutfit.values) {
      testWidgets(
        '${family.id}/${outfit.id}: manual, system, reaction and route ticker policy',
        (tester) async {
          SharedPreferences.setMockInitialValues({adultAccessKey: adultAccessValue,
            'mennyiment_character_style_v2': family.id,
            'mennyiment_outfit_v2': outfit.id,
            'mennyiment_menti_xp_v2': 'keep-xp',
          });
          final prefs = await SharedPreferences.getInstance();
          var taps = 0;
          Future<void> show({
            bool system = false,
            bool accessible = false,
            bool ticker = true,
            int reaction = 0,
          }) async {
            await tester.pumpWidget(
              MaterialApp(
                home: MediaQuery(
                  data: MediaQueryData(
                    disableAnimations: system,
                    accessibleNavigation: accessible,
                  ),
                  child: MentiMotionScope(
                    child: TickerMode(
                      enabled: ticker,
                      child: MentiEvolution(
                        assetPath: family.assetFor(outfit),
                        reaction: reaction,
                        onTap: () => taps++,
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pump();
          }

          await show();
          await tester.pump(const Duration(milliseconds: 100));
          expect(tester.hasRunningAnimations, isTrue);
          await settings(tester).setReduced(true);
          await tester.pumpAndSettle();
          expect(tester.hasRunningAnimations, isFalse);
          expect(tester.binding.transientCallbackCount, 0);
          final still = transforms(tester);
          await tester.tap(find.byType(MentiEvolution));
          await show(reaction: 1);
          await tester.pump(const Duration(seconds: 6));
          expect(taps, 1);
          expect(transforms(tester), still);
          expect(tester.binding.transientCallbackCount, 0);
          expect(imagePath(tester), family.assetFor(outfit));
          await show(system: true);
          await settings(tester).setReduced(false);
          await tester.pumpAndSettle();
          expect(tester.hasRunningAnimations, isFalse);
          expect(prefs.getBool(MentiMotionSettings.preferenceKey), false);
          await show(accessible: true);
          await tester.pumpAndSettle();
          expect(tester.hasRunningAnimations, isFalse);
          await show();
          expect(tester.hasRunningAnimations, isTrue);
          await show(ticker: false);
          await tester.pumpAndSettle();
          expect(tester.hasRunningAnimations, isFalse);
          await show();
          expect(tester.hasRunningAnimations, isTrue);
          expect(imagePath(tester), family.assetFor(outfit));
          expect(prefs.getString('mennyiment_character_style_v2'), family.id);
          expect(prefs.getString('mennyiment_outfit_v2'), outfit.id);
          expect(prefs.getString('mennyiment_menti_xp_v2'), 'keep-xp');
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          expect(tester.binding.transientCallbackCount, 0);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'Saved manual preference survives a fresh scope and preference instance',
    (tester) async {
      SharedPreferences.setMockInitialValues({adultAccessKey: adultAccessValue,});
      Future<void> show() => tester.pumpWidget(
        const MaterialApp(home: MentiMotionScope(child: MentiEvolution())),
      );
      await show();
      await tester.pump();
      await settings(tester).setReduced(true);
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      final persisted = {
        for (final key in prefs.getKeys()) key: prefs.get(key)!,
      };
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      persisted[adultAccessKey] = adultAccessValue;
    SharedPreferences.setMockInitialValues(persisted);
      await show();
      await tester.pumpAndSettle();
      expect(settings(tester).manual, true);
      expect(tester.hasRunningAnimations, isFalse);
      await settings(tester).setReduced(false);
      await tester.pump();
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Studio switch persists and updates home through the shared route scope',
    (tester) async {
      tester.view.physicalSize = const Size(1100, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({adultAccessKey: adultAccessValue,
        'mennyiment_character_setup_complete_v1': true,
        'mennyiment_character_style_v2': 'girl',
        'mennyiment_outfit_v2': 'legendary',
      });
      await tester.pumpWidget(const MennyiMentApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byKey(const ValueKey('home-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PopupMenuItem<String>, 'Menti és profil'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final toggle = find.byKey(const ValueKey('menti-reduce-motion'));
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(
        (await SharedPreferences.getInstance()).getBool(
          MentiMotionSettings.preferenceKey,
        ),
        true,
      );
      expect(tester.hasRunningAnimations, isFalse);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
      expect(
        tester.widget<MentiEvolution>(find.byType(MentiEvolution)).assetPath,
        MentiCharacterFamily.girl.assetFor(MentiOutfit.legendary),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Live platform accessibility flags automatically stop and resume the app',
    (tester) async {
      SharedPreferences.setMockInitialValues({adultAccessKey: adultAccessValue,
        'mennyiment_character_setup_complete_v1': true,
      });
      final dispatcher = tester.binding.platformDispatcher;
      addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
      dispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      await tester.pumpWidget(const MennyiMentApp());
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
      dispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures();
      await tester.pump();
      expect(tester.hasRunningAnimations, isTrue);
      await settings(tester).setReduced(true);
      await tester.pumpAndSettle();
      dispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      await tester.pumpAndSettle();
      dispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures();
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
      await settings(tester).setReduced(false);
      await tester.pump();
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  for (final legacy in <Widget>[
    const MentiAnimation(),
    const FloatingMenti(),
    const AnimatedCartoonAvatar(color: Colors.orange),
    const CartoonAvatar(),
    const MentiGoalWorldPage(goals: []),
  ]) {
    testWidgets(
      '${legacy.runtimeType}: system reduction removes continuous work and resumes',
      (tester) async {
        Future<void> show(bool reduced) => tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduced),
              child: legacy,
            ),
          ),
        );
        await show(true);
        await tester.pumpAndSettle();
        expect(tester.binding.transientCallbackCount, 0);
        await tester.pump(const Duration(seconds: 10));
        expect(tester.binding.transientCallbackCount, 0);
        await show(false);
        await tester.pump();
        expect(tester.hasRunningAnimations, isTrue);
        await show(true);
        await tester.pumpAndSettle();
        expect(tester.hasRunningAnimations, isFalse);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );
  }

  test('Preference load handles invalid data conservatively and disposal during IO', () async {
    SharedPreferences.setMockInitialValues({adultAccessKey: adultAccessValue,
      MentiMotionSettings.preferenceKey: 'unknown',
    });
    final controller = MentiMotionSettings();
    await controller.load();
    expect(controller.manual, true);
    expect(
      (await SharedPreferences.getInstance()).get(
        MentiMotionSettings.preferenceKey,
      ),
      'unknown',
    );
    final future = controller.setReduced(false);
    controller.dispose();
    await future;
  });
}
