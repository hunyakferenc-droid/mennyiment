import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mennyiment/drink_journal.dart';
import 'package:mennyiment/drink_journal_page.dart';
import 'package:mennyiment/journal_query.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';

final now = DateTime(2026, 11, 12, 16);
List<Drink> fixture() => [
  Drink('Őszibarack', 250, 0, time: now, priceFt: 1234.75),
  Drink('Ár nélküli', 330, 4, time: now),
  Drink('Ingyenes', 500, 0, time: now, priceFt: 0),
  Drink('Korábbi', 100, 5, time: DateTime(2026, 10, 1), priceFt: 100),
];
Future<void> open(
  WidgetTester tester, {
  String locale = 'hu',
  double width = 430,
  double textScale = 1,
  double height = 2800,
  List<Drink>? drinks,
  DateTime Function()? clock,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(locale),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: DrinkJournalPage(
        drinks: drinks ?? fixture(),
        clock: clock ?? () => now,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting());
  testWidgets('Reset retains the opening calendar day after midnight', (
    tester,
  ) async {
    var clock = now;
    await open(tester, clock: () => clock);
    await tester.tap(find.text('Nap'));
    await tester.pumpAndSettle();
    expect(find.text('Őszibarack'), findsOneWidget);
    clock = DateTime(2026, 11, 13);
    await tester.tap(find.byKey(const ValueKey('journal-reset')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nap'));
    await tester.pumpAndSettle();
    expect(find.text('Őszibarack'), findsOneWidget);
  });
  for (final locale in ['hu', 'en']) {
    for (final width in [320.0, 360.0, 390.0, 430.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          '$locale $width / $scale: phone keyboard and real price menu',
          (tester) async {
            final drinks = fixture();
            final before = jsonEncode(drinks.map((d) => d.toJson()).toList());
            await open(
              tester,
              locale: locale,
              width: width,
              height: 640,
              textScale: scale,
              drinks: drinks,
            );
            tester.view.viewInsets = const FakeViewPadding(bottom: 280);
            addTearDown(tester.view.resetViewInsets);
            await tester.enterText(
              find.byKey(const ValueKey('journal-search')),
              'ar',
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await tester.testTextInput.receiveAction(TextInputAction.done);
            tester.view.resetViewInsets();
            await tester.pumpAndSettle();
            final menu = find.byType(DropdownButtonFormField<JournalPrice>);
            await tester.ensureVisible(menu);
            await tester.tap(menu);
            await tester.pumpAndSettle();
            await tester.tap(
              find.text(locale == 'hu' ? 'Hiányzó ár' : 'Missing price').last,
            );
            await tester.pumpAndSettle();
            await tester.scrollUntilVisible(
              find.text('Ár nélküli'),
              180,
              scrollable: find.byType(Scrollable).first,
            );
            expect(find.text('Ár nélküli'), findsOneWidget);
            expect(tester.takeException(), isNull);
            expect(jsonEncode(drinks.map((d) => d.toJson()).toList()), before);
          },
        );
      }
    }
  }
  testWidgets('Accent-free search and reset preserve original JSON', (
    tester,
  ) async {
    final drinks = fixture();
    final before = jsonEncode(drinks.map((d) => d.toJson()).toList());
    await open(tester, drinks: drinks);
    await tester.enterText(
      find.byKey(const ValueKey('journal-search')),
      'oszibarack',
    );
    await tester.pumpAndSettle();
    expect(find.text('Őszibarack'), findsOneWidget);
    expect(find.text('Ár nélküli'), findsNothing);
    expect(find.text('Ingyenes'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('journal-reset')));
    await tester.pumpAndSettle();
    expect(find.text('Ár nélküli'), findsOneWidget);
    expect(jsonEncode(drinks.map((d) => d.toJson()).toList()), before);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Missing-price filter excludes zero and resets cleanly', (
    tester,
  ) async {
    await open(tester);
    final dropdown = tester.widget<DropdownButtonFormField<JournalPrice>>(
      find.byType(DropdownButtonFormField<JournalPrice>),
    );
    dropdown.onChanged!(JournalPrice.missing);
    await tester.pumpAndSettle();
    expect(find.text('Ár nélküli'), findsOneWidget);
    expect(find.text('Ingyenes'), findsNothing);
    expect(find.text('Őszibarack'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('journal-reset')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<DropdownButtonFormField<JournalPrice>>(
            find.byType(DropdownButtonFormField<JournalPrice>),
          )
          .initialValue,
      JournalPrice.all,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('Current month and previous month change the visible records', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Hónap'));
    await tester.pumpAndSettle();
    expect(find.text('Korábbi'), findsNothing);
    expect(find.text('Őszibarack'), findsOneWidget);
    await tester.tap(find.byTooltip('Előző időszak'));
    await tester.pumpAndSettle();
    expect(find.text('Korábbi'), findsOneWidget);
    expect(find.text('Őszibarack'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('No-match message differs from an empty journal', (tester) async {
    await open(tester, locale: 'en');
    await tester.enterText(
      find.byKey(const ValueKey('journal-search')),
      'nothing matches',
    );
    await tester.pumpAndSettle();
    expect(find.text('No entries match these filters.'), findsOneWidget);
    expect(find.text('Clear filters'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
  for (final locale in ['hu', 'en']) {
    for (final width in [320.0, 390.0]) {
      testWidgets('$locale at $width and 200% text remains scrollable', (
        tester,
      ) async {
        await open(tester, locale: locale, width: width, textScale: 2);
        await tester.tap(find.text(locale == 'hu' ? 'Hónap' : 'Month'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const ValueKey('journal-reset')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('Add action retains the existing pop(true) contract', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) =>
                      DrinkJournalPage(drinks: [], clock: () => now),
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('journal-add-drink')));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}
