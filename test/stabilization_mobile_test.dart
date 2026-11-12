import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/app_language.dart';
import 'package:mennyiment/data_backup.dart';
import 'package:mennyiment/data_backup_page.dart';
import 'package:mennyiment/drink_catalog.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';
import 'package:mennyiment/main.dart';
import 'package:mennyiment/menti_identity/menti_identity_store.dart';
import 'package:mennyiment/statistics.dart';

import 'support/adult_access_fixture.dart';

void main() {
  void viewport(WidgetTester tester, double width, double scale) {
    tester.view.physicalSize = Size(width, 740);
    tester.view.devicePixelRatio = 1;
    tester.binding.platformDispatcher.textScaleFactorTestValue = scale;
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(
      tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
    );
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );
  }

  Widget localized(String locale, double scale, Widget home) => MaterialApp(
    locale: Locale(locale),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: home,
  );

  Future<void> reveal(WidgetTester tester, Finder target) async {
    if (target.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        target,
        180,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 80,
      );
    }
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder target) async {
    await reveal(tester, target);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  for (final locale in ['hu', 'en']) {
    for (final width in [320.0, 360.0, 390.0, 430.0]) {
      for (final scale in [1.0, 2.0]) {
        final description = '$locale ${width}px ${scale}x';
        testWidgets(
          '$description onboarding system back and keyboard keep progress and actions reachable',
          (tester) async {
            viewport(tester, width, scale);
            SharedPreferences.setMockInitialValues({
              'mennyiment_locale_v1': locale,
            });
            await tester.pumpWidget(const MennyiMentApp());
            await tester.pumpAndSettle();
            final next = find.byKey(const ValueKey('start-next'));
            await tap(tester, next);
            await tap(tester, find.byKey(const ValueKey('start-adult')));
            await tap(tester, next);
            await tap(tester, next);
            final name = find.byKey(const ValueKey('start-name'));
            await reveal(tester, name);
            await tester.enterText(name, 'Mobile Menti');
            tester.view.viewInsets = const FakeViewPadding(bottom: 280);
            await tester.pumpAndSettle();
            expect(
              tester.getBottomRight(next).dy,
              lessThanOrEqualTo(740 - 280),
            );
            expect(next.hitTestable(), findsOneWidget);
            expect(tester.takeException(), isNull);
            tester.view.resetViewInsets();
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            expect(name, findsNothing);
            await reveal(
              tester,
              find.byKey(const ValueKey('start-family-girl')),
            );
            expect(
              find.byKey(const ValueKey('start-family-girl')),
              findsOneWidget,
            );
            final prefs = await SharedPreferences.getInstance();
            expect(prefs.containsKey(MentiIdentityStore.key), false);
            await tap(tester, next);
            expect(
              tester.widget<TextField>(name).controller!.text,
              'Mobile Menti',
            );
            final finish = tester.widget<FilledButton>(next).onPressed!;
            finish();
            finish();
            await tester.pumpAndSettle();
            expect(find.byType(HomePage), findsOneWidget);
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pumpAndSettle();
          },
        );

        testWidgets(
          '$description restore confirmation remains usable above keyboard',
          (tester) async {
            viewport(tester, width, scale);
            SharedPreferences.setMockInitialValues({
              'mennyiment_locale_v1': 'en',
            });
            final text = (await BackupExporter().capture()).json;
            SharedPreferences.setMockInitialValues({
              'mennyiment_locale_v1': 'hu',
            });
            await tester.pumpWidget(
              localized(locale, scale, DataBackupPage(pick: () async => text)),
            );
            await tester.pumpAndSettle();
            await tap(tester, find.byKey(const ValueKey('restore-pick')));
            await tap(tester, find.byKey(const ValueKey('restore-apply')));
            tester.view.viewInsets = const FakeViewPadding(bottom: 280);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await tap(tester, find.byKey(const ValueKey('restore-cancel')));
            expect(
              (await SharedPreferences.getInstance()).get(
                'mennyiment_locale_v1',
              ),
              'hu',
            );
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pumpAndSettle();
          },
        );

        testWidgets(
          '$description statistics periods fit and preserve missing prices',
          (tester) async {
            viewport(tester, width, scale);
            await tester.pumpWidget(
              localized(
                locale,
                scale,
                StatisticsPage(
                  clock: () => DateTime(2026, 11, 12),
                  drinks: [
                    StatisticsDrink(
                      name: 'Mobile record',
                      ml: 250,
                      percent: 4.5,
                      time: DateTime(2026, 11, 12),
                    ),
                  ],
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            final s = appStrings(tester.element(find.byType(StatisticsPage)));
            for (final period in [s.month, s.year, s.week]) {
              await tap(tester, find.text(period));
              expect(tester.takeException(), isNull);
            }
            await tester.scrollUntilVisible(
              find.byKey(const ValueKey('statistics-price-coverage')),
              200,
              scrollable: find.byType(Scrollable).first,
              maxScrolls: 50,
            );
            expect(find.text(s.partialPrices(1)), findsOneWidget);
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
          },
        );
      }
    }
    testWidgets(
      '$locale editing a fractional price preserves it and localizes visible helper and date',
      (tester) async {
        viewport(tester, 320, 2);
        final time = DateTime(2026, 11, 12, 13, 15);
        SharedPreferences.setMockInitialValues({
          adultAccessKey: adultAccessValue,
          'mennyiment_locale_v1': locale,
          'mennyiment_reduce_motion_v1': true,
          'mennyiment_drinks_v1': jsonEncode([
            {
              'name': 'Sör (általános)',
              'ml': 250,
              'percent': 4.5,
              'priceFt': 1234.75,
              'time': time.toIso8601String(),
              'future': 'keep',
            },
          ]),
        });
        await tester.pumpWidget(const MennyiMentApp());
        await tester.pumpAndSettle();
        final s = appStrings(tester.element(find.byType(HomePage)));
        final more = find.byKey(const ValueKey('home-more-features'));
        await tester.scrollUntilVisible(
          more,
          250,
          scrollable: find.byType(Scrollable).first,
          maxScrolls: 60,
        );
        await tap(tester, more);
        final menu = find.byTooltip(s.homeRecordActions);
        await tester.scrollUntilVisible(
          menu,
          250,
          scrollable: find.byType(Scrollable).first,
          maxScrolls: 60,
        );
        expect(
          find.textContaining(DateFormat.yMMMd(locale).add_Hm().format(time)),
          findsOneWidget,
        );
        await tap(tester, menu);
        await tap(
          tester,
          find.text(s.homeEditPrice(localeCurrency(1234.75, locale))),
        );
        expect(find.text(s.journalPriceHint), findsOneWidget);
        expect(
          find.text(s.journalSetPrice(catalogDrinkLabel('Sör (általános)', s))),
          findsOneWidget,
        );
        final field = tester.widget<TextField>(find.byType(TextField));
        expect(field.controller!.text, locale == 'hu' ? '1234,75' : '1234.75');
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tap(tester, find.widgetWithText(FilledButton, s.avatarSave));
        final records = jsonDecode(
          (await SharedPreferences.getInstance()).getString(
            'mennyiment_drinks_v1',
          )!,
        ) as List;
        expect(records.single['priceFt'], 1234.75);
        expect(records.single['name'], 'Sör (általános)');
        expect(records.single['future'], 'keep');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  }
}
