import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/main.dart';
import 'package:mennyiment/menti_access.dart';
import 'package:mennyiment/menti_onboarding.dart';
import 'package:mennyiment/menti_identity/menti_identity.dart';
import 'package:mennyiment/menti_identity/menti_identity_store.dart';
import 'package:mennyiment/drink_journal_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<void> next(WidgetTester tester) async {
    final f = find.byKey(const ValueKey('start-next'));
    await tester.scrollUntilVisible(
      f,
      200,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 40,
    );
    await tester.tap(f);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  for (final locale in ['hu', 'en']) {
    for (final scale in [1.0, 2.0]) {
      for (final width in [320.0, 360.0, 390.0, 430.0]) {
        testWidgets(
          '$locale fresh onboarding at ${width}px / ${scale}x saves chosen identity and restricts minors',
          (tester) async {
            tester.view.physicalSize = Size(width, 740);
            tester.view.devicePixelRatio = 1;
            tester.binding.platformDispatcher.textScaleFactorTestValue = scale;
            tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
                const FakeAccessibilityFeatures(disableAnimations: true);
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            addTearDown(
              tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
            );
            addTearDown(
              tester
                  .binding
                  .platformDispatcher
                  .clearAccessibilityFeaturesTestValue,
            );
            SharedPreferences.setMockInitialValues({
              'mennyiment_locale_v1': locale,
            });
            await tester.pumpWidget(const MennyiMentApp());
            await tester.pumpAndSettle();
            expect(find.byType(HomePage), findsNothing);
            await next(tester);
            await tester.scrollUntilVisible(
              find.byKey(const ValueKey('start-next')),
              200,
              scrollable: find.byType(Scrollable).first,
              maxScrolls: 40,
            );
            final disabled = tester.widget<FilledButton>(
              find.byKey(const ValueKey('start-next')),
            );
            expect(disabled.onPressed, isNull);
            final minor = find.byKey(const ValueKey('start-minor'));
            await tester.drag(
              find.byType(Scrollable).first,
              const Offset(0, 3000),
            );
            await tester.pumpAndSettle();
            await tester.scrollUntilVisible(
              minor,
              200,
              scrollable: find.byType(Scrollable).first,
              maxScrolls: 40,
            );
            await tester.pumpAndSettle();
            await tester.ensureVisible(minor);
            await tester.pumpAndSettle();
            await tester.tap(minor);
            await tester.pumpAndSettle();
            await next(tester);
            final girl = find.byKey(const ValueKey('start-family-girl'));
            await tester.drag(
              find.byType(Scrollable).first,
              const Offset(0, 3000),
            );
            await tester.pumpAndSettle();
            await tester.scrollUntilVisible(
              girl,
              200,
              scrollable: find.byType(Scrollable).first,
              maxScrolls: 40,
            );
            await tester.pumpAndSettle();
            await tester.ensureVisible(girl);
            await tester.pumpAndSettle();
            await tester.tap(girl);
            await tester.pumpAndSettle();
            final veteran = find.byKey(const ValueKey('start-age-veteran'));
            await tester.scrollUntilVisible(
              veteran,
              100,
              scrollable: find.byType(Scrollable).first,
              maxScrolls: 40,
            );
            await tester.pumpAndSettle();
            await tester.ensureVisible(veteran);
            await tester.pumpAndSettle();
            await tester.tap(veteran);
            await tester.pumpAndSettle();
            await next(tester);
            await tester.scrollUntilVisible(
              find.byKey(const ValueKey('start-name')),
              200,
              scrollable: find.byType(Scrollable).first,
              maxScrolls: 40,
            );
            await tester.pumpAndSettle();
            await tester.enterText(
              find.byKey(const ValueKey('start-name')),
              'Teszt Menti',
            );
            await next(tester);
            expect(find.byType(HomePage), findsOneWidget);
            final p = await SharedPreferences.getInstance();
            expect(
              MentiAccessSettings.decode(
                p.getString(MentiAccessSettings.key)!,
              )['audience'],
              'minor',
            );
            final identity = MentiIdentityDocument.decode(
              p.getString(MentiIdentityStore.key)!,
            );
            expect(identity.profile.name, 'Teszt Menti');
            expect(identity.profile.visual.value('family'), 'girl');
            expect(identity.profile.visual.value('age'), 'veteran');
            final navigation = tester.widget<NavigationBar>(
              find.byType(NavigationBar),
            );
            navigation.onDestinationSelected!(1);
            await tester.pumpAndSettle();
            expect(find.byType(DrinkJournalPage), findsNothing);
            expect(p.containsKey('mennyiment_drinks_v1'), false);
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pumpAndSettle();
            await tester.pumpWidget(const MennyiMentApp());
            await tester.pumpAndSettle();
            expect(find.byType(HomePage), findsOneWidget);
            expect(find.byKey(const ValueKey('start-next')), findsNothing);
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump();
          },
        );
      }
    }
  }
  testWidgets(
    'existing identity is preserved and only language and age are requested',
    (tester) async {
      final original = MentiIdentityDocument(
        profile: MentiIdentityProfile(
          name: 'Régi Menti',
          visual: MentiVisualProfile({
            'family': 'neutral',
            'age': 'adult',
            'future': 'keep',
          }),
        ),
      ).encode();
      SharedPreferences.setMockInitialValues({
        MentiIdentityStore.key: original,
        'mennyiment_drinks_v1': '[]',
        'mennyiment_menti_xp_v2': '{"xp":40,"days":[],"completed":[]}',
      });
      await tester.pumpWidget(const MennyiMentApp());
      await tester.pumpAndSettle();
      await next(tester);
      await tester.tap(find.byKey(const ValueKey('start-adult')));
      await tester.pumpAndSettle();
      await next(tester);
      expect(find.byType(HomePage), findsOneWidget);
      expect(
        (await SharedPreferences.getInstance()).getString(
          MentiIdentityStore.key,
        ),
        original,
      );
      expect(find.byType(MentiStartGate), findsOneWidget);
      expect(
        jsonDecode(
          (await SharedPreferences.getInstance()).getString(
            'mennyiment_menti_xp_v2',
          )!,
        )['xp'],
        40,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
