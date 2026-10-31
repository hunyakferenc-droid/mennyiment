import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/app_language.dart';
import 'package:mennyiment/drink_journal_page.dart';
import 'package:mennyiment/home_widgets.dart';
import 'package:mennyiment/main.dart';
import 'package:mennyiment/menti_motion.dart';
import 'package:mennyiment/menti_progress.dart';
import 'package:mennyiment/menti_profile_storage.dart';
import 'package:mennyiment/menti_rewards.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const xp = '{"xp":150,"days":[],"completed":[],"future":true}';
  final entries = [
    for (var i = 0; i < 8; i++)
      {'name': 'Entry $i', 'ml': 250, 'percent': 0,
        'time': DateTime(2026, 10, 25, 12, i).toIso8601String(),
        if (i == 0) 'priceFt': 0, 'future': {'keep': i}},
  ];
  Map<String, Object> seed(String locale, {String? journal, String? experience}) => {
    AppLanguage.preferenceKey: locale,
    MentiMotionSettings.preferenceKey: true,
    'mennyiment_character_setup_complete_v1': true,
    MentiProfileStorage.characterStyleKey: 'Lány Menti',
    MentiProfileStorage.outfitKey: 'Legendás szett',
    MentiRewards.preferenceKey: <String>['future:hat'],
    'mennyiment_drinks_v1': journal ?? jsonEncode(entries),
    'mennyiment_menti_xp_v2': experience ?? xp,
  };
  void viewport(WidgetTester tester, double width, [double scale = 1]) {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    tester.binding.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.binding.platformDispatcher.clearTextScaleFactorTestValue);
  }
  Future<void> disposeApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }

  for (final locale in ['hu', 'en']) {
    for (final width in [320.0, 390.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('$locale home fits ${width}px at ${scale}x text', (tester) async {
          viewport(tester, width, scale);
          SharedPreferences.setMockInitialValues(seed(locale));
          await tester.pumpWidget(const MennyiMentApp());
          await tester.pumpAndSettle();
          final s = appStrings(tester.element(find.byType(HomePage)));
          expect(find.text(s.homeGreeting), findsOneWidget);
          // The primary action is before the tall character and summary cards.
          final add = find.widgetWithText(FilledButton, s.addDrink);
          expect(tester.getRect(add).bottom, lessThan(800));
          final scrollable = find.byType(Scrollable).first;
          for (final text in [s.homeTodayDrinks, s.homeMonthSpending, s.explore,
            s.personalGoals, s.recentEntries, s.statisticsCaution]) {
            await tester.scrollUntilVisible(find.text(text), 250,
              scrollable: scrollable, maxScrolls: 80);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
          final prefs = await SharedPreferences.getInstance();
          expect(prefs.getString('mennyiment_drinks_v1'), jsonEncode(entries));
          expect(prefs.getString('mennyiment_menti_xp_v2'), xp);
          expect(prefs.getString(MentiProfileStorage.outfitKey), 'Legendás szett');
          await disposeApp(tester);
        });
      }
    }

    testWidgets('$locale journal navigation is read-only and rejects duplicate pushes', (tester) async {
      viewport(tester, 320);
      SharedPreferences.setMockInitialValues(seed(locale));
      await tester.pumpWidget(const MennyiMentApp());
      await tester.pumpAndSettle();
      final navigation = tester.widget<NavigationBar>(find.byType(NavigationBar));
      navigation.onDestinationSelected!(1);
      navigation.onDestinationSelected!(1);
      await tester.pumpAndSettle();
      expect(find.byType(DrinkJournalPage), findsOneWidget);
      expect(find.text('Entry 7'), findsOneWidget);
      final s = appStrings(tester.element(find.byType(DrinkJournalPage)));
      expect(find.text(s.homeUnknownPrice), findsWidgets);
      await tester.scrollUntilVisible(find.text('Entry 0'), 250,
        scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      expect(find.text('Entry 0'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(DrinkJournalPage), findsNothing);
      await tester.tap(find.byKey(const ValueKey('nav-menti')));
      await tester.pumpAndSettle();
      expect(find.byType(MentiProgressPage), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('mennyiment_drinks_v1'), jsonEncode(entries));
      expect(prefs.getString('mennyiment_menti_xp_v2'), xp);
      expect(prefs.getString(MentiProfileStorage.characterStyleKey), 'Lány Menti');
      expect(prefs.getStringList(MentiRewards.preferenceKey), contains('future:hat'));
      await disposeApp(tester);
    });

    testWidgets('$locale journal add returns to the existing picker', (tester) async {
      viewport(tester, 390);
      SharedPreferences.setMockInitialValues(seed(locale));
      await tester.pumpWidget(const MennyiMentApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nav-journal')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('journal-add-drink')));
      await tester.pumpAndSettle();
      expect(find.byType(DrinkJournalPage), findsNothing);
      expect(find.text('Ital hozzáadása'), findsOneWidget);
      expect((await SharedPreferences.getInstance()).getString('mennyiment_drinks_v1'), jsonEncode(entries));
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('$locale unreadable journal is not presented as an empty journal', (tester) async {
      viewport(tester, 390);
      SharedPreferences.setMockInitialValues(seed(locale, journal: '{broken'));
      await tester.pumpWidget(const MennyiMentApp());
      await tester.pumpAndSettle();
      expect(find.byType(HomeStatTile), findsNothing);
      final nav = tester.widget<NavigationDestination>(find.byKey(const ValueKey('nav-journal')));
      expect(nav.enabled, isFalse);
      final s = appStrings(tester.element(find.byType(HomePage)));
      await tester.scrollUntilVisible(find.byKey(const ValueKey('journal-error')), 250,
        scrollable: find.byType(Scrollable).first, maxScrolls: 40);
      expect(find.text(s.homeJournalLoadError), findsOneWidget);
      expect(find.text(s.homeEmptyJournal), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('mennyiment_drinks_v1'), '{broken');
      expect(prefs.getString('mennyiment_menti_xp_v2'), xp);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('$locale unreadable XP shows retry without inventing a level', (tester) async {
      viewport(tester, 390);
      SharedPreferences.setMockInitialValues(seed(locale, experience: '{broken'));
      await tester.pumpWidget(const MennyiMentApp());
      await tester.pumpAndSettle();
      expect(find.byType(HomeMentiCard), findsNothing);
      final s = appStrings(tester.element(find.byType(HomePage)));
      expect(find.text(s.homeCheckInUnavailable), findsOneWidget);
      expect((await SharedPreferences.getInstance()).getString('mennyiment_menti_xp_v2'), '{broken');
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });
  }

  test('Journal snapshot sorts a copy and leaves source and unknown fields intact', () {
    final source = entries.map((e) => Drink.fromJson(e)).toList();
    final before = source.map((d) => jsonEncode(d.toJson())).toList();
    final page = DrinkJournalPage(drinks: source);
    expect(page.drinks.first.name, 'Entry 7');
    expect(source.map((d) => jsonEncode(d.toJson())), before);
    expect(() => page.drinks.clear(), throwsUnsupportedError);
  });
}
