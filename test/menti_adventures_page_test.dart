import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';
import 'package:mennyiment/menti_access.dart';
import 'package:mennyiment/menti_adventure_store.dart';
import 'package:mennyiment/menti_adventures.dart';
import 'package:mennyiment/menti_design.dart';
import 'package:mennyiment/menti_identity/menti_avatar_renderer.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(initializeDateFormatting);
  late DateTime now;
  late AdventureStore store;
  late MentiAccessSettings access;
  int wellbeingOpens = 0, goalOpens = 0;
  setUp(() {
    now = DateTime(2026, 11, 12, 10);
    SharedPreferences.setMockInitialValues({
      MentiAccessSettings.key:
          '{"version":1,"audience":"adult","complete":true}',
    });
    store = AdventureStore(clock: () => now);
    access = MentiAccessSettings();
    wellbeingOpens = 0;
    goalOpens = 0;
  });

  Future<void> show(
    WidgetTester t, {
    String locale = 'hu',
    double width = 390,
    double scale = 1,
    bool reduced = true,
  }) async {
    t.view.physicalSize = Size(width, 700);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(t.view.resetViewInsets);
    await access.load();
    await t.pumpWidget(
      MaterialApp(
        theme: MentiDesign.theme,
        locale: Locale(locale),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (c, child) => MentiAccessScope(
          settings: access,
          child: MediaQuery(
            data: MediaQuery.of(c).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: reduced,
            ),
            child: child!,
          ),
        ),
        home: MentiAdventuresPage(
          store: store,
          clock: () => now,
          onWellbeing: () async {
            wellbeingOpens++;
          },
          onGoals: () async {
            goalOpens++;
          },
        ),
      ),
    );
    await t.pumpAndSettle();
    addTearDown(() async {
      await t.pumpWidget(const SizedBox.shrink());
      await t.pumpAndSettle();
      access.dispose();
    });
  }

  Future<void> reveal(WidgetTester t, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      final list = find.byType(ListView).first;
      await t.drag(list, const Offset(0, 20000));
      await t.pumpAndSettle();
      await t.scrollUntilVisible(
        finder,
        180,
        scrollable: find
            .descendant(of: list, matching: find.byType(Scrollable))
            .first,
        maxScrolls: 60,
      );
    }
    await t.ensureVisible(finder);
    await t.pumpAndSettle();
  }

  Future<void> tap(WidgetTester t, Finder finder) async {
    await reveal(t, finder);
    await t.pumpAndSettle();
    await t.tap(finder);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  }

  Finder key(String value) => find.byKey(ValueKey(value));

  for (final locale in ['hu', 'en']) {
    for (final width in [320.0, 360.0, 390.0, 430.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          '$locale $width/$scale: choose, cancel dialog, complete three, map and badges with keyboard',
          (t) async {
            await show(t, locale: locale, width: width, scale: scale);
            final s = lookupAppLocalizations(Locale(locale));
            await tap(t, key('adventure-select-movement'));
            await tap(t, key('adventure-complete-movement'));
            await tap(t, find.text(s.adventureLater));
            expect(store.document.completedCount(now), 0);
            expect(
              store.document.status(now, AdventureTask.movement),
              'active',
            );
            await tap(t, key('adventure-complete-movement'));
            await tap(t, key('adventure-confirm'));
            expect(store.document.completedCount(now), 1);
            await t.pump(const Duration(seconds: 6));
            await t.pumpAndSettle();
            expect(key('adventure-dismiss-feedback'), findsNothing);
            await tap(t, key('adventure-select-rest'));
            await tap(t, key('adventure-complete-rest'));
            await tap(t, key('adventure-confirm'));
            await t.pump(const Duration(seconds: 6));
            await t.pumpAndSettle();
            await tap(t, key('adventure-select-decision'));
            await tap(t, key('adventure-complete-decision'));
            t.view.viewInsets = const FakeViewPadding(bottom: 260);
            await t.pumpAndSettle();
            await t.enterText(key('adventure-note'), 'I took a quiet break.');
            await tap(t, key('adventure-confirm'));
            t.view.resetViewInsets();
            await t.pumpAndSettle();
            expect(store.document.completedCount(now), 3);
            expect(store.document.badges.length, 3);
            await t.pump(const Duration(seconds: 6));
            await t.pumpAndSettle();
            await tap(t, find.text(s.adventureMap));
            expect(find.text(s.adventureProgress(3, 21)), findsOneWidget);
            await reveal(t, find.text(s.adventureStationDone));
            expect(find.text(s.adventureStationDone), findsOneWidget);
            await reveal(t, find.text(s.adventureStationCurrent));
            expect(find.text(s.adventureStationCurrent), findsOneWidget);
            expect(find.byType(MentiCurrentAvatar), findsOneWidget);
            await tap(t, find.text(s.adventureBadges));
            for (final id in adventureBadges) {
              await reveal(t, key('adventure-badge-$id'));
              expect(
                find.descendant(
                  of: key('adventure-badge-$id'),
                  matching: find.textContaining(
                    locale == 'hu' ? 'Megszerzés napja' : 'Earned on',
                  ),
                ),
                findsOneWidget,
              );
              expect(
                find.descendant(
                  of: key('adventure-badge-$id'),
                  matching: find.text(s.adventureLocked),
                ),
                findsNothing,
              );
            }
            expect(t.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets(
    'Cancel a commitment frees a slot; dismissing confirmation does not cancel it',
    (t) async {
      await show(t, locale: 'en');
      await tap(t, key('adventure-select-rest'));
      final before = store.document.encode();
      await tap(t, key('adventure-cancel-rest'));
      await tap(t, find.text('Cancel').last);
      expect(store.document.encode(), before);
      await tap(t, key('adventure-cancel-rest'));
      await tap(t, key('adventure-confirm'));
      expect(store.document.status(now, AdventureTask.rest), 'cancelled');
      expect(store.document.occupied(now), 0);
      await tap(t, key('adventure-select-rest'));
      expect(store.document.status(now, AdventureTask.rest), 'active');
    },
  );

  testWidgets(
    'Opening wellbeing alone never completes; a real saved today entry is verified',
    (t) async {
      await show(t, locale: 'en');
      await tap(t, key('adventure-select-wellbeing'));
      await tap(t, key('adventure-open-wellbeing'));
      expect(wellbeingOpens, 1);
      await tap(t, key('adventure-complete-wellbeing'));
      expect(store.document.completedCount(now), 0);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'mennyiment_wellbeing_v1',
        jsonEncode([
          {
            'day': '2026-11-12T00:00:00.000',
            'mood': 3,
            'sleep': 3,
            'hangover': 0,
          },
        ]),
      );
      await tap(t, key('adventure-complete-wellbeing'));
      expect(store.document.completedCount(now), 1);
    },
  );

  testWidgets(
    'Minor sees only general wellbeing tasks, with no adult goal route',
    (t) async {
      SharedPreferences.setMockInitialValues({
        MentiAccessSettings.key:
            '{"version":1,"audience":"minor","complete":true}',
      });
      await show(t, locale: 'en', width: 320, scale: 2);
      expect(key('adventure-select-goal'), findsNothing);
      expect(key('adventure-open-goal'), findsNothing);
      await reveal(t, key('adventure-select-rest'));
      expect(key('adventure-select-rest'), findsOneWidget);
      await reveal(t, key('adventure-select-wellbeing'));
      expect(key('adventure-select-wellbeing'), findsOneWidget);
      expect(goalOpens, 0);
    },
  );

  testWidgets('Live local midnight reloads today without changing yesterday', (
    t,
  ) async {
    now = DateTime(2026, 3, 28, 23, 59);
    await show(t, locale: 'en');
    await tap(t, key('adventure-select-rest'));
    final yesterday = now;
    now = DateTime(2026, 3, 29, 0, 0);
    await t.pump(const Duration(minutes: 1));
    await t.pumpAndSettle();
    await reveal(t, key('adventure-select-rest'));
    expect(key('adventure-select-rest'), findsOneWidget);
    expect(store.document.occupied(now), 0);
    expect(store.document.status(yesterday, AdventureTask.rest), 'active');
  });

  testWidgets(
    'Corrupt state has a readable recovery message and no writable controls',
    (t) async {
      SharedPreferences.setMockInitialValues({
        AdventureStore.key: '{"version":2}',
      });
      await show(t, locale: 'en', width: 320, scale: 2);
      expect(find.textContaining('unreadable'), findsOneWidget);
      expect(key('adventure-select-rest'), findsNothing);
      expect(
        (await SharedPreferences.getInstance()).getString(AdventureStore.key),
        '{"version":2}',
      );
    },
  );

  testWidgets(
    'Reopen and reduced motion do not replay completed celebrations',
    (t) async {
      await store.load();
      await store.select(now, AdventureTask.rest);
      await store.complete(now, AdventureTask.rest);
      await show(t, locale: 'en', reduced: true);
      expect(key('adventure-dismiss-feedback'), findsNothing);
      expect(key('adventure-complete-rest'), findsNothing);
      expect(store.document.completedCount(now), 1);
    },
  );

  testWidgets(
    'Normal motion feedback can be skipped and does not write another reward',
    (t) async {
      await show(t, locale: 'en', reduced: false);
      await tap(t, key('adventure-select-rest'));
      await tap(t, key('adventure-complete-rest'));
      await tap(t, key('adventure-confirm'));
      final before = store.document.encode();
      expect(key('adventure-dismiss-feedback'), findsOneWidget);
      await tap(t, key('adventure-dismiss-feedback'));
      expect(key('adventure-dismiss-feedback'), findsNothing);
      expect(store.document.encode(), before);
    },
  );
}
