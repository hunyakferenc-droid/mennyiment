import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/menti_fitness.dart';
import 'package:mennyiment/menti_club_store.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';

void main() {
  for (final lang in ['hu', 'en']) {
    for (final allowed in [false, true]) {
      testWidgets(
        '$lang 320/200 virtual days require explicit REVIEW capability: $allowed',
        (t) async {
          SharedPreferences.setMockInitialValues({});
          t.view.physicalSize = const Size(320, 1000);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          await t.pumpWidget(
            MaterialApp(
              locale: Locale(lang),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (c, child) => MediaQuery(
                data: MediaQuery.of(c)
                    .copyWith(textScaler: TextScaler.linear(2)),
                child: child!,
              ),
              home: MentiFitnessClub(allowTestMode: allowed),
            ),
          );
          await t.pumpAndSettle();
          final control = find.byKey(const ValueKey('club-test-mode'));
          if (allowed) {
            await t.scrollUntilVisible(control, 300, maxScrolls: 30);
            await t.pumpAndSettle();
            await t.tap(control);
            await t.pumpAndSettle();
            expect(find.byKey(const ValueKey('club-next-day')), findsOneWidget);
            expect(
              find.byKey(const ValueKey('club-test-date')),
              findsOneWidget,
            );
          } else {
            await t.drag(find.byType(Scrollable).first, const Offset(0, -4000));
            await t.pumpAndSettle();
            expect(control, findsNothing);
            expect(find.byKey(const ValueKey('club-next-day')), findsNothing);
          }
          final p = await SharedPreferences.getInstance();
          expect(p.containsKey(MentiClubStore.testKey), false);
          expect(p.containsKey(MentiClubStore.normalKey), false);
          expect(t.takeException(), isNull);
        },
      );
    }
    testWidgets(
      '$lang testMode cannot activate virtual clock without REVIEW permission',
      (t) async {
        SharedPreferences.setMockInitialValues({});
        await t.pumpWidget(
          MaterialApp(
            locale: Locale(lang),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const MentiFitnessClub(testMode: true),
          ),
        );
        await t.pumpAndSettle();
        expect(find.byKey(const ValueKey('club-next-day')), findsNothing);
      },
    );
  }
}
