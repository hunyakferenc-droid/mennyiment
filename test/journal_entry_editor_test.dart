import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mennyiment/drink_journal.dart';
import 'package:mennyiment/journal_entry_editor.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';

final clock = DateTime(2026, 11, 12, 20, 45);
Drink fixture() => Drink.fromJson({
  'name': 'Original',
  'ml': 250.0,
  'percent': 4,
  'time': '2026-11-12T13:15:12.123456',
  'priceFt': 'bad',
  'extension': {'keep': true},
});

Future<void> openEditor(
  WidgetTester t,
  Future<bool> Function(Drink) save, {
  String locale = 'hu',
  double width = 430,
  double scale = 1,
  double height = 900,
  bool priceOnly = false,
  Drink? drink,
}) async {
  t.view.physicalSize = Size(width, height);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  addTearDown(() async {
    await t.pumpWidget(const SizedBox.shrink());
    await t.pumpAndSettle();
  });
  await t.pumpWidget(
    MaterialApp(
      locale: Locale(locale),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Builder(
        builder: (c) => TextButton(
          onPressed: () => Navigator.push<bool>(
            c,
            MaterialPageRoute(
              builder: (_) => JournalEntryEditor(
                drink: drink ?? fixture(),
                onSave: save,
                priceOnly: priceOnly,
                clock: () => clock,
              ),
            ),
          ),
          child: const Text('Open'),
        ),
      ),
    ),
  );
  await t.tap(find.text('Open'));
  await t.pumpAndSettle();
}

Finder field(int i) => find.byKey(ValueKey('entry-field-$i'));
Future<void> enter(WidgetTester t, int i, String value) async {
  if (field(i).evaluate().isEmpty) {
    await t.scrollUntilVisible(
      field(i),
      160,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 60,
    );
  }
  await t.ensureVisible(field(i));
  await t.pumpAndSettle();
  await t.enterText(field(i), value);
  await t.pumpAndSettle();
}

Future<void> save(WidgetTester t) async {
  final button = find.byKey(const ValueKey('entry-save'));
  if (button.evaluate().isEmpty) {
    await t.scrollUntilVisible(
      button,
      160,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 60,
    );
  }
  await t.ensureVisible(button);
  await t.pumpAndSettle();
  await t.tap(button);
  await t.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting());
  for (final locale in ['hu', 'en']) {
    testWidgets('$locale saves all six fields only after success', (t) async {
      Drink? saved;
      await openEditor(t, (d) async {
        saved = d;
        return true;
      }, locale: locale);
      for (final entry in {
        0: 'Changed',
        1: '330,0',
        2: '5,5',
        3: '1234,75',
        4: '2026-11-11',
        5: '18:30',
      }.entries) {
        await enter(t, entry.key, entry.value);
      }
      expect(saved, isNull);
      await save(t);
      expect(saved!.name, 'Changed');
      expect(saved!.ml, 330);
      expect(saved!.percent, 5.5);
      expect(saved!.priceFt, 1234.75);
      expect(saved!.time, DateTime(2026, 11, 11, 18, 30));
      expect(saved!.toJson()['extension'], {'keep': true});
      expect(find.text('Open'), findsOneWidget);
    });
  }
  testWidgets(
    'Untouched save preserves raw timestamp, invalid price and numeric types',
    (t) async {
      Drink? result;
      final original = fixture();
      await openEditor(t, (d) async {
        result = d;
        return true;
      });
      await save(t);
      expect(result!.toJson(), original.toJson());
      expect(result!.toJson()['ml'], isA<double>());
      expect(result!.toJson()['percent'], isA<int>());
    },
  );
  testWidgets(
    'Cancel and system Back require one discard confirmation and never write',
    (t) async {
      var calls = 0;
      await openEditor(t, (d) async {
        calls++;
        return true;
      });
      await enter(t, 0, 'Unsaved');
      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await t.tap(find.text('Szerkesztés folytatása'));
      await t.pumpAndSettle();
      expect(t.widget<TextFormField>(field(0)).controller!.text, 'Unsaved');
      final cancel = find.widgetWithText(TextButton, 'Mégse');
      await t.ensureVisible(cancel);
      await t.tap(cancel);
      await t.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await t.tap(find.text('Módosítások elvetése'));
      await t.pumpAndSettle();
      expect(calls, 0);
      expect(find.text('Open'), findsOneWidget);
    },
  );
  testWidgets('Unchanged Back exits without writing or prompting', (t) async {
    var calls = 0;
    await openEditor(t, (d) async {
      calls++;
      return true;
    });
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(calls, 0);
  });
  testWidgets(
    'Double save and Back while pending invoke one writer; failure retains the draft',
    (t) async {
      final pending = Completer<bool>();
      var calls = 0;
      await openEditor(t, (d) {
        calls++;
        return pending.future;
      });
      await enter(t, 0, 'Draft');
      final button = find.byKey(const ValueKey('entry-save'));
      await t.ensureVisible(button);
      await t.pumpAndSettle();
      final press = t.widget<FilledButton>(button).onPressed!;
      press();
      press();
      await t.pump();
      await t.binding.handlePopRoute();
      await t.pump();
      expect(calls, 1);
      expect(find.byType(AlertDialog), findsNothing);
      pending.complete(false);
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('entry-save-error')), findsOneWidget);
      expect(t.widget<TextFormField>(field(0)).controller!.text, 'Draft');
      expect(find.byType(JournalEntryEditor), findsOneWidget);
    },
  );
  testWidgets(
    'Thrown write failure stays open and a successful retry can close',
    (t) async {
      var calls = 0;
      await openEditor(t, (d) async {
        if (++calls == 1) throw StateError('write');
        return true;
      });
      await enter(t, 3, '0');
      await save(t);
      expect(find.byType(JournalEntryEditor), findsOneWidget);
      expect(find.byKey(const ValueKey('entry-save-error')), findsOneWidget);
      await save(t);
      expect(calls, 2);
      expect(find.text('Open'), findsOneWidget);
    },
  );
  for (final invalid in [
    (0, ''),
    (1, '0'),
    (1, '10001'),
    (1, '1.5'),
    (1, 'NaN'),
    (2, '-1'),
    (2, '101'),
    (2, 'Infinity'),
    (3, '-1'),
    (3, '10000001'),
    (3, 'NaN'),
    (3, '1e309'),
    (4, '2026-02-30'),
    (4, '2026-11-13'),
    (5, '25:00'),
    (5, '9:ab'),
  ]) {
    testWidgets(
      'Invalid field ${invalid.$1} ${invalid.$2} never invokes persistence',
      (t) async {
        var calls = 0;
        await openEditor(t, (d) async {
          calls++;
          return true;
        });
        await enter(t, invalid.$1, invalid.$2);
        await save(t);
        expect(calls, 0);
        expect(find.byType(JournalEntryEditor), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );
  }
  testWidgets('Nonexistent Budapest DST time is rejected', (t) async {
    expect(DateTime(2026, 3, 29).timeZoneOffset, const Duration(hours: 1));
    var calls = 0;
    await openEditor(t, (d) async {
      calls++;
      return true;
    });
    await enter(t, 4, '2026-03-29');
    await enter(t, 5, '02:30');
    await save(t);
    expect(calls, 0);
    expect(find.byKey(const ValueKey('entry-date-error')), findsOneWidget);
  });
  testWidgets(
    'Existing future time can remain raw while another field changes',
    (t) async {
      final original = Drink.fromJson({
        ...fixture().toJson(),
        'time': '2030-01-01T13:15:12.123456Z',
      });
      Drink? result;
      await openEditor(t, (d) async {
        result = d;
        return true;
      }, drink: original);
      await enter(t, 0, 'Changed');
      await save(t);
      expect(result!.toJson()['time'], original.toJson()['time']);
    },
  );
  testWidgets('Date-only change retains the unchanged time precision', (
    t,
  ) async {
    Drink? result;
    await openEditor(t, (d) async {
      result = d;
      return true;
    });
    await enter(t, 4, '2026-11-11');
    await save(t);
    expect(result!.time, DateTime(2026, 11, 11, 13, 15, 12, 123, 456));
  });
  for (final date in ['2024-02-29', '2025-12-31']) {
    testWidgets(
      'Valid leap/year boundary $date is accepted without changing other fields',
      (t) async {
        Drink? result;
        await openEditor(t, (d) async {
          result = d;
          return true;
        });
        await enter(t, 4, date);
        await save(t);
        expect(result!.time, DateTime.parse('${date}T13:15:12.123456'));
        expect(
          result!.toJson()..remove('time'),
          fixture().toJson()..remove('time'),
        );
      },
    );
  }
  for (final value in ['0', '0,00', '12.5', '12,5', '10000000']) {
    testWidgets(
      'Price-only mode accepts $value and preserves every other raw field',
      (t) async {
        Drink? result;
        await openEditor(t, (d) async {
          result = d;
          return true;
        }, priceOnly: true);
        await enter(t, 3, value);
        await save(t);
        expect(result!.priceFt, double.parse(value.replaceAll(',', '.')));
        expect(
          result!.toJson()..remove('priceFt'),
          fixture().toJson()..remove('priceFt'),
        );
      },
    );
  }
  testWidgets('Explicit price removal removes invalid history too', (t) async {
    Drink? result;
    await openEditor(t, (d) async {
      result = d;
      return true;
    }, priceOnly: true);
    await t.tap(find.text('Ár törlése'));
    await save(t);
    expect(result!.toJson().containsKey('priceFt'), isFalse);
  });
  for (final locale in ['hu', 'en']) {
    for (final width in [320.0, 360.0, 390.0, 430.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          '$locale $width / $scale: all fields and save reachable with keyboard',
          (t) async {
            Drink? result;
            await openEditor(
              t,
              (d) async {
                result = d;
                return true;
              },
              locale: locale,
              width: width,
              scale: scale,
              height: 640,
            );
            t.view.viewInsets = const FakeViewPadding(bottom: 280);
            addTearDown(t.view.resetViewInsets);
            await enter(t, 0, 'Mobile');
            await enter(t, 1, '10000');
            await enter(t, 2, '100');
            await enter(t, 3, '0');
            await enter(t, 4, '2026-11-11');
            await enter(t, 5, '23:59');
            await save(t);
            expect(result!.name, 'Mobile');
            expect(result!.ml, 10000);
            expect(result!.percent, 100);
            expect(result!.priceFt, 0);
            expect(result!.time, DateTime(2026, 11, 11, 23, 59));
            expect(t.takeException(), isNull);
          },
        );
      }
    }
  }
}
