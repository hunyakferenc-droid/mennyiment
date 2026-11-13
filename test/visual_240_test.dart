import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/drink_journal.dart';
import 'package:mennyiment/main.dart' show MennyiMentApp;
import 'package:mennyiment/menti_access.dart';
import 'package:mennyiment/drink_journal_page.dart';
import 'package:mennyiment/home_adventure_summary.dart';
import 'package:mennyiment/journal_query.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';
import 'package:mennyiment/menti_adventure_store.dart';
import 'package:mennyiment/menti_design.dart';
import 'package:mennyiment/menti_identity/menti_studio_page.dart';

void main() {
  setUpAll(initializeDateFormatting);
  final day = DateTime(2026, 11, 13, 12);
  final raw = jsonEncode({
    'version': 1,
    'days': {
      '2026-11-13': {
        'movement': {
          'status': 'active',
          'selectedAt': '2026-11-13T08:00:00.000Z',
          'future': 'keep',
        },
      },
    },
    'badges': {},
    'future': [true, 'raw'],
  });
  setUp(
    () => SharedPreferences.setMockInitialValues({AdventureStore.key: raw}),
  );
  Future<void> show(
    WidgetTester t,
    Widget child,
    String locale,
    double width,
    double scale,
  ) async {
    t.view.physicalSize = Size(width, 740);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(t.view.resetViewInsets);
    addTearDown(() async {
      await t.pumpWidget(const SizedBox.shrink());
      await t.pumpAndSettle();
    });
    await t.pumpWidget(
      MaterialApp(
        theme: MentiDesign.theme,
        locale: Locale(locale),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (c, child) => MediaQuery(
          data: MediaQuery.of(c).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: child,
      ),
    );
    await t.pumpAndSettle();
  }

  Future<void> toggle(WidgetTester t) async {
    final scroll = find.byType(Scrollable).first;
    t.state<ScrollableState>(scroll).position.jumpTo(0);
    await t.pumpAndSettle();
    final key = find.byKey(const ValueKey('journal-filter-toggle'));
    await t.ensureVisible(key);
    await t.pumpAndSettle();
    await t.tap(key);
    await t.pumpAndSettle();
  }

  for (final locale in ['hu', 'en']) {
    for (final width in [320.0, 360.0, 390.0, 430.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          '$locale $width/$scale: collapsed filters, active chips, keyboard and zero/missing remain independent',
          (t) async {
            final s = lookupAppLocalizations(Locale(locale));
            final records = [
              Drink('Tea', 250, 0, time: day, priceFt: 0),
              Drink('Tea', 300, 0, time: day),
            ];
            final before = jsonEncode(records.map((d) => d.toJson()).toList());
            await show(
              t,
              DrinkJournalPage(drinks: records, clock: () => day),
              locale,
              width,
              scale,
            );
            final semantics = t.ensureSemantics();
            try {
              expect(find.bySemanticsLabel(s.journalSearch), findsOneWidget);
            } finally {
              semantics.dispose();
            }
            expect(
              find.byType(DropdownButtonFormField<JournalPrice>),
              findsNothing,
            );
            expect(
              find.byKey(const ValueKey('journal-search')),
              findsOneWidget,
            );
            await toggle(t);
            t
                .widget<DropdownButtonFormField<JournalPrice>>(
                  find.byType(DropdownButtonFormField<JournalPrice>),
                )
                .onChanged!(JournalPrice.missing);
            t
                .widget<DropdownButtonFormField<JournalOrder>>(
                  find.byType(DropdownButtonFormField<JournalOrder>),
                )
                .onChanged!(JournalOrder.oldest);
            await t.pumpAndSettle();
            await toggle(t);
            expect(
              find.byType(DropdownButtonFormField<JournalPrice>),
              findsNothing,
            );
            expect(
              find.widgetWithText(InputChip, s.journalMissingPrices),
              findsOneWidget,
            );
            expect(
              find.widgetWithText(InputChip, s.journalOldest),
              findsOneWidget,
            );
            t
                .widget<InputChip>(
                  find.widgetWithText(InputChip, s.journalMissingPrices),
                )
                .onDeleted!();
            await t.pumpAndSettle();
            expect(
              find.widgetWithText(InputChip, s.journalOldest),
              findsOneWidget,
            );
            expect(
              find.widgetWithText(InputChip, s.journalMissingPrices),
              findsNothing,
            );
            await toggle(t);
            expect(
              t
                  .widget<DropdownButtonFormField<JournalPrice>>(
                    find.byType(DropdownButtonFormField<JournalPrice>),
                  )
                  .initialValue,
              JournalPrice.all,
            );
            expect(
              t
                  .widget<DropdownButtonFormField<JournalOrder>>(
                    find.byType(DropdownButtonFormField<JournalOrder>),
                  )
                  .initialValue,
              JournalOrder.oldest,
            );
            t.view.viewInsets = const FakeViewPadding(bottom: 280);
            await t.pumpAndSettle();
            await t.enterText(
              find.byKey(const ValueKey('journal-search')),
              'tea',
            );
            await t.pumpAndSettle();
            expect(t.takeException(), isNull);
            expect(jsonEncode(records.map((d) => d.toJson()).toList()), before);
          },
        );
      }
    }
  }
  for (final locale in ['hu', 'en']) {
    for (final width in [320.0, 360.0, 390.0, 430.0]) {
      testWidgets(
        '$locale $width: Studio controls and preview at 200 percent with keyboard',
        (t) async {
          final s = lookupAppLocalizations(Locale(locale));
          await show(t, const MentiStudioPage(), locale, width, 2);
          final save = find.byKey(const ValueKey('studio-save')),
              undo = find.byKey(const ValueKey('studio-revert'));
          expect(save.hitTestable(), findsOneWidget);
          expect(undo.hitTestable(), findsOneWidget);
          expect(find.text(s.visualUndo), findsOneWidget);
          expect(find.text('Menti Studio'), findsOneWidget);
          t.view.viewInsets = const FakeViewPadding(bottom: 240);
          await t.pumpAndSettle();
          expect(save.hitTestable(), findsOneWidget);
          expect(t.getRect(save).bottom, lessThanOrEqualTo(500));
          expect(t.getRect(save).bottom, lessThanOrEqualTo(500));
          expect(t.takeException(), isNull);
        },
      );
    }
  }
  for (final locale in ['hu', 'en']) {
    testWidgets(
      '$locale: home reads the exact active task and refreshes without writes',
      (t) async {
        final s = lookupAppLocalizations(Locale(locale));
        var opens = 0;
        Widget card(int revision) => Scaffold(
          body: ListView(
            children: [
              HomeAdventureSummary(
                refreshToken: revision,
                clock: () => day,
                onOpen: () => opens++,
              ),
            ],
          ),
        );
        await show(t, card(0), locale, 320, 2);
        expect(find.text(s.adventureMovement), findsOneWidget);
        expect(find.text(s.adventureSlots(1)), findsOneWidget);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(AdventureStore.key), raw);
        await prefs.setString(
          AdventureStore.key,
          '{"version":99,"future":"preserve"}',
        );
        await show(t, card(1), locale, 320, 2);
        expect(
          find.byKey(const ValueKey('home-adventure-unavailable')),
          findsOneWidget,
        );
        expect(find.text(s.adventureSlots(0)), findsNothing);
        expect(find.text(s.visualNoActive), findsNothing);
        await t.ensureVisible(find.byKey(const ValueKey('open-adventures')));
        await t.pumpAndSettle();
        await t.tap(find.byKey(const ValueKey('open-adventures')));
        expect(opens, 1);
        expect(
          prefs.getString(AdventureStore.key),
          '{"version":99,"future":"preserve"}',
        );
      },
    );
  }
  for (final adult in [true, false]) {
    test(
      'Next activity is selected time order, with the existing minor restriction: $adult',
      () {
        final document = AdventureDocument.decode(
          jsonEncode({
            'version': 1,
            'badges': {},
            'days': {
              '2026-11-13': {
                'wellbeing': {
                  'status': 'active',
                  'selectedAt': '2026-11-13T10:00:00.000Z',
                },
                'movement': {
                  'status': 'active',
                  'selectedAt': '2026-11-13T09:00:00.000Z',
                },
                'goal': {
                  'status': 'active',
                  'selectedAt': '2026-11-13T08:00:00.000Z',
                },
              },
            },
          }),
        );
        final before = document.encode();
        expect(
          nextHomeAdventure(document, day, adult: adult),
          adult ? AdventureTask.goal : AdventureTask.movement,
        );
        expect(
          nextHomeAdventure(document, DateTime(2026, 11, 14), adult: adult),
          isNull,
        );
        expect(document.encode(), before);
      },
    );
  }
  test('An absent document never invents a next activity', () {
    expect(
      nextHomeAdventure(AdventureDocument.decode(null), day, adult: true),
      isNull,
    );
  });
  for (final locale in ['hu', 'en']) {
    testWidgets(
      '$locale minor home has check-in primary and no drink primary',
      (t) async {
        const xp = '{"xp":150,"days":[],"completed":[],"future":"keep"}';
        SharedPreferences.setMockInitialValues({
          MentiAccessSettings.key:
              '{"version":1,"audience":"minor","complete":true}',
          'mennyiment_character_setup_complete_v1': true,
          'mennyiment_locale_v1': locale,
          'mennyiment_reduce_motion_v1': true,
          'mennyiment_menti_xp_v2': xp,
          'mennyiment_drinks_v1': '[]',
        });
        t.view.physicalSize = const Size(320, 740);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        await t.pumpWidget(const MennyiMentApp());
        await t.pumpAndSettle();
        expect(find.byKey(const ValueKey('home-primary-log')), findsNothing);
        final primary = find.byKey(const ValueKey('home-primary-checkin'));
        await t.scrollUntilVisible(
          primary,
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await t.pumpAndSettle();
        expect(primary.hitTestable(), findsOneWidget);
        expect(t.widget<FilledButton>(primary).onPressed, isNotNull);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('mennyiment_menti_xp_v2'), xp);
        expect(prefs.getString('mennyiment_drinks_v1'), '[]');
        await t.pumpWidget(const SizedBox.shrink());
        await t.pumpAndSettle();
      },
    );
  }
}
