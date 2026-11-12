import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mennyiment/drink_journal.dart';
import 'package:mennyiment/drink_journal_page.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';
import 'package:mennyiment/menti_design.dart';

void main() {
  setUpAll(() => initializeDateFormatting());
  for (final locale in ['hu', 'en']) {
    for (final width in [320.0, 360.0, 390.0, 430.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          '$locale $width / $scale: both actions select the exact occurrence with keyboard',
          (t) async {
            t.view.physicalSize = Size(width, 640);
            t.view.devicePixelRatio = 1;
            addTearDown(t.view.resetPhysicalSize);
            addTearDown(t.view.resetDevicePixelRatio);
            addTearDown(t.view.resetViewInsets);
            final drink = Drink('Twin', 250, 4, time: DateTime(2026, 11, 12));
            final calls = <(int, bool)>[];
            await t.pumpWidget(
              MaterialApp(
                theme: MentiDesign.theme,
                locale: Locale(locale),
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                builder: (c, child) => MediaQuery(
                  data: MediaQuery.of(c)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: DrinkJournalPage(
                  drinks: [drink, drink],
                  onEdit: (index, entry, price) async {
                    expect(identical(entry, drink), isTrue);
                    calls.add((index, price));
                    return false;
                  },
                ),
              ),
            );
            await t.pumpAndSettle();
            t.view.viewInsets = const FakeViewPadding(bottom: 280);
            await t.enterText(
              find.byKey(const ValueKey('journal-search')),
              'twin',
            );
            await t.pumpAndSettle();
            for (final kind in ['edit', 'price']) {
              final button = find.byKey(ValueKey('journal-$kind-1'));
              await t.scrollUntilVisible(
                button,
                160,
                scrollable: find.byType(Scrollable).first,
                maxScrolls: 70,
              );
              await t.pumpAndSettle();
              await t.tap(button);
              await t.pumpAndSettle();
              expect(t.takeException(), isNull);
            }
            expect(calls, [(1, false), (1, true)]);
            expect(drink.priceFt, isNull);
            expect(drink.name, 'Twin');
            await t.pumpWidget(const SizedBox.shrink());
            await t.pumpAndSettle();
          },
        );
      }
    }
  }
}
