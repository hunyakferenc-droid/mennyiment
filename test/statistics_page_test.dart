import 'support/adult_access_fixture.dart';
import 'dart:convert';

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:mennyiment/app_language.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/main.dart';
import 'package:mennyiment/statistics.dart';

void largeView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1100, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  setUpAll(() => initializeDateFormatting());
  testWidgets(
    'Period selection updates costs, incomplete data and calendar bars',
    (tester) async {
      largeView(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: StatisticsPage(
            clock: () => DateTime(2026, 3, 25),
            drinks: [
              StatisticsDrink(
                name: 'Hét',
                ml: 250,
                percent: 4,
                time: DateTime(2026, 3, 24),
                priceFt: 100,
              ),
              StatisticsDrink(
                name: 'Hiányzó',
                ml: 250,
                percent: 4,
                time: DateTime(2026, 3, 25),
              ),
              StatisticsDrink(
                name: 'Korábbi',
                ml: 250,
                percent: 4,
                time: DateTime(2026, 3, 2),
                priceFt: 700,
              ),
              StatisticsDrink(
                name: 'Következő',
                ml: 250,
                percent: 4,
                time: DateTime(2026, 4, 1),
                priceFt: 900,
              ),
            ],
          ),
        ),
      );
      expect(find.text(localeCurrency(100, 'hu')), findsOneWidget);
      expect(find.textContaining('Részösszeg: 1 ital'), findsOneWidget);
      Finder bars() => find.byWidgetPredicate(
        (w) => w is Tooltip && (w.message?.endsWith(' g') ?? false),
      );
      expect(bars(), findsNWidgets(7));
      await tester.tap(find.text('Hónap'));
      await tester.pumpAndSettle();
      expect(find.text(localeCurrency(800, 'hu')), findsOneWidget);
      expect(bars(), findsNWidgets(31));
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      expect(find.text(localeCurrency(0, 'hu')), findsOneWidget);
      expect(
        find.text(
          'Nincs rögzített ital: költésadat még nem áll rendelkezésre.',
        ),
        findsOneWidget,
      );
      expect(bars(), findsNWidgets(28));
      await tester.tap(find.text('Év'));
      await tester.pumpAndSettle();
      expect(find.text(localeCurrency(1700, 'hu')), findsOneWidget);
      expect(bars(), findsNWidgets(12));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('UTC clock uses the local month for previous-month navigation', (
    tester,
  ) async {
    largeView(tester);
    final instant = DateTime.utc(2026, 3, 31, 23, 30);
    final local = instant.toLocal();
    await tester.pumpWidget(
      MaterialApp(
        home: StatisticsPage(clock: () => instant, drinks: const []),
      ),
    );
    await tester.tap(find.text('Hónap'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
    final start = DateTime(local.year, local.month - 1);
    final end = DateTime(local.year, local.month, 0);
    String date(DateTime d) => DateFormat.yMd('hu').format(d);
    expect(find.text('${date(start)} – ${date(end)}'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Zero is a known price and retains unlogged-day caution on narrow view',
    (tester) async {
      tester.view.physicalSize = const Size(360, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: StatisticsPage(
            clock: () => DateTime(2026, 3, 25),
            drinks: [
              StatisticsDrink(
                name: 'Ajándék',
                ml: 250,
                percent: 4,
                time: DateTime(2026, 3, 24),
                priceFt: 0,
              ),
            ],
          ),
        ),
      );
      expect(find.text(localeCurrency(0, 'hu')), findsOneWidget);
      expect(
        find.text('Minden rögzített italhoz tartozik ár az időszakban.'),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.textContaining('A „rögzítés nélküli nap”'),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('nem bizonyítottan alkoholmentes nap'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Home forwards saved prices; statistics neither rewrites drinks nor XP',
    (tester) async {
      largeView(tester);
      final saved = jsonEncode([
        {
          'name': 'Teszt',
          'ml': 250,
          'percent': 4.0,
          'time': DateTime.now().toIso8601String(),
          'priceFt': 1234.0,
        },
      ]);
      final xp = jsonEncode({'xp': 150, 'days': [], 'completed': []});
      SharedPreferences.setMockInitialValues({adultAccessKey: adultAccessValue,
        'mennyiment_drinks_v1': saved,
        'mennyiment_menti_xp_v2': xp,
        'mennyiment_character_setup_complete_v1': true,
      });
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(const MennyiMentApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final before = {for (final key in prefs.getKeys()) key: prefs.get(key)};
      final statisticsLabel = appStrings(tester.element(find.byType(HomePage))).statisticsNav;
      await tester.scrollUntilVisible(find.text(statisticsLabel), 300,
        scrollable: find.byType(Scrollable).first, maxScrolls: 40);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text(statisticsLabel));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        tester
            .widget<StatisticsPage>(find.byType(StatisticsPage))
            .drinks
            .single
            .priceFt,
        1234,
      );
      expect(find.text(localeCurrency(1234, 'hu')), findsOneWidget);
      expect({for (final key in prefs.getKeys()) key: prefs.get(key)}, before);
      expect(prefs.getString('mennyiment_drinks_v1'), saved);
      expect(prefs.getString('mennyiment_menti_xp_v2'), xp);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
