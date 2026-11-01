import 'support/adult_access_fixture.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/app_language.dart';
import 'package:mennyiment/main.dart';
import 'package:mennyiment/statistics.dart';
import 'package:mennyiment/menti_character_catalog.dart';
import 'package:mennyiment/menti_profile_storage.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => SharedPreferences.setMockInitialValues({adultAccessKey: adultAccessValue,
      'mennyiment_character_setup_complete_v1': true,
    }),
  );
  Future<void> frames(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
  }

  void large(WidgetTester tester) {
    tester.view.physicalSize = const Size(1100, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  test(
    'ARB catalogs have exactly the same translated keys and placeholders',
    () {
      final hu = jsonDecode(
        File('lib/l10n/app_hu.arb').readAsStringSync(),
      ) as Map<String, dynamic>;
      final en = jsonDecode(
        File('lib/l10n/app_en.arb').readAsStringSync(),
      ) as Map<String, dynamic>;
      expect(hu.keys.toSet(), en.keys.toSet());
      for (final key in hu.keys.where((k) => !k.startsWith('@'))) {
        expect(en[key], isA<String>());
        expect((en[key] as String).trim(), isNotEmpty);
        expect(
          RegExp(r'\{\w+\}').allMatches(en[key]).map((m) => m[0]).toSet(),
          RegExp(r'\{\w+\}').allMatches(hu[key]).map((m) => m[0]).toSet(),
        );
      }
    },
  );
  test(
    'Language preference reloads and never changes legacy profiles',
    () async {
      for (final family in MentiCharacterFamily.values) {
        SharedPreferences.setMockInitialValues({adultAccessKey: adultAccessValue,
          MentiProfileStorage.characterStyleKey: family.label,
          MentiProfileStorage.outfitKey: 'Legendás szett',
        });
        final prefs = await SharedPreferences.getInstance();
        final controller = AppLanguage();
        await controller.load();
        expect(controller.selection, 'hu');
        for (final choice in ['en', 'auto', 'hu']) {
          expect(await controller.select(choice), isTrue);
          final restored = AppLanguage();
          await restored.load();
          expect(restored.selection, choice);
          expect(MentiProfileStorage.family(prefs), family);
          expect(MentiProfileStorage.outfit(prefs), MentiOutfit.legendary);
          expect(
            prefs.get(MentiProfileStorage.characterStyleKey),
            family.label,
          );
          expect(prefs.get(MentiProfileStorage.outfitKey), 'Legendás szett');
          restored.dispose();
        }
        controller.dispose();
      }
    },
  );
  test(
    'Unknown language value is retained and falls back to Hungarian',
    () async {
      SharedPreferences.setMockInitialValues({adultAccessKey: adultAccessValue,
        AppLanguage.preferenceKey: 'future-locale',
      });
      final controller = AppLanguage();
      await controller.load();
      expect(controller.selection, 'hu');
      expect(
        (await SharedPreferences.getInstance()).get(AppLanguage.preferenceKey),
        'future-locale',
      );
      controller.dispose();
    },
  );
  test(
    'Failed preference access does not change the selected language',
    () async {
      var fail = false;
      final controller = AppLanguage(
        openPreferences: () {
          if (fail) throw StateError('Test storage failure');
          return SharedPreferences.getInstance();
        },
      );
      await controller.load();
      expect(await controller.select('en'), isTrue);
      fail = true;
      expect(await controller.select('hu'), isFalse);
      expect(controller.selection, 'en');
      expect(controller.saving, isFalse);
      controller.dispose();
      final unreadable = AppLanguage(
        openPreferences: () => throw StateError('Test read failure'),
      );
      await unreadable.load();
      expect(unreadable.selection, 'hu');
      unreadable.dispose();
    },
  );

  testWidgets(
    'Default Hungarian, manual English and Hungarian survive app recreation',
    (tester) async {
      large(tester);
      await tester.pumpWidget(const MennyiMentApp());
      await frames(tester);
      expect(find.text('Kezdőlap'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('language-menu')));
      await frames(tester);
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is CheckedPopupMenuItem<String> && w.value == 'en',
        ),
      );
      await frames(tester);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Journal'), findsOneWidget);
      expect(find.text('Insights'), findsOneWidget);
      expect(
        (await SharedPreferences.getInstance()).get(AppLanguage.preferenceKey),
        'en',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pumpWidget(const MennyiMentApp());
      await frames(tester);
      expect(find.text('Home'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('language-menu')));
      await frames(tester);
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is CheckedPopupMenuItem<String> && w.value == 'hu',
        ),
      );
      await frames(tester);
      expect(find.text('Kezdőlap'), findsOneWidget);
      expect(
        (await SharedPreferences.getInstance()).get(AppLanguage.preferenceKey),
        'hu',
      );
      await tester.tap(find.byKey(const ValueKey('language-menu')));
      await frames(tester);
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is CheckedPopupMenuItem<String> && w.value == 'auto',
        ),
      );
      await frames(tester);
      expect(
        (await SharedPreferences.getInstance()).get(AppLanguage.preferenceKey),
        'auto',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
  testWidgets(
    'Explicit automatic follows supported system locale and falls back to Hungarian',
    (tester) async {
      large(tester);
      SharedPreferences.setMockInitialValues({adultAccessKey: adultAccessValue,
        AppLanguage.preferenceKey: 'auto',
        'mennyiment_character_setup_complete_v1': true,
      });
      tester.binding.platformDispatcher.localesTestValue = const [
        Locale('en', 'GB'),
      ];
      addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
      await tester.pumpWidget(const MennyiMentApp());
      await frames(tester);
      expect(find.text('Home'), findsOneWidget);
      tester.binding.platformDispatcher.localesTestValue = const [Locale('de')];
      await frames(tester);
      expect(find.text('Kezdőlap'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
  testWidgets('English home navigation fits a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(360, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({adultAccessKey: adultAccessValue,
      AppLanguage.preferenceKey: 'en',
      'mennyiment_character_setup_complete_v1': true,
    });
    await tester.pumpWidget(const MennyiMentApp());
    await frames(tester);
    expect(find.text('Home'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Finance centre – detailed overview'), 300,
      scrollable: find.byType(Scrollable).first, maxScrolls: 40);
    await frames(tester);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  for (final locale in ['hu', 'en']) {
    testWidgets(
      '$locale statistics formats numbers, dates and long text on a narrow screen',
      (tester) async {
        tester.view.physicalSize = const Size(360, 2200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(locale),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: StatisticsPage(
              clock: () => DateTime(2026, 3, 25),
              drinks: [
                StatisticsDrink(
                  name: 'Saját ital / user drink',
                  ml: 250,
                  percent: 4,
                  time: DateTime(2026, 3, 24),
                  priceFt: 1234.5,
                ),
                StatisticsDrink(
                  name: 'Hiányzó ár',
                  ml: 250,
                  percent: 4,
                  time: DateTime(2026, 3, 25),
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(localeCurrency(1234.5, locale)), findsOneWidget);
        final date = DateFormat.yMd(locale);
        expect(
          find.text(
            '${date.format(DateTime(2026, 3, 23))} – ${date.format(DateTime(2026, 3, 29))}',
          ),
          findsOneWidget,
        );
        expect(
          find.text(locale == 'en' ? 'Known spending' : 'Ismert költés'),
          findsOneWidget,
        );
        expect(
          find.textContaining(
            locale == 'en' ? 'Partial total: 1' : 'Részösszeg: 1',
          ),
          findsOneWidget,
        );
        await tester.ensureVisible(
          find.textContaining(
            locale == 'en'
                ? 'Summaries use recorded'
                : 'Az összesítések kizárólag',
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
