import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mennyiment/drink_journal.dart';
import 'package:mennyiment/journal_query.dart';

Drink record(String name, DateTime time, {double? price, int ml = 250}) =>
    Drink(name, ml, 4, time: time, priceFt: price);

void main() {
  final anchor = DateTime(2026, 11, 12, 16);
  test('Search folds Hungarian accents and requires all words', () {
    final drinks = [
      record('Őszibarack üdítő', anchor),
      record('Barack', anchor),
    ];
    expect(
      const JournalQuery(search: '  OSZIBARACK UDITO ').apply(drinks, anchor),
      [drinks.first],
    );
    expect(
      const JournalQuery(search: 'barack sör').apply(drinks, anchor),
      isEmpty,
    );
  });
  test('Search includes translated catalog labels without changing names', () {
    final drink = record('Sör (általános)', anchor);
    expect(
      const JournalQuery(search: 'beer')
          .apply([drink], anchor, label: (_) => 'Beer'),
      [drink],
    );
    expect(drink.name, 'Sör (általános)');
  });
  test('Whitespace search retains all entries including duplicates', () {
    final drinks = [record('A', anchor), record('A', anchor)];
    expect(const JournalQuery(search: ' \t ').apply(drinks, anchor), drinks);
  });
  for (final entry in [
    (JournalPeriod.day, DateTime(2026, 11, 12), DateTime(2026, 11, 13)),
    (JournalPeriod.week, DateTime(2026, 11, 9), DateTime(2026, 11, 16)),
    (JournalPeriod.month, DateTime(2026, 11), DateTime(2026, 12)),
    (JournalPeriod.year, DateTime(2026), DateTime(2027)),
  ]) {
    test('${entry.$1} includes start and excludes end', () {
      final start = record('start', entry.$2);
      final last = record(
        'last',
        entry.$3.subtract(const Duration(microseconds: 1)),
      );
      final drinks = [
        record('before', entry.$2.subtract(const Duration(microseconds: 1))),
        start,
        last,
        record('end', entry.$3),
      ];
      final result = JournalQuery(
        period: entry.$1,
        order: JournalOrder.oldest,
      ).apply(drinks, anchor);
      expect(result, [start, last]);
    });
  }
  test('Calendar ranges handle leap years and December', () {
    final query = const JournalQuery(period: JournalPeriod.month);
    expect(query.range(DateTime(2024, 2, 29))!.days, 29);
    expect(query.range(DateTime(2026, 12, 31))!.end, DateTime(2027));
  });
  test('DST civil day is bounded by local midnights', () {
    final query = const JournalQuery(period: JournalPeriod.day);
    final range = query.range(DateTime(2026, 3, 29, 12))!;
    expect(range.start, DateTime(2026, 3, 29));
    expect(range.end, DateTime(2026, 3, 30));
    expect(range.days, 1);
  });
  test('UTC instants are classified by the selected local day', () {
    final instant = DateTime.utc(2026, 3, 29, 23, 30);
    final drink = record('UTC', instant);
    expect(
      const JournalQuery(period: JournalPeriod.day)
          .apply([drink], instant.toLocal()),
      [drink],
    );
  });
  test('Unknown historic prices are missing, a genuine zero is known', () {
    final raw = {
      'name': 'Historic',
      'ml': 250,
      'percent': 4,
      'time': anchor.toIso8601String(),
      'priceFt': 'invalid',
      'extra': [1, 2],
    };
    final historic = Drink.fromJson(raw);
    final zero = record('Free', anchor, price: 0);
    final paid = record('Paid', anchor, price: 1234.75);
    final missing = record('Unknown', anchor);
    final drinks = [historic, zero, paid, missing];
    expect(
      const JournalQuery(price: JournalPrice.missing).apply(drinks, anchor),
      [historic, missing],
    );
    expect(
      const JournalQuery(price: JournalPrice.known).apply(drinks, anchor),
      [zero, paid],
    );
    expect(historic.toJson(), raw);
  });
  test('Out of range and nonfinite in-memory prices remain unknown', () {
    for (final price in [-1.0, double.nan, double.infinity, 10000001.0]) {
      expect(
        JournalQuery.hasPrice(record('bad', anchor, price: price)),
        isFalse,
      );
    }
    expect(
      JournalQuery.hasPrice(record('max', anchor, price: 10000000)),
      isTrue,
    );
  });
  test('Highest price puts unknown values last and uses time for ties', () {
    final drinks = [
      record('unknown', anchor),
      record('zero', anchor, price: 0),
      record('older', DateTime(2026, 11, 11), price: 10),
      record('newer', anchor, price: 10),
    ];
    expect(
      const JournalQuery(order: JournalOrder.priceHighest)
          .apply(drinks, anchor)
          .map((d) => d.name),
      ['newer', 'older', 'zero', 'unknown'],
    );
  });
  test('Stable sort retains identical records and never mutates source', () {
    final a = record('A', anchor);
    final b = record('B', DateTime(2026, 11, 11));
    final duplicate = record('A', anchor);
    final drinks = [b, a, duplicate];
    final before = jsonEncode(drinks.map((d) => d.toJson()).toList());
    final result = const JournalQuery().apply(drinks, anchor);
    expect(result, [a, duplicate, b]);
    expect(identical(result[1], duplicate), isTrue);
    expect(jsonEncode(drinks.map((d) => d.toJson()).toList()), before);
    expect(() => result.clear(), throwsUnsupportedError);
  });
  test('Oldest first sorts chronologically', () {
    final drinks = [record('new', anchor), record('old', DateTime(2020))];
    expect(
      const JournalQuery(order: JournalOrder.oldest)
          .apply(drinks, anchor)
          .first,
      drinks.last,
    );
  });
  test('Combined filters and totals describe only matching entries', () {
    final drinks = [
      record('Sör', anchor, price: 12.5, ml: 500),
      record('Sör', anchor, ml: 330),
      record('Víz', anchor, price: 900),
      record('Sör', DateTime(2020), price: 700),
    ];
    final matches = const JournalQuery(
      search: 'sor',
      period: JournalPeriod.month,
    ).apply(drinks, anchor);
    final totals = JournalTotals(matches);
    expect(totals.count, 2);
    expect(totals.ml, 830);
    expect(totals.knownCost, 12.5);
    expect(totals.pricedCount, 1);
    expect(totals.missingCount, 1);
  });
  test('Empty totals do not invent price coverage', () {
    final totals = JournalTotals([]);
    expect(totals.count, 0);
    expect(totals.pricedCount, 0);
    expect(totals.missingCount, 0);
    expect(totals.knownCost, 0);
  });
}
