import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Test-only fault injection into SharedPreferences' own in-memory platform.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:mennyiment/main.dart';

const key = 'mennyiment_drinks_v1';
Map<String, Object> initial(Object? journal) => {
  key: ?journal,
  'mennyiment_character_setup_complete_v1': true,
  'mennyiment_menti_xp_v2': jsonEncode({'xp': 0, 'days': [], 'completed': []}),
};
String savedRecord() => jsonEncode([
  {
    'name': 'Régi ital',
    'ml': 250,
    'percent': 4,
    'time': DateTime.now().toIso8601String(),
    'priceFt': 100,
    'unknown': 'retain',
  },
]);

Future<void> frames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
}

Future<void> openHome(WidgetTester tester, Object? journal) async {
  tester.view.physicalSize = const Size(1100, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues(initial(journal));
  await tester.pumpWidget(const MennyiMentApp());
  await frames(tester);
}

Future<void> details(WidgetTester tester) async {
  await tester.ensureVisible(find.text('ITAL NAPLÓZÁSA'));
  await tester.tap(find.text('ITAL NAPLÓZÁSA'));
  await frames(tester);
  await tester.tap(find.text('Sör (általános)'));
  await frames(tester);
}

Future<void> dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

class FailedJournalWrites extends InMemorySharedPreferencesStore {
  FailedJournalWrites(super.data) : super.withData();
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (key == 'flutter.mennyiment_drinks_v1') return false;
    return super.setValue(type, key, value);
  }
}

void main() {
  for (final corrupt in <Object>['{broken', '{}', '[{"name":"broken"}]', 42]) {
    testWidgets(
      'Corrupt journal $corrupt remains untouched with writes disabled',
      (tester) async {
        await openHome(tester, corrupt);
        final prefs = await SharedPreferences.getInstance();
        expect(find.byKey(const ValueKey('journal-error')), findsOneWidget);
        final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'ITAL NAPLÓZÁSA'),
        );
        expect(button.onPressed, isNull);
        expect(prefs.get(key), corrupt);
        await dispose(tester);
      },
    );
  }
  testWidgets('Canceling drink details never writes a journal', (tester) async {
    final saved = savedRecord();
    await openHome(tester, saved);
    await details(tester);
    Navigator.of(tester.element(find.text('Mentés a naplóba'))).pop();
    await frames(tester);
    expect((await SharedPreferences.getInstance()).getString(key), saved);
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets(
    'Rapid double submit records exactly one drink and preserves old fields',
    (tester) async {
      final saved = savedRecord();
      await openHome(tester, saved);
      await details(tester);
      final submit = tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Mentés a naplóba'),
          )
          .onPressed!;
      submit();
      submit();
      await frames(tester);
      final values = jsonDecode(
        (await SharedPreferences.getInstance()).getString(key)!,
      ) as List;
      expect(values.length, 2);
      expect(values.last, (jsonDecode(saved) as List).single);
      expect(values.first.containsKey('priceFt'), isFalse);
      expect(find.textContaining('mentve a naplóba'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await dispose(tester);
    },
  );

  testWidgets(
    'Invalid input is rejected; comma decimals and zero price save correctly',
    (tester) async {
      await openHome(tester, null);
      await details(tester);
      final fields = find.byType(TextFormField);
      for (final data in [
        <String>['0', '5', ''],
        ['10001', '5', ''],
        ['500', 'NaN', ''],
        ['500', '101', ''],
        ['500', '5', '-1'],
        ['500', '5', 'Infinity'],
      ]) {
        for (var i = 0; i < 3; i++) {
          await tester.enterText(fields.at(i), data[i]);
        }
        await tester.tap(find.text('Mentés a naplóba'));
        await tester.pump();
        expect((await SharedPreferences.getInstance()).get(key), isNull);
        expect(find.text('Mentés a naplóba'), findsOneWidget);
      }
      await tester.enterText(fields.at(0), '250');
      await tester.enterText(fields.at(1), '4,5');
      await tester.enterText(fields.at(2), '0');
      await tester.tap(find.text('Mentés a naplóba'));
      await frames(tester);
      final value = (jsonDecode(
        (await SharedPreferences.getInstance()).getString(key)!,
      ) as List).single;
      expect(value['percent'], 4.5);
      expect(value['priceFt'], 0);
      expect(tester.takeException(), isNull);
      await dispose(tester);
    },
  );

  testWidgets(
    'Delete requires confirmation and cancellation leaves original JSON intact',
    (tester) async {
      final saved = savedRecord();
      await openHome(tester, saved);
      Future<void> menu() async {
        await tester.ensureVisible(find.byTooltip('Bejegyzés műveletei'));
        await tester.tap(find.byTooltip('Bejegyzés műveletei'));
        await frames(tester);
        await tester.tap(find.text('Bejegyzés törlése'));
        await frames(tester);
      }

      await menu();
      await tester.tap(find.text('Mégse'));
      await frames(tester);
      expect((await SharedPreferences.getInstance()).getString(key), saved);
      await menu();
      final confirm = tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Törlés'))
          .onPressed!;
      confirm();
      confirm();
      await frames(tester);
      expect((await SharedPreferences.getInstance()).getString(key), '[]');
      expect(tester.takeException(), isNull);
      await dispose(tester);
    },
  );

  testWidgets(
    'Failed persistence does not show success or change the visible journal',
    (tester) async {
      final saved = savedRecord();
      await openHome(tester, saved);
      final prefs = await SharedPreferences.getInstance();
      SharedPreferencesStorePlatform.instance = FailedJournalWrites({
        for (final k in prefs.getKeys()) 'flutter.$k': prefs.get(k)!,
      });
      await details(tester);
      await tester.tap(find.text('Mentés a naplóba'));
      await frames(tester);
      await prefs.reload();
      expect(prefs.getString(key), saved);
      expect(find.textContaining('mentve a naplóba'), findsNothing);
      expect(find.byKey(const ValueKey('journal-error')), findsOneWidget);
      expect(find.text('Régi ital'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await dispose(tester);
    },
  );

  testWidgets(
    'Price edits preserve legacy fields and an empty price explicitly clears only that field',
    (tester) async {
      final saved = savedRecord();
      await openHome(tester, saved);
      Future<void> price() async {
        await tester.ensureVisible(find.byTooltip('Bejegyzés műveletei'));
        await tester.tap(find.byTooltip('Bejegyzés műveletei'));
        await frames(tester);
        await tester.tap(find.textContaining('Ft – szerkesztés'));
        await frames(tester);
      }

      await price();
      await tester.enterText(find.byType(TextField), '12,5');
      await tester.tap(find.widgetWithText(FilledButton, 'Mentés'));
      await frames(tester);
      final prefs = await SharedPreferences.getInstance();
      var value = (jsonDecode(prefs.getString(key)!) as List).single;
      expect(value, {...(jsonDecode(saved) as List).single, 'priceFt': 12.5});
      await price();
      await tester.enterText(find.byType(TextField), '');
      final submit = tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Mentés'))
          .onPressed!;
      submit();
      submit();
      await frames(tester);
      value = (jsonDecode(prefs.getString(key)!) as List).single;
      expect(value.containsKey('priceFt'), isFalse);
      expect(value['unknown'], 'retain');
      expect(tester.takeException(), isNull);
      await dispose(tester);
    },
  );

  testWidgets('Corrupt custom drink catalog cannot be silently replaced', (
    tester,
  ) async {
    await openHome(tester, null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mennyiment_custom_drinks_v1', '{broken');
    final dynamic state = tester.state(find.byType(HomePage));
    await state.loadCustomDrinks();
    await state.showAddDrinkDialog();
    await frames(tester);
    expect(find.text('Új saját ital'), findsNothing);
    expect(prefs.getString('mennyiment_custom_drinks_v1'), '{broken');
    await dispose(tester);
  });

  testWidgets(
    'An external journal change is not overwritten by a stale screen',
    (tester) async {
      await openHome(tester, savedRecord());
      await details(tester);
      final prefs = await SharedPreferences.getInstance();
      final external = jsonEncode([
        {'external': 'keep'},
      ]);
      await prefs.setString(key, external);
      await tester.tap(find.text('Mentés a naplóba'));
      await frames(tester);
      expect(prefs.getString(key), external);
      expect(find.byKey(const ValueKey('journal-error')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await dispose(tester);
    },
  );
}
