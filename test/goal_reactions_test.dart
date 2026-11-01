import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/app_language.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';
import 'package:mennyiment/menti_reactions.dart';
import 'package:mennyiment/personal_goal_store.dart';
import 'package:mennyiment/personal_goals.dart';
import 'package:mennyiment/weekly_challenges.dart';

class _FailedPersonalStore extends PersonalGoalStore {
  @override
  Future<bool> update(Map<String, dynamic> changes) async => false;
}

class _FailedChallengeStore extends ChallengeStore {
  @override
  Future<bool> put(DateTime day, String id, Map<String, dynamic> item) async => false;
}

class _DelayedPersonalStore extends PersonalGoalStore {
  final gate = Completer<void>();
  @override
  Future<bool> update(Map<String, dynamic> changes) async {
    final result = await super.update(changes);
    await gate.future;
    return result;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final sunday = DateTime(2026, 10, 25, 12);
  const xp = 'unchanged XP sentinel';
  const journal = 'unchanged drink journal sentinel';
  Map<String, Object> seed({int target = 2, List<String>? days}) => {
    'mennyiment_menti_xp_v2': xp,
    'mennyiment_drinks_v1': journal,
    'mennyiment_outfit_v2': 'Legendás szett',
    'mennyiment_menti_rewards_v1': <String>['future:keep'],
    PersonalGoalStore.key: jsonEncode({'reflectionGoal': target,
      'reflectionDays': days ?? ['2026-10-24'], 'future': {'keep': true}}),
    ChallengeStore.key: jsonEncode({'version': 1, 'future': true, 'weeks': {
      '2026-10-19': {'reflection': {'goal': target, 'status': 'active',
        'title': '', 'days': days ?? ['2026-10-24'], 'future': 42}},
    }}),
  };
  Future<void> mount(WidgetTester tester, String locale, Widget page, {double scale = 1}) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      locale: Locale(locale),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true,
          textScaler: TextScaler.linear(scale)), child: child!),
      home: page,
    ));
    await tester.pumpAndSettle();
  }
  Future<void> scroll(WidgetTester tester, Finder finder, {bool up = false}) async {
    await tester.scrollUntilVisible(finder, up ? -250 : 250,
      scrollable: find.byType(Scrollable).first, maxScrolls: 60);
    await tester.pumpAndSettle();
  }
  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }
  Future<void> unchanged() async {
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('mennyiment_menti_xp_v2'), xp);
    expect(prefs.getString('mennyiment_drinks_v1'), journal);
    expect(prefs.getString('mennyiment_outfit_v2'), 'Legendás szett');
    expect(prefs.getStringList('mennyiment_menti_rewards_v1'), ['future:keep']);
  }

  for (final locale in ['hu', 'en']) {
    testWidgets('$locale personal goal celebrates confirmed crossing once, at 320px/200%', (tester) async {
      SharedPreferences.setMockInitialValues(seed());
      await mount(tester, locale, PersonalGoalsPage(drinks: const [], clock: () => sunday), scale: 2);
      expect(find.byKey(const ValueKey('personal-goal-reaction')), findsNothing);
      final button = find.byKey(const ValueKey('personal-goal-check-in'));
      await scroll(tester, button);
      final action = tester.widget<FilledButton>(button).onPressed!;
      action();
      action();
      await tester.pumpAndSettle();
      final bubble = find.byKey(const ValueKey('personal-goal-reaction'));
      await scroll(tester, bubble, up: true);
      expect(tester.widget<MentiSpeechBubble>(bubble).message,
        MentiReactions.message(MentiMood.personalGoalCompleted, locale: locale));
      final prefs = await SharedPreferences.getInstance();
      final data = jsonDecode(prefs.getString(PersonalGoalStore.key)!) as Map;
      expect(data['reflectionDays'], ['2026-10-24', '2026-10-25']);
      expect(data['future'], {'keep': true});
      await unchanged();
      final s = appStrings(tester.element(find.byType(PersonalGoalsPage)));
      await scroll(tester, find.text(s.goalReload));
      await tester.tap(find.text(s.goalReload));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('personal-goal-reaction')), findsNothing);
      // Reload can retain the bottom scroll offset; the check-in is above it.
      await scroll(tester, button, up: true);
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      expect(tester.takeException(), isNull);
      await close(tester);
    });

    testWidgets('$locale failed personal save leaves count and data unchanged', (tester) async {
      final initial = seed();
      SharedPreferences.setMockInitialValues(initial);
      await mount(tester, locale, PersonalGoalsPage(drinks: const [],
        store: _FailedPersonalStore(), clock: () => sunday));
      final s = appStrings(tester.element(find.byType(PersonalGoalsPage)));
      await scroll(tester, find.byKey(const ValueKey('personal-goal-check-in')));
      await tester.tap(find.byKey(const ValueKey('personal-goal-check-in')));
      await tester.pumpAndSettle();
      expect(find.text(s.goalSaveError), findsOneWidget);
      expect(find.text(s.goalProgress(1, 2)), findsOneWidget);
      expect(find.byKey(const ValueKey('personal-goal-reaction')), findsNothing);
      expect((await SharedPreferences.getInstance()).getString(PersonalGoalStore.key), initial[PersonalGoalStore.key]);
      await unchanged();
      expect(tester.takeException(), isNull);
      await close(tester);
    });

    testWidgets('$locale lowering a personal target does not invent a new event', (tester) async {
      SharedPreferences.setMockInitialValues(seed());
      await mount(tester, locale, PersonalGoalsPage(drinks: const [], clock: () => sunday));
      final s = appStrings(tester.element(find.byType(PersonalGoalsPage)));
      await scroll(tester, find.text(s.goalEditTarget));
      await tester.tap(find.text(s.goalEditTarget));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '1');
      await tester.tap(find.text(s.challengeSave));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('personal-goal-reaction')), findsNothing);
      expect(jsonDecode((await SharedPreferences.getInstance()).getString(PersonalGoalStore.key)!)['reflectionGoal'], 1);
      await unchanged();
      expect(tester.takeException(), isNull);
      await close(tester);
    });

    testWidgets('$locale corrupt personal data stays protected and retryable', (tester) async {
      SharedPreferences.setMockInitialValues({...seed(), PersonalGoalStore.key: '{broken'});
      await mount(tester, locale, PersonalGoalsPage(drinks: const [], clock: () => sunday));
      expect(find.byKey(const ValueKey('personal-goals-error')), findsOneWidget);
      expect(find.byKey(const ValueKey('personal-goal-check-in')), findsNothing);
      expect((await SharedPreferences.getInstance()).getString(PersonalGoalStore.key), '{broken');
      await unchanged();
      expect(tester.takeException(), isNull);
      await close(tester);
    });

    testWidgets('$locale manual weekly completion celebrates only after save', (tester) async {
      SharedPreferences.setMockInitialValues(seed());
      await mount(tester, locale, WeeklyChallengesPage(clock: () => sunday));
      final s = appStrings(tester.element(find.byType(WeeklyChallengesPage)));
      expect(find.byKey(const ValueKey('challenge-reaction')), findsNothing);
      await tester.tap(find.text(s.challengeDoneToday).first);
      await tester.pumpAndSettle();
      final bubble = find.byKey(const ValueKey('challenge-reaction'));
      expect(tester.widget<MentiSpeechBubble>(bubble).message,
        MentiReactions.message(MentiMood.challengeCompleted, locale: locale));
      final prefs = await SharedPreferences.getInstance();
      final data = jsonDecode(prefs.getString(ChallengeStore.key)!) as Map;
      expect(data['future'], true);
      expect(data['weeks']['2026-10-19']['reflection']['future'], 42);
      await unchanged();
      await scroll(tester, find.text(s.challengeRefresh));
      await tester.tap(find.text(s.challengeRefresh));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('challenge-reaction')), findsNothing);
      expect(tester.takeException(), isNull);
      await close(tester);
    });

    testWidgets('$locale completed or stopped challenges do not celebrate on opening or stopping', (tester) async {
      SharedPreferences.setMockInitialValues(seed(target: 1));
      await mount(tester, locale, WeeklyChallengesPage(clock: () => sunday));
      final s = appStrings(tester.element(find.byType(WeeklyChallengesPage)));
      expect(find.byKey(const ValueKey('challenge-reaction')), findsNothing);
      await tester.tap(find.text(s.challengeStop).first);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('challenge-reaction')), findsNothing);
      await unchanged();
      expect(tester.takeException(), isNull);
      await close(tester);
    });

    testWidgets('$locale a personal save finishing in a new week cannot celebrate the old week', (tester) async {
      var clock = sunday;
      final store = _DelayedPersonalStore();
      SharedPreferences.setMockInitialValues(seed());
      await mount(tester, locale, PersonalGoalsPage(drinks: const [], store: store, clock: () => clock));
      final button = find.byKey(const ValueKey('personal-goal-check-in'));
      await scroll(tester, button);
      await tester.tap(button);
      await tester.pump();
      clock = DateTime(2026, 10, 26, 0, 1);
      store.gate.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('personal-goal-reaction')), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(jsonDecode(prefs.getString(PersonalGoalStore.key)!)['reflectionDays'], ['2026-10-24', '2026-10-25']);
      await unchanged();
      expect(tester.takeException(), isNull);
      await close(tester);
    });

    testWidgets('$locale unconfirmed challenge write cannot celebrate', (tester) async {
      final initial = seed();
      SharedPreferences.setMockInitialValues(initial);
      await mount(tester, locale, WeeklyChallengesPage(store: _FailedChallengeStore(), clock: () => sunday));
      final s = appStrings(tester.element(find.byType(WeeklyChallengesPage)));
      await tester.tap(find.text(s.challengeDoneToday).first);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('challenge-reaction')), findsNothing);
      expect(find.text(s.challengeSaveError), findsOneWidget);
      expect((await SharedPreferences.getInstance()).getString(ChallengeStore.key), initial[ChallengeStore.key]);
      await unchanged();
      expect(tester.takeException(), isNull);
      await close(tester);
    });

    testWidgets('$locale refreshed wellbeing evidence can complete an existing journal challenge', (tester) async {
      final base = seed();
      base[ChallengeStore.key] = jsonEncode({'version': 1, 'weeks': {
        '2026-10-19': {'journal': {'goal': 2, 'status': 'active', 'title': '', 'days': []}},
      }});
      base['mennyiment_wellbeing_v1'] = jsonEncode([{'day': '2026-10-24T00:00:00.000'}]);
      SharedPreferences.setMockInitialValues(base);
      await mount(tester, locale, WeeklyChallengesPage(clock: () => sunday));
      expect(find.byKey(const ValueKey('challenge-reaction')), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mennyiment_wellbeing_v1', jsonEncode([
        {'day': '2026-10-24T00:00:00.000'}, {'day': '2026-10-25T00:00:00.000'},
      ]));
      final s = appStrings(tester.element(find.byType(WeeklyChallengesPage)));
      await scroll(tester, find.text(s.challengeRefresh));
      await tester.tap(find.text(s.challengeRefresh));
      await tester.pumpAndSettle();
      await scroll(tester, find.byKey(const ValueKey('challenge-reaction')), up: true);
      expect(find.byKey(const ValueKey('challenge-reaction')), findsOneWidget);
      expect(prefs.getString(ChallengeStore.key), base[ChallengeStore.key]);
      await unchanged();
      expect(tester.takeException(), isNull);
      await close(tester);
    });
  }
}
