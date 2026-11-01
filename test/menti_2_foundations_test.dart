import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/app_language.dart';
import 'package:mennyiment/menti_progress.dart';
import 'package:mennyiment/menti_profile_storage.dart';
import 'package:mennyiment/menti_rewards.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';
import 'package:mennyiment/menti_motion.dart';
import 'package:mennyiment/menti_reactions.dart';
import 'package:mennyiment/menti_ui.dart';
import 'package:mennyiment/menti_xp_store.dart';

void main() {
  test('Every reaction has distinct HU/EN content and stable index wrapping', () {
    for (final mood in MentiMood.values) {
      final hu = MentiReactions.message(mood);
      final en = MentiReactions.message(mood, locale: 'en');
      expect(hu, isNotEmpty);
      expect(en, isNotEmpty);
      expect(en, isNot(hu));
      expect(MentiReactions.message(mood, locale: 'fr'), hu);
      for (final index in [-100, -1, 0, 1, 100]) {
        expect(MentiReactions.message(mood, index: index), isNotEmpty);
        expect(MentiReactions.message(mood, index: index, locale: 'en'), isNotEmpty);
      }
    }
  });

  test('Week ranges use Monday midnight and exclude the following Monday', () {
    for (final day in [DateTime(2026, 3, 29, 23), DateTime(2026, 10, 25, 23)]) {
      final start = MentiXpStore.weekStart(day);
      final end = MentiXpStore.weekEnd(day);
      expect(start.weekday, DateTime.monday);
      expect(end.weekday, DateTime.monday);
      expect(start.hour, 0);
      expect(end.hour, 0);
      expect(day.isBefore(end), isTrue);
      expect(MentiXpStore.weekKey(day), MentiXpStore.dayKey(start));
      expect(MentiXpStore.weekKey(end), isNot(MentiXpStore.weekKey(day)));
      expect(end.subtract(const Duration(minutes: 1)).isBefore(end), isTrue);
    }
  });

  test('Budapest spring/fall weeks end at midnight after 167/169 hours', () {
    for (final pair in [(DateTime(2026, 3, 29, 23), 167), (DateTime(2026, 10, 25, 23), 169)]) {
      expect(MentiXpStore.weekEnd(pair.$1)
          .difference(MentiXpStore.weekStart(pair.$1)).inHours, pair.$2);
    }
  }, skip: Platform.environment['TZ'] != 'Europe/Budapest'
      ? 'Run with TZ=Europe/Budapest to verify DST.' : false);

  testWidgets('A level reaction grants no extra XP and keeps existing rewards', (tester) async {
    const journal = '[{"unchanged":"journal sentinel"}]';
    SharedPreferences.setMockInitialValues({
      'mennyiment_menti_xp_v2': jsonEncode({'xp': 40, 'days': [], 'completed': []}),
      'mennyiment_drinks_v1': journal,
      MentiProfileStorage.characterStyleKey: 'Lány Menti',
      MentiProfileStorage.outfitKey: 'Legendás szett',
      MentiRewards.preferenceKey: ['future:keep-this-reward'],
    });
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: const MentiProgressPage(),
    ));
    await tester.pumpAndSettle();
    final strings = appStrings(tester.element(find.byType(MentiProgressPage)));
    await tester.ensureVisible(find.text(strings.evolutionCheck));
    await tester.tap(find.text(strings.evolutionCheck));
    await tester.pumpAndSettle();
    expect((await MentiXpStore.load()).xp, 50);
    final bubble = tester.widget<MentiSpeechBubble>(find.byType(MentiSpeechBubble));
    expect(bubble.message, MentiReactions.message(MentiMood.levelUp, index: 1, locale: 'en'));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('mennyiment_drinks_v1'), journal);
    expect(prefs.getString(MentiProfileStorage.characterStyleKey), 'Lány Menti');
    expect(prefs.getString(MentiProfileStorage.outfitKey), 'Legendás szett');
    expect(prefs.getStringList(MentiRewards.preferenceKey), contains('future:keep-this-reward'));
    // Visiting again must neither replay an event nor award another daily check-in.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect((await MentiXpStore.checkInToday()).xp, 50);
    expect(tester.takeException(), isNull);
  });

  for (final locale in ['hu', 'en']) {
    testWidgets('$locale reaction fits a 320px phone at large text scale', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
        locale: Locale(locale),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: true,
            textScaler: const TextScaler.linear(2),
          ),
          child: child!,
        ),
        home: Scaffold(body: MentiPageBody(children: [
          MentiPanel(child: MentiSpeechBubble(message:
            MentiReactions.message(MentiMood.levelUp, locale: locale))),
        ])),
      ));
      await tester.pumpAndSettle();
      final bubble = tester.element(find.byType(MentiSpeechBubble));
      expect(MentiMotionScope.reducedOf(bubble), isTrue);
      final switcher = tester.widget<AnimatedSwitcher>(find.descendant(
        of: find.byType(MentiSpeechBubble), matching: find.byType(AnimatedSwitcher)));
      expect(switcher.duration, Duration.zero);
      expect(tester.takeException(), isNull);
    });
  }
}
