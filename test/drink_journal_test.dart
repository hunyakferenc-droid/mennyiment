import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mennyiment/drink_journal.dart';

Map<String, dynamic> legacy({Object? price, bool includePrice = true}) => {
  'name': 'Régi ital',
  'ml': 250,
  'percent': 4,
  'time': '2026-10-25T01:30:00.000Z',
  if (includePrice) 'priceFt': price,
  'futureField': {'keep': true},
};

void main() {
  for (final price in <Object?>[
    null,
    0,
    1250,
    12.5,
    -1,
    'rossz',
    double.nan,
    double.infinity,
  ]) {
    test(
      'Legacy price $price is safely displayed and round-tripped without erasure',
      () {
        final source = legacy(price: price);
        final drink = Drink.fromJson(source);
        expect(
          drink.priceFt,
          price is num && price.isFinite && price >= 0 ? price : null,
        );
        // NaN is intentionally retained as the identical source object here; JSON input itself cannot contain NaN.
        if (price is! double || !price.isNaN) expect(drink.toJson(), source);
        expect(drink.toJson()['futureField'], {'keep': true});
        expect(drink.time, DateTime.utc(2026, 10, 25, 1, 30));
      },
    );
  }
  test('Missing price stays missing; numeric and timezone representation survive save', () {
    final source = legacy(includePrice: false);
    final drink = Drink.fromJson(source);
    expect(drink.priceFt, isNull);
    expect(jsonEncode(drink.toJson()), jsonEncode(source));
    expect(drink.alcoholGrams, closeTo(7.89, 0.001));
  });
  test('Explicit price edits preserve unknown fields and do not mutate original record', () {
    final source = legacy(price: 'unknown');
    final drink = Drink.fromJson(source);
    final edited = drink.withPrice(0);
    expect(drink.toJson(), source);
    expect(edited.toJson(), {...source, 'priceFt': 0.0});
    expect(edited.withPrice(null).toJson().containsKey('priceFt'), isFalse);
    expect(edited.toJson()['futureField'], {'keep': true});
  });
  for (final patch in <Map<String, dynamic>>[
    {'name': ''},
    {'name': 42},
    {'ml': 0},
    {'ml': -1},
    {'ml': 10001},
    {'ml': 1.5},
    {'ml': '250'},
    {'percent': -1},
    {'percent': 101},
    {'percent': double.nan},
    {'time': 'not-a-date'},
    {'time': '2026-02-31T12:00:00.000'},
    {'time': '2026-13-01T12:00:00.000'},
    {'time': '2026-01-01T25:61:00'},
    {'time': '2026-01-01T12:00:60'},
    {'time': '2026-01-01T12:00:00+24:00'},
  ]) {
    test('Ambiguous required data $patch is rejected, not guessed', () {
      expect(
        () => Drink.fromJson({...legacy(), ...patch}),
        throwsFormatException,
      );
    });
  }
  test('Boundary amounts and historic/future valid dates remain readable', () {
    for (final ml in [1, 10000]) {
      for (final percent in [0, 100]) {
        for (final time in [
          '2000-02-29T00:00:00.000',
          '2099-12-31T23:59:00.000',
        ]) {
          final source = {
            ...legacy(),
            'ml': ml,
            'percent': percent,
            'time': time,
          };
          expect(Drink.fromJson(source).toJson(), source);
        }
      }
    }
  });
}
