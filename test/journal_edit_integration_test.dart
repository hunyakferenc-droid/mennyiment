import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:mennyiment/main.dart';
import 'package:mennyiment/app_language.dart';
import 'package:mennyiment/drink_journal_page.dart';
import 'package:mennyiment/journal_entry_editor.dart';
import 'package:mennyiment/journal_query.dart';
import 'package:mennyiment/statistics.dart';
import 'package:mennyiment/finance_center.dart';

import 'support/adult_access_fixture.dart';

const journalKey = 'mennyiment_drinks_v1';
const xp = '{"xp":150,"days":[],"completed":[],"future":"keep"}';
List<Map<String, dynamic>> records() => [
  for (var i = 0; i < 2; i++)
    {
      'name': 'Twin',
      'ml': 250.0,
      'percent': 4,
      'priceFt': 'invalid',
      'time': DateTime.now()
          .subtract(const Duration(hours: 1))
          .toIso8601String(),
      'extension': {'keep': true},
    },
];

Future<void> home(
  WidgetTester t, {
  String locale = 'hu',
  bool minor = false,
}) async {
  t.view.physicalSize = const Size(430, 900);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  addTearDown(() async {
    await t.pumpWidget(const SizedBox.shrink());
    await t.pumpAndSettle();
  });
  final list = records();
  list[1] = Map.of(list[0]);
  SharedPreferences.setMockInitialValues({
    adultAccessKey: minor
        ? jsonEncode({'version': 1, 'audience': 'minor', 'complete': true})
        : adultAccessValue,
    'mennyiment_character_setup_complete_v1': true,
    'mennyiment_reduce_motion_v1': true,
    'mennyiment_menti_xp_v2': xp,
    'mennyiment_locale_v1': locale,
    journalKey: jsonEncode(list),
  });
  await t.pumpWidget(const MennyiMentApp());
  await t.pumpAndSettle();
}

Future<void> reveal(WidgetTester t, Finder finder) async {
  for (var attempt = 0; attempt < 60; attempt++) {
    try {
      if (finder.evaluate().isNotEmpty) {
        await t.ensureVisible(finder);
        await t.pumpAndSettle();
        return;
      }
    } on StateError {
      /* A lazy list has not built the first match yet. */
    }
    await t.drag(find.byType(Scrollable).first, const Offset(0, -220));
    await t.pumpAndSettle();
  }
  fail('Control is not reachable: $finder');
}

Future<void> tap(WidgetTester t, Finder finder) async {
  await reveal(t, finder);
  await t.tap(finder);
  await t.pumpAndSettle();
}

Future<void> journal(WidgetTester t) async {
  t.widget<NavigationBar>(find.byType(NavigationBar)).onDestinationSelected!(1);
  await t.pumpAndSettle();
  expect(find.byType(DrinkJournalPage), findsOneWidget);
}

Future<void> enter(WidgetTester t, int i, String text) async {
  final finder = find.byKey(ValueKey('entry-field-$i'));
  await reveal(t, finder);
  await t.enterText(finder, text);
  await t.pumpAndSettle();
}

Future<void> save(WidgetTester t) =>
    tap(t, find.byKey(const ValueKey('entry-save')));
Future<List<dynamic>> persisted() async =>
    jsonDecode((await SharedPreferences.getInstance()).getString(journalKey)!)
        as List;
Future<void> missing(WidgetTester t) async {
  final field = find.byType(DropdownButtonFormField<JournalPrice>);
  await reveal(t, field);
  t.widget<DropdownButtonFormField<JournalPrice>>(field).onChanged!(
    JournalPrice.missing,
  );
  await t.pumpAndSettle();
}

class FaultStore extends InMemorySharedPreferencesStore {
  FaultStore(super.data, {this.gate, this.fail = false}) : super.withData();
  final Completer<void>? gate;
  final bool fail;
  int writes = 0;
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (key == 'flutter.$journalKey') {
      writes++;
      await gate?.future;
      if (fail) return false;
    }
    return super.setValue(type, key, value);
  }
}

Future<FaultStore> fault({Completer<void>? gate, bool fail = false}) async {
  final p = await SharedPreferences.getInstance();
  final store = FaultStore(
    {for (final key in p.getKeys()) 'flutter.$key': p.get(key)!},
    gate: gate,
    fail: fail,
  );
  SharedPreferencesStorePlatform.instance = store;
  return store;
}

void main() {
  for (final locale in ['hu', 'en']) {
    testWidgets(
      '$locale missing-price save updates only selected duplicate and retains all filters',
      (t) async {
        await home(t, locale: locale);
        final before = await persisted();
        await journal(t);
        await t.enterText(find.byKey(const ValueKey('journal-search')), 'twin');
        await t.pumpAndSettle();
        await tap(t, find.text(locale == 'hu' ? 'Hónap' : 'Month'));
        await missing(t);
        final order = find.byType(DropdownButtonFormField<JournalOrder>);
        await reveal(t, order);
        t.widget<DropdownButtonFormField<JournalOrder>>(order).onChanged!(
          JournalOrder.oldest,
        );
        await t.pumpAndSettle();
        await tap(t, find.byKey(const ValueKey('journal-price-1')));
        await enter(t, 3, '0');
        await save(t);
        final after = await persisted();
        expect(after[0], before[0]);
        expect(after[1], {...before[1] as Map, 'priceFt': 0.0});
        expect(find.byType(DrinkJournalPage), findsOneWidget);
        expect(
          t
              .widget<TextField>(find.byKey(const ValueKey('journal-search')))
              .controller!
              .text,
          'twin',
        );
        expect(
          t
              .widget<DropdownButtonFormField<JournalPrice>>(
                find.byType(DropdownButtonFormField<JournalPrice>),
              )
              .initialValue,
          JournalPrice.missing,
        );
        expect(
          t
              .widget<DropdownButtonFormField<JournalOrder>>(
                find.byType(DropdownButtonFormField<JournalOrder>),
              )
              .initialValue,
          JournalOrder.oldest,
        );
        final s = appStrings(t.element(find.byType(DrinkJournalPage)));
        expect(find.text(s.entrySavedFiltered), findsOneWidget);
        await reveal(t, find.byKey(const ValueKey('journal-price-0')));
        expect(find.byKey(const ValueKey('journal-price-1')), findsNothing);
        final p = await SharedPreferences.getInstance();
        expect(p.getString('mennyiment_menti_xp_v2'), xp);
        // A second edit proves that save completion re-enables the live controls.
        await tap(t, find.byKey(const ValueKey('journal-price-0')));
        await enter(t, 3, '12,5');
        await save(t);
        expect((await persisted())[0]['priceFt'], 12.5);
        expect((await persisted())[1]['priceFt'], 0);
      },
    );
  }
  testWidgets(
    'Full edit from home persists all fields and the next journal uses the new values',
    (t) async {
      await home(t);
      final before = await persisted();
      final s = appStrings(
        t.element(find.byType(HomePage, skipOffstage: false)),
      );
      await tap(t, find.text(s.homeMore));
      await tap(t, find.byTooltip(s.homeRecordActions).first);
      await tap(t, find.text(s.entryEdit));
      for (final e in {
        0: 'Changed',
        1: '500',
        2: '0',
        3: '1234.75',
        4: '2026-01-01',
        5: '10:30',
      }.entries) {
        await enter(t, e.key, e.value);
      }
      await save(t);
      final after = await persisted();
      expect(after[1], before[1]);
      expect(after[0]['extension'], before[0]['extension']);
      expect(after[0]['name'], 'Changed');
      expect(after[0]['ml'], 500);
      expect(after[0]['percent'], 0);
      expect(after[0]['priceFt'], 1234.75);
      expect(
        DateTime.parse(after[0]['time'] as String),
        DateTime(2026, 1, 1, 10, 30),
      );
      await journal(t);
      await reveal(t, find.text('Changed'));
      expect(find.text('Changed'), findsOneWidget);
    },
  );
  testWidgets(
    'Persistence is pending before UI update; repeated save produces one write',
    (t) async {
      await home(t);
      final before = await persisted();
      await journal(t);
      await tap(t, find.byKey(const ValueKey('journal-price-1')));
      await enter(t, 3, '12.5');
      final gate = Completer<void>();
      final store = await fault(gate: gate);
      final button = find.byKey(const ValueKey('entry-save'));
      await reveal(t, button);
      final press = t.widget<FilledButton>(button).onPressed!;
      press();
      press();
      await t.pump();
      await t.pump();
      expect(store.writes, 1);
      await (await SharedPreferences.getInstance()).reload();
      expect(await persisted(), before);
      final dynamic state = t.state(find.byType(HomePage, skipOffstage: false));
      expect((state.drinks as List<Drink>)[1].priceFt, isNull);
      gate.complete();
      await t.pumpAndSettle();
      expect((await persisted())[1]['priceFt'], 12.5);
      expect((state.drinks as List<Drink>)[1].priceFt, 12.5);
    },
  );
  testWidgets(
    'Write failure keeps original data and draft without success feedback',
    (t) async {
      await home(t);
      final before = await persisted();
      await journal(t);
      await tap(t, find.byKey(const ValueKey('journal-edit-1')));
      await enter(t, 0, 'Draft');
      await fault(fail: true);
      await save(t);
      expect(await persisted(), before);
      expect(find.byKey(const ValueKey('entry-save-error')), findsOneWidget);
      expect(find.byType(JournalEntryEditor), findsOneWidget);
      final dynamic state = t.state(find.byType(HomePage, skipOffstage: false));
      expect((state.drinks as List<Drink>)[1].name, 'Twin');
      final s = appStrings(t.element(find.byType(JournalEntryEditor)));
      expect(find.text(s.entrySaved), findsNothing);
    },
  );
  testWidgets(
    'External snapshot mismatch cannot overwrite another writer and reload preserves filters',
    (t) async {
      await home(t);
      await journal(t);
      await missing(t);
      await tap(t, find.byKey(const ValueKey('journal-price-1')));
      await enter(t, 3, '99');
      final p = await SharedPreferences.getInstance();
      final external = jsonEncode([
        {...(await persisted())[0] as Map, 'name': 'External'},
      ]);
      await p.setString(journalKey, external);
      await save(t);
      expect(p.getString(journalKey), external);
      expect(find.byKey(const ValueKey('entry-save-error')), findsOneWidget);
      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      await t.tap(find.text('Módosítások elvetése'));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('journal-stale')), findsOneWidget);
      final s = appStrings(t.element(find.byType(DrinkJournalPage)));
      await tap(t, find.text(s.homeJournalRetry));
      expect(find.byKey(const ValueKey('journal-stale')), findsNothing);
      expect(
        t
            .widget<DropdownButtonFormField<JournalPrice>>(
              find.byType(DropdownButtonFormField<JournalPrice>),
            )
            .initialValue,
        JournalPrice.missing,
      );
      await reveal(t, find.text('External'));
      expect(find.text('External'), findsOneWidget);
    },
  );
  for (final view in ['statistics', 'finance']) {
    testWidgets(
      'Already-open $view receives successful persisted edits without losing period',
      (t) async {
        await home(t);
        final dynamic state = t.state(
          find.byType(HomePage, skipOffstage: false),
        );
        final d = (state.drinks as List<Drink>)[0];
        final s = appStrings(
          t.element(find.byType(HomePage, skipOffstage: false)),
        );
        await tap(t, find.text(s.homeMore));
        await tap(
          t,
          find.text(view == 'finance' ? s.financeCenter : s.statisticsNav),
        );
        if (view == 'statistics') {
          await tap(t, find.text(s.month));
        }
        final pending = state.editDrinkPrice(d);
        await t.pumpAndSettle();
        await enter(t, 3, '1234.75');
        await save(t);
        await pending;
        if (view == 'statistics') {
          final page = t.widget<StatisticsPage>(find.byType(StatisticsPage));
          expect(page.drinks[0].priceFt, 1234.75);
          final selected = t.widget<SegmentedButton<StatisticsPeriod>>(
            find.byType(SegmentedButton<StatisticsPeriod>),
          );
          expect(selected.selected, {StatisticsPeriod.month});
        } else {
          expect(
            t
                .widget<FinanceCenterPage>(find.byType(FinanceCenterPage))
                .drinks[0]
                .priceFt,
            1234.75,
          );
        }
        expect(find.byType(JournalEntryEditor), findsNothing);
        await reveal(t, find.text(localeCurrency(1234.75, 'hu')).first);
        expect(find.text(localeCurrency(1234.75, 'hu')), findsWidgets);
        expect(t.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'External change on resume is explicitly marked in an open view',
    (t) async {
      await home(t);
      await journal(t);
      final p = await SharedPreferences.getInstance();
      await p.setString(journalKey, '[]');
      final dynamic state = t.state(find.byType(HomePage, skipOffstage: false));
      state.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('journal-stale')), findsOneWidget);
      expect(p.getString(journalKey), '[]');
      await reveal(t, find.byKey(const ValueKey('journal-edit-0')));
      expect(
        t
            .widget<TextButton>(find.byKey(const ValueKey('journal-edit-0')))
            .onPressed,
        isNull,
      );
    },
  );
  testWidgets(
    'Clearing a known zero price returns that exact record to missing prices',
    (t) async {
      await home(t);
      final p = await SharedPreferences.getInstance();
      final initial = await persisted();
      initial[0]['priceFt'] = 0;
      await p.setString(journalKey, jsonEncode(initial));
      final dynamic state = t.state(find.byType(HomePage));
      await state.loadDrinks();
      await t.pumpAndSettle();
      await journal(t);
      final filter = find.byType(DropdownButtonFormField<JournalPrice>);
      await reveal(t, filter);
      t.widget<DropdownButtonFormField<JournalPrice>>(filter).onChanged!(
        JournalPrice.known,
      );
      await t.pumpAndSettle();
      await tap(t, find.byKey(const ValueKey('journal-price-0')));
      await tap(t, find.text('Ár törlése'));
      await save(t);
      final after = await persisted();
      expect(after[0], Map.of(initial[0] as Map)..remove('priceFt'));
      expect(after[1], initial[1]);
      final s = appStrings(t.element(find.byType(DrinkJournalPage)));
      expect(find.text(s.entrySavedFiltered), findsOneWidget);
      await reveal(t, filter);
      t.widget<DropdownButtonFormField<JournalPrice>>(filter).onChanged!(
        JournalPrice.missing,
      );
      await t.pumpAndSettle();
      await reveal(t, find.byKey(const ValueKey('journal-price-0')));
      expect(find.byKey(const ValueKey('journal-price-0')), findsOneWidget);
    },
  );
  testWidgets(
    'Minor cannot open the editor through the existing public price path',
    (t) async {
      await home(t, minor: true);
      final before = await persisted();
      final dynamic state = t.state(find.byType(HomePage, skipOffstage: false));
      await state.editDrinkPrice((state.drinks as List<Drink>)[0]);
      await t.pumpAndSettle();
      expect(find.byType(JournalEntryEditor), findsNothing);
      expect(await persisted(), before);
    },
  );
}
