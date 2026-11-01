import 'support/adult_access_fixture.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/main.dart';
import 'package:mennyiment/menti_evolution.dart';
import 'package:mennyiment/menti_motion.dart';

void main() {
  const journalKey = 'mennyiment_drinks_v1';
  const xpKey = 'mennyiment_menti_xp_v2';
  const familyKey = 'mennyiment_character_style_v2';
  const outfitKey = 'mennyiment_outfit_v2';
  final xp = jsonEncode({'xp': 150, 'days': [], 'completed': []});

  Future<void> frames(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
  }

  Future<SharedPreferences> open(WidgetTester tester, String saved) async {
    tester.view.physicalSize = const Size(1100, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({adultAccessKey: adultAccessValue,
      journalKey: saved,
      xpKey: xp,
      familyKey: 'girl',
      outfitKey: 'legendary',
      'mennyiment_character_setup_complete_v1': true,
    });
    await tester.pumpWidget(const MennyiMentApp());
    await frames(tester);
    return SharedPreferences.getInstance();
  }

  Future<void> reduceInStudio(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Menti és profil'));
    await frames(tester);
    final toggle = find.byKey(const ValueKey('menti-reduce-motion'));
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
  }

  void expectProfileAndXp(SharedPreferences prefs) {
    expect(prefs.getString(familyKey), 'girl');
    expect(prefs.getString(outfitKey), 'legendary');
    expect(prefs.getString(xpKey), xp);
  }

  testWidgets(
    'Reduced motion preserves profile and XP while hardened double submit records once',
    (tester) async {
      final oldRecord = {
        'name': 'Régi ital',
        'ml': 250,
        'percent': 4,
        'time': DateTime.now().toIso8601String(),
        'priceFt': 0,
        'legacyData': {'keep': true},
      };
      final saved = jsonEncode([oldRecord]);
      final prefs = await open(tester, saved);
      await reduceInStudio(tester);
      expect(tester.hasRunningAnimations, isFalse);
      expect(prefs.getString(journalKey), saved);
      expectProfileAndXp(prefs);

      await tester.ensureVisible(find.text('ITAL NAPLÓZÁSA'));
      await tester.tap(find.text('ITAL NAPLÓZÁSA'));
      await frames(tester);
      await tester.tap(find.text('Sör (általános)'));
      await frames(tester);
      final submit = tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Mentés a naplóba'),
          )
          .onPressed!;
      submit();
      submit();
      await frames(tester);
      final records = jsonDecode(prefs.getString(journalKey)!) as List;
      expect(records.length, 2);
      expect(records.last, oldRecord);
      expectProfileAndXp(prefs);
      expect(prefs.getBool(MentiMotionSettings.preferenceKey), true);

      final persisted = {
        for (final key in prefs.getKeys()) key: prefs.get(key)!,
      };
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      persisted[adultAccessKey] = adultAccessValue;
    SharedPreferences.setMockInitialValues(persisted);
      await tester.pumpWidget(const MennyiMentApp());
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
      expect(
        tester.widget<MentiEvolution>(find.byType(MentiEvolution)).assetPath,
        'assets/images/menti_outfits_642/lany/legendas.png',
      );
      expect(find.text('Menti • 4. szint'), findsOneWidget);
      expect(
        (jsonDecode(
          (await SharedPreferences.getInstance()).getString(journalKey)!,
        ) as List).length,
        2,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'Motion preference cannot unlock or overwrite a corrupt journal',
    (tester) async {
      const broken = '[{"name":"broken"}]';
      final prefs = await open(tester, broken);
      await reduceInStudio(tester);
      expect(find.byKey(const ValueKey('journal-error')), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'ITAL NAPLÓZÁSA'),
            )
            .onPressed,
        isNull,
      );
      expect(prefs.getString(journalKey), broken);
      expectProfileAndXp(prefs);
      expect(prefs.getBool(MentiMotionSettings.preferenceKey), true);
      expect(tester.hasRunningAnimations, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
