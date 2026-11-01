import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/app_language.dart';
import 'package:mennyiment/daily_menti_message.dart';
import 'package:mennyiment/daily_menti_store.dart';
import 'package:mennyiment/drink_journal_page.dart';
import 'package:mennyiment/home_widgets.dart';
import 'package:mennyiment/data_restore.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';
import 'package:mennyiment/main.dart';
import 'package:mennyiment/menti_evolution.dart';
import 'package:mennyiment/menti_experience_settings.dart';
import 'package:mennyiment/menti_intro.dart';
import 'package:mennyiment/menti_motion.dart';
import 'package:mennyiment/menti_reactions.dart';
import 'package:mennyiment/menti_settings_page.dart';
import 'package:mennyiment/menti_xp_store.dart';
import 'package:mennyiment/personal_goal_store.dart';
import 'package:mennyiment/personal_hub_data.dart';

import 'experience_preferences_test.dart' show experienceSnapshot;
import 'personal_hub_fixtures.dart';

class _RejectIntroSettings extends MentiExperienceSettings {
  @override
  Future<bool> markIntroSeen() async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 10, 25, 12);
  void viewport(WidgetTester tester, double width) {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }
  Widget app(String locale, Widget child, MentiExperienceSettings settings, {
    double scale = 1, bool reduced = true,
  }) => MaterialApp(
    locale: Locale(locale), supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(
      disableAnimations: reduced, textScaler: TextScaler.linear(scale)),
      child: MentiExperienceScope(settings: settings, child: MentiMotionScope(child: child!))),
    home: child,
  );
  Future<void> scroll(WidgetTester tester, String key, {bool up = false}) async {
    await tester.scrollUntilVisible(find.byKey(ValueKey(key)), up ? -250 : 250,
      scrollable: find.byType(Scrollable).first, maxScrolls: 80);
    await tester.pumpAndSettle();
  }
  Future<void> close(WidgetTester tester, MentiExperienceSettings? settings) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    settings?.dispose();
  }
  Widget introHost() => Builder(builder: (context) => Scaffold(body: FilledButton(
    key: const ValueKey('launch-intro'), onPressed: () => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const MentiIntroPage())), child: const Text('Open'))));

  for (final locale in ['hu', 'en']) {
    for (final width in [320.0, 360.0, 390.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('$locale intro $width px ${scale}x is optional and preserves all existing data', (tester) async {
          viewport(tester, width);
          final initial = hubValues(now);
          SharedPreferences.setMockInitialValues(initial);
          final settings = MentiExperienceSettings();
          await tester.pumpWidget(app(locale, introHost(), settings, scale: scale));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('launch-intro')));
          await tester.pumpAndSettle();
          for (var step = 0; step < 4; step++) {
            await scroll(tester, 'intro-step', up: true);
            final s = appStrings(tester.element(find.byType(MentiIntroPage)));
            expect(find.text(s.experienceIntroStep(step + 1, 4)), findsOneWidget);
            await scroll(tester, 'intro-next');
            expect(tester.takeException(), isNull);
            await tester.tap(find.byKey(const ValueKey('intro-next')));
            await tester.pumpAndSettle();
          }
          expect(find.byType(MentiIntroPage), findsNothing);
          expect(experienceSnapshot(await SharedPreferences.getInstance()), {
            ...initial, MentiExperienceSettings.introKey: true});
          await close(tester, settings);
        });
      }
      testWidgets('$locale settings $width px 200% keep OS motion priority and keyboard focus', (tester) async {
        viewport(tester, width);
        final initial = hubValues(now);
        SharedPreferences.setMockInitialValues(initial);
        final settings = MentiExperienceSettings();
        await tester.pumpWidget(app(locale, const MentiSettingsPage(), settings, scale: 2));
        await tester.pumpAndSettle();
        await scroll(tester, 'experience-reactions');
        await tester.tap(find.byKey(const ValueKey('experience-reactions')));
        await tester.pumpAndSettle();
        expect(settings.reactions, false);
        await scroll(tester, 'menti-reduce-motion');
        await tester.tap(find.byKey(const ValueKey('menti-reduce-motion')));
        await tester.pumpAndSettle();
        expect(MentiMotionScope.reducedOf(tester.element(find.byType(MentiSettingsPage))), true);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(FocusManager.instance.primaryFocus?.hasFocus, true);
        expect(experienceSnapshot(await SharedPreferences.getInstance()), {
          ...initial, MentiExperienceSettings.reactionsKey: false,
          MentiMotionSettings.preferenceKey: false});
        expect(tester.takeException(), isNull);
        await close(tester, settings);
      });
    }
    testWidgets('$locale intro cancellation does not save; skip and help reopen are explicit', (tester) async {
      viewport(tester, 390);
      final initial = hubValues(now);
      SharedPreferences.setMockInitialValues(initial);
      final settings = MentiExperienceSettings();
      await tester.pumpWidget(app(locale, introHost(), settings));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('launch-intro')));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(experienceSnapshot(await SharedPreferences.getInstance()), initial);
      await tester.tap(find.byKey(const ValueKey('launch-intro')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('intro-skip')));
      await tester.pumpAndSettle();
      expect(settings.introSeen, true);
      await tester.tap(find.byKey(const ValueKey('launch-intro')));
      await tester.pumpAndSettle();
      final s = appStrings(tester.element(find.byType(MentiIntroPage)));
      expect(find.text(s.experienceIntro1Title), findsOneWidget);
      expect(experienceSnapshot(await SharedPreferences.getInstance()), {
        ...initial, MentiExperienceSettings.introKey: true});
      expect(tester.takeException(), isNull);
      await close(tester, settings);
    });
  }

  testWidgets('An unconfirmed intro dismissal stays open and does not touch data', (tester) async {
    viewport(tester, 390);
    final initial = hubValues(now);
    SharedPreferences.setMockInitialValues(initial);
    final settings = _RejectIntroSettings();
    await tester.pumpWidget(app('en', introHost(), settings));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('launch-intro')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('intro-skip')));
    await tester.pumpAndSettle();
    final s = appStrings(tester.element(find.byType(MentiIntroPage)));
    expect(find.text(s.experienceSaveError), findsOneWidget);
    expect(experienceSnapshot(await SharedPreferences.getInstance()), initial);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(MentiIntroPage), findsNothing);
    await close(tester, settings);
  });

  testWidgets('Fresh root offers an invitation, existing data and failed recovery never force intro', (tester) async {
    viewport(tester, 390);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MennyiMentApp());
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(MentiIntroPage), findsNothing);
    await scroll(tester, 'open-intro-invite');
    await tester.tap(find.byKey(const ValueKey('open-intro-invite')));
    await tester.pumpAndSettle();
    expect(find.byType(MentiIntroPage), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect((await SharedPreferences.getInstance()).containsKey(MentiExperienceSettings.introKey), false);
    await close(tester, null);
    final initial = {...hubValues(now), 'mennyiment_character_setup_complete_v1': false};
    SharedPreferences.setMockInitialValues(initial);
    await tester.pumpWidget(const MennyiMentApp());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('open-intro-invite')), findsNothing);
    expect(experienceSnapshot(await SharedPreferences.getInstance()), initial);
    await tester.tap(find.byKey(const ValueKey('open-menti-settings')));
    await tester.pumpAndSettle();
    await scroll(tester, 'settings-open-intro');
    await tester.tap(find.byKey(const ValueKey('settings-open-intro')));
    await tester.pumpAndSettle();
    expect(find.byType(MentiIntroPage), findsOneWidget);
    await close(tester, null);
    SharedPreferences.setMockInitialValues({BackupRestorer.recoveryKey: 'broken',
      'mennyiment_menti_progress_v1': '{"xp":70}'});
    await tester.pumpWidget(const MennyiMentApp());
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsNothing);
    expect(find.byType(MentiExperienceScope), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(MentiExperienceSettings.introKey), false);
    expect(prefs.containsKey(MentiXpStore.currentKey), false);
    await close(tester, null);
  });

  testWidgets('Missing journal and a saved empty journal stay distinct on home and journal routes', (tester) async {
    viewport(tester, 390);
    final initial = hubValues(now)..remove('mennyiment_drinks_v1');
    SharedPreferences.setMockInitialValues(initial);
    await tester.pumpWidget(const MennyiMentApp());
    await tester.pumpAndSettle();
    await scroll(tester, 'home-journal-missing');
    expect(find.byType(HomeStatTile), findsNothing);
    final s = appStrings(tester.element(find.byType(HomePage)));
    await tester.tap(find.byKey(const ValueKey('nav-journal')));
    await tester.pumpAndSettle();
    expect(tester.widget<DrinkJournalPage>(find.byType(DrinkJournalPage)).hasSavedJournal, false);
    expect(find.text(s.hubMissing), findsOneWidget);
    expect(experienceSnapshot(await SharedPreferences.getInstance()), initial);
    await close(tester, null);
    SharedPreferences.setMockInitialValues({...initial, 'mennyiment_drinks_v1': '[]'});
    await tester.pumpWidget(const MennyiMentApp());
    await tester.pumpAndSettle();
    await scroll(tester, 'daily-menti-mini-card');
    await tester.scrollUntilVisible(find.byType(HomeStatTile).first, 250,
      scrollable: find.byType(Scrollable).first, maxScrolls: 40);
    expect(find.byType(HomeStatTile), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('nav-journal')));
    await tester.pumpAndSettle();
    expect(tester.widget<DrinkJournalPage>(find.byType(DrinkJournalPage)).hasSavedJournal, true);
    expect(find.text(s.experienceEmptyJournal), findsOneWidget);
    expect(tester.takeException(), isNull);
    await close(tester, null);
  });

  testWidgets('Disabling reactions hides an event without replay; new events and motion are finite', (tester) async {
    viewport(tester, 390);
    final initial = {...hubValues(now), MentiMotionSettings.preferenceKey: false};
    SharedPreferences.setMockInitialValues(initial);
    final settings = MentiExperienceSettings();
    var token = 1;
    late StateSetter update;
    await tester.pumpWidget(app('en', StatefulBuilder(builder: (context, setState) {
      update = setState;
      return Scaffold(body: Column(children: [
        MentiEvolution(size: 90, assetPath: 'assets/images/menti_outfits/alap.png'),
        MentiReactionCard(mood: MentiMood.personalGoalCompleted, eventToken: token),
      ]));
    }), settings, reduced: false));
    await tester.pumpAndSettle();
    final message = MentiReactions.message(MentiMood.personalGoalCompleted, locale: 'en');
    expect(find.text(message), findsOneWidget);
    expect(tester.hasRunningAnimations, false);
    await settings.setReactions(false);
    await tester.pumpAndSettle();
    expect(find.text(message), findsNothing);
    await settings.setReactions(true);
    await tester.pumpAndSettle();
    expect(find.text(message), findsNothing);
    update(() => token++);
    await tester.pumpAndSettle();
    expect(find.text(message), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    expect(tester.hasRunningAnimations, false);
    expect(experienceSnapshot(await SharedPreferences.getInstance()), {
      ...initial, MentiExperienceSettings.reactionsKey: true});
    expect(tester.takeException(), isNull);
    await close(tester, settings);
  });

  test('Daily context uses only recorded evidence and is stable across DST and ISO week changes', () {
    final blank = PersonalHubSnapshot.fromValues({}, now);
    expect(DailyMentiMessage.context(blank), DailyMentiContext.invitation);
    final answers = PersonalHubSnapshot.fromValues({DailyMentiStore.key(now): '{"mood":3}'}, now);
    expect(DailyMentiMessage.context(answers), DailyMentiContext.answers);
    final checked = PersonalHubSnapshot.fromValues({MentiXpStore.currentKey:
      '{"xp":10,"days":["2026-10-25"]}'}, now);
    expect(DailyMentiMessage.context(checked), DailyMentiContext.checked);
    final goal = PersonalHubSnapshot.fromValues({PersonalGoalStore.key:
      '{"reflectionGoal":1,"reflectionDays":["2026-10-25"]}'}, now);
    expect(DailyMentiMessage.context(goal), DailyMentiContext.personalGoal);
    final unknown = PersonalHubSnapshot.fromValues({MentiXpStore.currentKey: '{broken'}, now);
    expect(DailyMentiMessage.context(unknown), DailyMentiContext.unavailable);
    final monday = PersonalHubSnapshot.fromValues({PersonalGoalStore.key:
      '{"reflectionGoal":1,"reflectionDays":["2026-10-25"]}'}, DateTime(2026, 10, 26));
    expect(DailyMentiMessage.context(monday), DailyMentiContext.invitation);
    if (Platform.environment['TZ'] == 'Europe/Budapest') {
      for (final time in [DateTime.utc(2026, 10, 25, 0, 30), DateTime.utc(2026, 10, 25, 1, 30)]) {
        expect(DailyMentiMessage.context(PersonalHubSnapshot.fromValues({MentiXpStore.currentKey:
          '{"xp":10,"days":["2026-10-25"]}'}, time)), DailyMentiContext.checked);
      }
    }
    expect(DailyMentiMessage.context(PersonalHubSnapshot.fromValues({PersonalGoalStore.key:
      '{"reflectionGoal":1,"reflectionDays":["2026-12-31"]}'}, DateTime(2027, 1, 3))), DailyMentiContext.personalGoal);
  });

  testWidgets('Daily mini-card stays stable on rebuild and re-reads after day/resume without writes', (tester) async {
    viewport(tester, 390);
    var clock = DateTime(2027, 1, 3, 23, 59);
    SharedPreferences.setMockInitialValues({});
    final settings = MentiExperienceSettings();
    late StateSetter update;
    var unrelated = 0;
    await tester.pumpWidget(app('en', StatefulBuilder(builder: (_, setState) {
      update = setState;
      return Scaffold(body: ListView(children: [Text('$unrelated'),
        DailyMentiMiniCard(clock: () => clock, onOpenDaily: () {}, onOpenHub: () {})]));
    }), settings));
    await tester.pumpAndSettle();
    final first = tester.widget<Text>(find.byKey(const ValueKey('daily-menti-message'))).data;
    update(() => unrelated++);
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(const ValueKey('daily-menti-message'))).data, first);
    final prefs = await SharedPreferences.getInstance();
    expect(experienceSnapshot(prefs), isEmpty);
    clock = DateTime(2027, 1, 4, 0, 1);
    await prefs.setString(DailyMentiStore.key(clock), jsonEncode({'energy': 4}));
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    final s = appStrings(tester.element(find.byType(DailyMentiMiniCard)));
    expect(find.text(s.experienceTodayAnswers), findsOneWidget);
    expect(experienceSnapshot(prefs), {DailyMentiStore.key(clock): '{"energy":4}'});
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text(s.experienceTodayAnswers), findsOneWidget);
    expect(tester.takeException(), isNull);
    await close(tester, settings);
  });
}
