import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mennyiment/drink_journal.dart';

Map<String, dynamic> raw() => {
  'name': '  Sör (általános)  ',
  'ml': 250.0,
  'percent': 4,
  'time': '2026-10-25T02:15:12.123456+02:00',
  'priceFt': 'historic-invalid',
  'future': {
    'nested': [1, 'keep', null],
  },
};

void main() {
  test('Unchanged edit keeps every raw value, type, offset and extension', () {
    final source = raw(), drink = Drink.fromJson(raw());
    final edited = drink.edited(
      name: drink.name,
      ml: drink.ml,
      percent: drink.percent,
      time: drink.time,
    );
    expect(jsonEncode(edited.toJson()), jsonEncode(source));
    expect(edited.toJson()['ml'], isA<double>());
    expect(edited.toJson()['percent'], isA<int>());
    expect(drink.toJson(), source);
  });
  final changes = <String, Drink Function(Drink)>{
    'name': (d) => d.edited(name: 'Saját ital'),
    'ml': (d) => d.edited(ml: 330),
    'percent': (d) => d.edited(percent: 0),
    'time': (d) => d.edited(time: DateTime(2026, 10, 24, 18, 30)),
    'priceFt': (d) => d.edited(editPrice: true, priceFt: 1234.75),
  };
  for (final entry in changes.entries) {
    test(
      '${entry.key} patches only the selected field and preserves the source',
      () {
        final before = raw(), drink = Drink.fromJson(raw());
        final after = entry.value(drink).toJson();
        expect(after[entry.key], isNot(before[entry.key]));
        for (final key in before.keys.where((k) => k != entry.key)) {
          expect(jsonEncode(after[key]), jsonEncode(before[key]), reason: key);
        }
        expect(drink.toJson(), before);
      },
    );
  }
  test('Explicit removal clears an invalid historic price without repairing anything else', () {
    final source = raw();
    expect(
      Drink.fromJson(source).edited(editPrice: true).toJson(),
      Map.of(source)..remove('priceFt'),
    );
  });
  for (final value in [0.0, 12.5, 10000000.0]) {
    test('Price $value stays known and can be removed again', () {
      final drink = Drink.fromJson(raw())
          .edited(editPrice: true, priceFt: value);
      expect(drink.priceFt, value);
      expect(
        drink.edited(editPrice: true).toJson().containsKey('priceFt'),
        isFalse,
      );
    });
  }
  test('Equal numeric values preserve the original raw integer price', () {
    final source = raw()..['priceFt'] = 0;
    expect(
      Drink.fromJson(source)
          .edited(editPrice: true, priceFt: 0)
          .toJson()['priceFt'],
      isA<int>(),
    );
  });
  test('Identical content remains separate and a copy does not modify either source', () {
    final a = Drink.fromJson(raw()), b = Drink.fromJson(raw());
    final source = [a, b];
    final next = List<Drink>.of(source);
    next[1] = b.edited(name: 'Changed');
    expect(identical(next[0], a), isTrue);
    expect(source.map((d) => d.toJson()), [raw(), raw()]);
    expect(next[1].name, 'Changed');
  });
}
