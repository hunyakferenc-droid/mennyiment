import 'support/adult_access_fixture.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/app_language.dart';
import 'package:mennyiment/daily_menti_store.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';
import 'package:mennyiment/main.dart';
import 'package:mennyiment/menti_completion.dart';
import 'package:mennyiment/menti_evolution.dart';
import 'package:mennyiment/menti_reactions.dart';
import 'package:mennyiment/menti_xp_store.dart';
import 'package:mennyiment/personal_goal_store.dart';
import 'package:mennyiment/personal_hub.dart';
import 'package:mennyiment/personal_hub_data.dart';

import 'personal_hub_fixtures.dart';

class _ControlledReader extends PersonalHubReader {
  final requests = <Completer<PersonalHubSnapshot>>[];
  @override
  Future<PersonalHubSnapshot> load(DateTime Function() clock) {
    final request = Completer<PersonalHubSnapshot>();
    requests.add(request);
    return request.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 10, 25, 12);
  Map<String, Object?> snapshot(SharedPreferences prefs) => {
    for (final key in prefs.getKeys()) key: prefs.get(key),
  };
  void viewport(WidgetTester tester, [double width = 320]) {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }
  Widget app(String locale, Widget page, {double scale = 1}) => MaterialApp(
    locale: Locale(locale),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(
      disableAnimations: true, textScaler: TextScaler.linear(scale)), child: child!),
    home: page,
  );
  Future<void> scroll(WidgetTester tester, String key, {bool up = false}) async {
    await tester.scrollUntilVisible(find.byKey(ValueKey(key)), up ? -250 : 250,
      scrollable: find.byType(Scrollable).first, maxScrolls: 100);
    await tester.pumpAndSettle();
  }
  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  for (final locale in ['hu', 'en']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('$locale complete hub at 320px/${scale}x text preserves every preference', (tester) async {
        viewport(tester);
        SharedPreferences.setMockInitialValues(hubValues(now));
        final prefs = await SharedPreferences.getInstance();
        final before = snapshot(prefs);
        await tester.pumpWidget(app(locale, PersonalHubPage(clock: () => now), scale: scale));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('hub-reaction')), findsNothing);
        final s = appStrings(tester.element(find.byType(PersonalHubPage)));
        expect(find.text(s.hubTitle), findsOneWidget);
        for (final id in ['profile', 'xp', 'daily', 'goals', 'challenges', 'journal']) {
          await scroll(tester, 'hub-$id');
          expect(tester.takeException(), isNull);
        }
        expect(find.text(s.partialPrices(1)), findsOneWidget);
        expect(find.text(s.hubKnownZero), findsOneWidget);
        expect(snapshot(prefs), before);
        await tester.tap(find.byKey(const ValueKey('hub-refresh')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('hub-reaction')), findsNothing);
        expect(snapshot(prefs), before);
        expect(tester.takeException(), isNull);
        await close(tester);
      });
    }
    testWidgets('$locale missing data is not displayed as recorded zero; corrupt XP stays separate', (tester) async {
      viewport(tester);
      SharedPreferences.setMockInitialValues({adultAccessKey: adultAccessValue,MentiXpStore.currentKey: '{bad'});
      await tester.pumpWidget(app(locale, PersonalHubPage(clock: () => now)));
      await tester.pumpAndSettle();
      final s = appStrings(tester.element(find.byType(PersonalHubPage)));
      await scroll(tester, 'hub-status-xp');
      expect(find.text(s.hubReadError), findsOneWidget);
      expect(find.byType(MentiEvolution), findsNothing);
      await scroll(tester, 'hub-status-journal');
      expect(find.text(s.hubRecordedEmpty), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mennyiment_drinks_v1', '[]');
      await tester.tap(find.byKey(const ValueKey('hub-refresh')));
      await tester.pumpAndSettle();
      await scroll(tester, 'hub-journal');
      expect(find.text(s.hubRecordedEmpty), findsOneWidget);
      expect(prefs.getString(MentiXpStore.currentKey), '{bad');
      expect(tester.takeException(), isNull);
      await close(tester);
    });
    testWidgets('$locale new evidence reacts once; refresh and reopening do not replay it', (tester) async {
      viewport(tester);
      SharedPreferences.setMockInitialValues(hubValues(now));
      await tester.pumpWidget(app(locale, PersonalHubPage(clock: () => now)));
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      final before = snapshot(prefs);
      final updated = jsonDecode(prefs.getString(PersonalGoalStore.key)!) as Map<String, dynamic>;
      updated['reflectionDays'] = ['2026-10-24', '2026-10-25'];
      await prefs.setString(PersonalGoalStore.key, jsonEncode(updated));
      await tester.tap(find.byKey(const ValueKey('hub-refresh')));
      await tester.pumpAndSettle();
      final bubble = find.byKey(const ValueKey('hub-reaction'));
      expect(tester.widget<MentiSpeechBubble>(bubble).message,
        MentiReactions.message(MentiMood.personalGoalCompleted, locale: locale));
      final card = find.byType(MentiReactionCard);
      final fade = tester.widget<TweenAnimationBuilder<double>>(find.descendant(
        of: card, matching: find.byType(TweenAnimationBuilder<double>)).first);
      expect(fade.duration, Duration.zero);
      expect(tester.hasRunningAnimations, false);
      expect(prefs.getString(MentiXpStore.currentKey), before[MentiXpStore.currentKey]);
      await tester.tap(find.byKey(const ValueKey('hub-refresh')));
      await tester.pumpAndSettle();
      expect(bubble, findsNothing);
      await close(tester);
      await tester.pumpWidget(app(locale, PersonalHubPage(clock: () => now)));
      await tester.pumpAndSettle();
      expect(bubble, findsNothing);
      expect(snapshot(prefs), {...before, PersonalGoalStore.key: jsonEncode(updated)});
      expect(tester.takeException(), isNull);
      await close(tester);
    });
    testWidgets('$locale failed preference access is retryable without altering stored data', (tester) async {
      viewport(tester);
      SharedPreferences.setMockInitialValues(hubValues(now));
      var fail = true;
      final reader = PersonalHubReader(open: () {
        if (fail) throw StateError('Injected preference failure');
        return SharedPreferences.getInstance();
      });
      final prefs = await SharedPreferences.getInstance();
      final before = snapshot(prefs);
      await tester.pumpWidget(app(locale, PersonalHubPage(reader: reader, clock: () => now)));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('hub-global-error')), findsOneWidget);
      final s = appStrings(tester.element(find.byType(PersonalHubPage)));
      fail = false;
      await tester.tap(find.text(s.challengeRetry));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('hub-global-error')), findsNothing);
      expect(snapshot(prefs), before);
      expect(tester.takeException(), isNull);
      await close(tester);
    });
  }
  testWidgets('Locale changes reformat the existing snapshot without writing preferences', (tester) async {
    viewport(tester);
    SharedPreferences.setMockInitialValues(hubValues(now));
    final page = PersonalHubPage(clock: () => now);
    final prefs = await SharedPreferences.getInstance();
    final before = snapshot(prefs);
    await tester.pumpWidget(app('hu', page));
    await tester.pumpAndSettle();
    await scroll(tester, 'hub-journal');
    expect(find.text(localeCurrency(0, 'hu')), findsOneWidget);
    await tester.pumpWidget(app('en', page));
    await tester.pumpAndSettle();
    await scroll(tester, 'hub-journal');
    expect(find.text(localeCurrency(0, 'en')), findsOneWidget);
    expect(snapshot(prefs), before);
    expect(tester.takeException(), isNull);
    await close(tester);
  });
  testWidgets('Night-to-day rollover and resume update the local daily key and ISO week', (tester) async {
    viewport(tester);
    var clock = DateTime(2027, 1, 3, 23, 59);
    SharedPreferences.setMockInitialValues(hubValues(clock));
    await tester.pumpWidget(app('en', PersonalHubPage(clock: () => clock)));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    clock = DateTime(2027, 1, 4, 0, 1);
    await prefs.setString(DailyMentiStore.key(clock), '{"mood":4}');
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    final s = appStrings(tester.element(find.byType(PersonalHubPage)));
    final date = DateFormat.yMMMd('en');
    expect(find.text(s.hubWeek(date.format(mentiMonday(clock)),
      date.format(mentiCalendarDay(mentiMonday(clock), 6)))), findsOneWidget);
    expect(find.byKey(const ValueKey('hub-reaction')), findsNothing);
    await prefs.setString(DailyMentiStore.key(clock), '{broken');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    await scroll(tester, 'hub-status-daily');
    expect(find.text(s.hubReadError), findsOneWidget);
    expect(prefs.getString(DailyMentiStore.key(clock)), '{broken');
    expect(tester.takeException(), isNull);
    await close(tester);
  });
  testWidgets('A slower obsolete load cannot replace a newer resumed snapshot', (tester) async {
    viewport(tester);
    final reader = _ControlledReader();
    await tester.pumpWidget(app('en', PersonalHubPage(reader: reader, clock: () => now)));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(reader.requests.length, 2);
    reader.requests[1].complete(PersonalHubSnapshot.fromValues(hubValues(now), now));
    await tester.pumpAndSettle();
    reader.requests[0].complete(PersonalHubSnapshot.fromValues({}, now));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('hub-status-profile')), findsNothing);
    expect(find.byType(MentiEvolution), findsOneWidget);
    expect(tester.takeException(), isNull);
    await close(tester);
  });
  testWidgets('Home opens one hub and back returns without preference writes', (tester) async {
    viewport(tester, 390);
    SharedPreferences.setMockInitialValues({adultAccessKey: adultAccessValue,...hubValues(DateTime.now()), 'mennyiment_locale_v1': 'en'});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(const MennyiMentApp());
    await tester.pumpAndSettle();
    final before = snapshot(prefs);
    await scroll(tester, 'open-personal-hub');
    final action = tester.widget<OutlinedButton>(find.byKey(const ValueKey('open-personal-hub'))).onPressed!;
    action();
    action();
    await tester.pumpAndSettle();
    expect(find.byType(PersonalHubPage), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(PersonalHubPage), findsNothing);
    expect(find.byType(HomePage), findsOneWidget);
    expect(snapshot(prefs), before);
    expect(tester.takeException(), isNull);
    await close(tester);
  });
}
