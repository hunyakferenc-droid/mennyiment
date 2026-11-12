import 'dart:convert';
import 'dart:io';

import 'package:mennyiment/drink_journal.dart';
import 'package:mennyiment/journal_query.dart';

void main() {
  var checks = 0;
  void check(bool result, String name) {
    if (!result) throw StateError(name);
    checks++;
  }

  final anchor = DateTime(2026, 11, 12, 16);
  final raw = {
    'name': 'Őszibarack üdítő',
    'ml': 250,
    'percent': 0,
    'time': anchor.toIso8601String(),
    'priceFt': 'invalid',
    'future': 'preserve',
  };
  final unknown = Drink.fromJson(raw);
  final zero = Drink('Ingyenes', 500, 0, time: anchor, priceFt: 0);
  final paid = Drink('Fizetős', 330, 4, time: anchor, priceFt: 1234.75);
  final old = Drink(
    'Korábbi',
    100,
    4,
    time: DateTime(2026, 10, 1),
    priceFt: 100,
  );
  final source = [unknown, zero, paid, old];
  final before = jsonEncode(source.map((d) => d.toJson()).toList());
  check(
    const JournalQuery(search: ' OSZIBARACK UDITO ')
            .apply(source, anchor)
            .single ==
        unknown,
    'Hungarian accent search',
  );
  check(
    const JournalQuery(search: 'barack beer').apply(source, anchor).isEmpty,
    'All search terms required',
  );
  check(
    const JournalQuery(search: 'peach')
            .apply(source, anchor, label: (_) => 'Peach')
            .length ==
        4,
    'Localized names searchable',
  );
  check(
    const JournalQuery(price: JournalPrice.missing)
            .apply(source, anchor)
            .single ==
        unknown,
    'Missing filter',
  );
  check(
    const JournalQuery(price: JournalPrice.known)
        .apply(source, anchor)
        .contains(zero),
    'Real zero known',
  );
  check(
    const JournalQuery(period: JournalPeriod.month)
            .apply(source, anchor)
            .length ==
        3,
    'Current month',
  );
  check(
    const JournalQuery(period: JournalPeriod.month)
            .apply(source, DateTime(2026, 10))
            .single ==
        old,
    'Previous month',
  );
  check(
    const JournalQuery(order: JournalOrder.priceHighest)
            .apply(source, anchor)
            .first ==
        paid,
    'Price sort',
  );
  check(
    const JournalQuery(order: JournalOrder.priceHighest)
            .apply(source, anchor)
            .last ==
        unknown,
    'Unknown sorted last',
  );
  check(
    const JournalQuery(order: JournalOrder.oldest)
            .apply(source, anchor)
            .first ==
        old,
    'Oldest first',
  );
  final duplicate = Drink('Fizetős', 330, 4, time: anchor, priceFt: 1234.75);
  final sorted = const JournalQuery().apply([paid, duplicate], anchor);
  check(
    identical(sorted[0], paid) && identical(sorted[1], duplicate),
    'Stable duplicates',
  );
  var immutable = false;
  try {
    sorted.clear();
  } on UnsupportedError {
    immutable = true;
  }
  check(immutable, 'Immutable result');
  for (final period in JournalPeriod.values.where(
    (p) => p != JournalPeriod.all,
  )) {
    final query = JournalQuery(period: period);
    final range = query.range(anchor)!;
    check(range.contains(range.start), '$period inclusive start');
    check(!range.contains(range.end), '$period exclusive end');
  }
  final leap = const JournalQuery(period: JournalPeriod.month)
      .range(DateTime(2024, 2, 29))!;
  check(leap.days == 29, 'Leap February');
  final dst = const JournalQuery(period: JournalPeriod.day)
      .range(DateTime(2026, 3, 29))!;
  check(
    dst.days == 1 && dst.end == DateTime(2026, 3, 30),
    'DST calendar boundaries',
  );
  check(
    dst.end.difference(dst.start).inHours == 23,
    'Budapest spring day has 23 hours',
  );
  final totals = JournalTotals(source);
  check(totals.count == 4 && totals.ml == 1180, 'Count and volume');
  check(
    totals.knownCost == 1334.75 &&
        totals.pricedCount == 3 &&
        totals.missingCount == 1,
    'Cost and coverage',
  );
  for (final bad in [-1.0, double.nan, double.infinity, 10000001.0]) {
    check(
      !JournalQuery.hasPrice(Drink('bad', 1, 0, priceFt: bad)),
      'Reject invalid price',
    );
  }
  check(
    jsonEncode(source.map((d) => d.toJson()).toList()) == before,
    'Source JSON unchanged',
  );
  check(
    jsonEncode(unknown.toJson()) == jsonEncode(raw),
    'Unknown historic fields unchanged',
  );
  stdout.writeln(
    '$checks model assertions passed; timezone: ${anchor.timeZoneName}',
  );
}
