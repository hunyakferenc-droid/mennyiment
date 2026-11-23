// Real native UI journeys; also copied into the pinned #50 source archive.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/main.dart' as app;
import 'package:mennyiment/statistics.dart';
import 'package:mennyiment/app_language.dart';
import 'package:mennyiment/menti_fitness.dart';
import 'package:mennyiment/menti_rhythm.dart';
import 'package:mennyiment/menti_club_store.dart';
import 'package:mennyiment/menti_xp_store.dart';
import 'package:mennyiment/menti_collection_store.dart';
import 'package:mennyiment/menti_identity/menti_identity_store.dart';

import '../tool/menti_home_review.dart' as review;
import 'menti_home_review_test.dart' show fromTop, clubTap;
import 'menti_beta_device_test.dart' show reach, tap, until;

Future<void> textTap(WidgetTester t, Finder f) async {
  await fromTop(t);
  await reach(t, f);
  await t.tap(f);
  await t.pumpAndSettle();
}

Future<void> firstUse33(WidgetTester t, {required bool isReview, String locale = 'en'}) async {
  final p = await SharedPreferences.getInstance();
  await p.reload();
  expect(p.getKeys().where((k) => k.startsWith('mennyiment_')), isEmpty);
  if (isReview) {
    await review.main();
  } else {
    app.main();
  }
  await t.pumpAndSettle();
  await tap(t, 'start-language-$locale');
  await tap(t, 'start-next');
  await tap(t, 'start-adult');
  await tap(t, 'start-next');
  final family = find.byKey(const ValueKey('start-family-girl'));
  await reach(t, family);
  // Exercise the enclosing route's PopScope directly from the onboarding UI.
  expect(await Navigator.of(t.element(family)).maybePop(), isTrue);
  await t.pumpAndSettle();
  await reach(t, find.byKey(const ValueKey('start-adult')));
  await tap(t, 'start-next');
  await tap(t, 'start-family-girl');
  await tap(t, 'start-look-girl-base-v1');
  await tap(t, 'start-next');
  final name = find.byKey(const ValueKey('start-name'));
  await reach(t, name);
  await t.enterText(name, 'Android Upgrade');
  // ignore: avoid_print
  print(
    'ANDROID33_NAME_IME inset=${MediaQuery.viewInsetsOf(t.element(name)).bottom}',
  );
  await t.testTextInput.receiveAction(TextInputAction.done);
  await t.pumpAndSettle();
  await tap(t, 'start-next');
  await until(t, find.byType(app.HomePage));
  await clubTap(t, 'home-primary-log');
  final favorite = find.byIcon(Icons.star_border).first;
  await reach(t, favorite);
  await t.tap(favorite);
  await t.pumpAndSettle();
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  do {
    await p.reload();
    if (p.getStringList('mennyiment_favorites_v1')?.isNotEmpty == true) break;
    await t.pump(const Duration(milliseconds: 100));
  } while (DateTime.now().isBefore(deadline));
  expect(p.getStringList('mennyiment_favorites_v1'), hasLength(1));
  await t.tap(
    find
        .descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(ListTile),
        )
        .first,
  );
  await t.pumpAndSettle();
  final s = appStrings(t.element(find.byType(app.HomePage)));
  final price = find.widgetWithText(TextFormField, s.journalOptionalPrice);
  await reach(t, price);
  await t.enterText(price, '0');
  await t.pumpAndSettle();
  final save = find.text(s.journalSave);
  await reach(t, save);
  expect(save.hitTestable(), findsOneWidget);
  // ignore: avoid_print
  print(
    'ANDROID33_PRICE_IME inset=${MediaQuery.viewInsetsOf(t.element(price)).bottom}; save hit-testable',
  );
  await t.tap(save);
  await t.pumpAndSettle();
  await p.reload();
  expect(
    (jsonDecode(
      p.getString('mennyiment_drinks_v1')!,
    ) as List).single['priceFt'],
    0,
  );
  expect(
    (await MentiXpStore.load()).xp,
    0,
    reason: 'Logging alcohol never earns XP',
  );
  await fromTop(t);
  await textTap(t, find.text(s.dailyOpen).first);
  await tap(t, 'mood-3');
  await tap(t, 'energy-4');
  await tap(t, 'daily-save');
  await until(t, find.text(s.dailySaved));
  expect((await MentiXpStore.load()).xp, 10);
  await t.tap(find.byType(BackButton));
  await t.pumpAndSettle();
  final statisticsTab = find.descendant(
    of: find.byType(NavigationBar),
    matching: find.byType(NavigationDestination),
  ).at(2);
  expect(statisticsTab.hitTestable(), findsOneWidget);
  await t.tap(statisticsTab);
  await t.pumpAndSettle();
  expect(find.byType(StatisticsPage), findsOneWidget);
  expect(
    t.widget<StatisticsPage>(find.byType(StatisticsPage)).drinks,
    hasLength(1),
  );
  await t.tap(find.byType(BackButton));
  await t.pumpAndSettle();
  if (isReview) {
    await clubTap(t, 'home-fitness');
    await clubTap(t, 'fitness-play');
    final dynamic state = t.state(find.byType(MentiRhythmPage));
    final MentiRhythm game = state.game;
    for (var round = 0; round < 5; round++) {
      while (game.phase == RhythmPhase.demonstration) {
        await tap(t, 'rhythm-next');
      }
      for (final action in game.sequence) {
        await tap(t, 'rhythm-${action.name}');
      }
    }
    expect(game.completed, 5);
    await t.tap(find.byType(BackButton));
    await t.pumpAndSettle();
    await clubTap(t, 'fitness-cards');
    await clubTap(t, 'cards-start');
    for (var i = 0; i < 3; i++) {
      await clubTap(t, 'cards-next');
    }
    await clubTap(t, 'cards-club');
    await t.tap(find.byType(BackButton));
    await t.pumpAndSettle();
    await p.reload();
    final club = MentiClubRecord.decode(p.get(MentiClubStore.normalKey));
    expect(club.best, 5);
    expect(club.days, hasLength(1));
    expect(p.containsKey(MentiClubStore.testKey), false);
  } else {
    expect(find.byType(MentiFitnessClub), findsNothing);
    expect(
      find.byKey(const ValueKey('home-fitness')),
      findsNothing,
      reason: 'Experimental fitness remains REVIEW-only',
    );
  }
  await p.reload();
  expect(
    jsonDecode(p.getString(MentiIdentityStore.key)!)['profile']['name'],
    'Android Upgrade',
  );
  expect(
    jsonDecode(p.getString(CompleteLookStore.key)!)['look'],
    'girl-base-v1',
  );
  expect((await MentiXpStore.load()).xp, 10);
  // ignore: avoid_print
  print(
    'ANDROID33_FIRST_USE passed: clean $locale, onboarding route back, own girl, favorite, zero-price journal, statistics, legitimate 10 XP; REVIEW=$isReview',
  );
}
