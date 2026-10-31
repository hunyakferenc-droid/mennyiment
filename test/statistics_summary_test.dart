import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mennyiment/statistics_summary.dart';

StatisticsDrink drink(DateTime time, {double? price}) => StatisticsDrink(
  name: 'Teszt',
  ml: 250,
  percent: 4,
  time: time,
  priceFt: price,
);

void main() {
  test('Week uses Monday start and exclusive next Monday', () {
    final range = StatisticsRange.forPeriod(
      StatisticsPeriod.week,
      DateTime(2026, 3, 29, 23),
    );
    expect(range.start, DateTime(2026, 3, 23));
    expect(range.end, DateTime(2026, 3, 30));
    expect(range.days, 7);
    expect(range.contains(range.start), isTrue);
    expect(range.contains(range.end), isFalse);
  });
  for (final date in [DateTime(2026, 3, 29), DateTime(2026, 10, 25)]) {
    test('DST week at $date has seven distinct calendar dates', () {
      final range = StatisticsRange.forPeriod(StatisticsPeriod.week, date);
      final dates = List.generate(
        range.days,
        (i) => StatisticsRange.addDays(range.start, i),
      );
      expect(dates.length, 7);
      expect(dates.toSet().length, 7);
      expect(dates.every((d) => d.hour == 0), isTrue);
      expect(StatisticsRange.addDays(dates.last, 1), range.end);
      if (Platform.environment['TZ'] == 'Europe/Budapest') {
        expect(
          range.end.difference(range.start).inHours,
          date.month == 3 ? 167 : 169,
        );
      }
    });
  }
  test('Month and year boundaries account for leap years', () {
    expect(
      StatisticsRange.forPeriod(
        StatisticsPeriod.month,
        DateTime(2024, 2, 15),
      ).days,
      29,
    );
    expect(
      StatisticsRange.forPeriod(
        StatisticsPeriod.month,
        DateTime(2026, 3, 15),
      ).days,
      31,
    );
    expect(
      StatisticsRange.forPeriod(StatisticsPeriod.year, DateTime(2024, 2)).days,
      366,
    );
    final range = StatisticsRange.forPeriod(
      StatisticsPeriod.week,
      DateTime(2026, 1, 1),
    );
    expect(range.start, DateTime(2025, 12, 29));
    expect(range.end, DateTime(2026, 1, 5));
  });
  test(
    'Prices include zero and report incomplete totals without changing input',
    () {
      final date = DateTime(2026, 3, 25);
      final input = [
        drink(date, price: 1000),
        drink(date, price: 500),
        drink(date),
        drink(date, price: 0),
      ];
      final summary = StatisticsSummary(
        input,
        StatisticsRange.forPeriod(StatisticsPeriod.month, date),
        date,
      );
      expect(summary.knownCostFt, 1500);
      expect(summary.pricedCount, 3);
      expect(summary.missingPriceCount, 1);
      expect(input[2].priceFt, isNull);
      expect(() => summary.items.clear(), throwsUnsupportedError);
    },
  );
  test(
    'Invalid prices remain unknown rather than reducing or corrupting totals',
    () {
      final date = DateTime(2026, 3, 25);
      final summary = StatisticsSummary(
        [
          drink(date, price: -100),
          drink(date, price: double.nan),
          drink(date, price: double.infinity),
          drink(date, price: 250),
        ],
        StatisticsRange.forPeriod(StatisticsPeriod.week, date),
        date,
      );
      expect(summary.knownCostFt, 250);
      expect(summary.missingPriceCount, 3);
    },
  );
  test('Range filtering includes start, excludes end and excludes unrelated prices', () {
    final range = StatisticsRange.forPeriod(
      StatisticsPeriod.month,
      DateTime(2026, 3),
    );
    final summary = StatisticsSummary(
      [
        drink(range.start, price: 100),
        drink(range.end, price: 200),
        drink(DateTime(2026, 2, 28, 23, 59), price: 300),
      ],
      range,
      DateTime(2026, 4, 1),
    );
    expect(summary.items.length, 1);
    expect(summary.knownCostFt, 100);
  });
  test('Multiple drinks on one day count as one logged day', () {
    final now = DateTime(2026, 3, 25, 12);
    final summary = StatisticsSummary(
      [drink(now), drink(now)],
      StatisticsRange.forPeriod(StatisticsPeriod.week, now),
      now,
    );
    expect(summary.elapsedDays, 3);
    expect(summary.unloggedDays, 2);
  });
  test('Future records do not subtract from elapsed unlogged dates', () {
    final now = DateTime(2026, 3, 25);
    final summary = StatisticsSummary(
      [drink(DateTime(2026, 3, 29))],
      StatisticsRange.forPeriod(StatisticsPeriod.week, now),
      now,
    );
    expect(summary.unloggedDays, 3);
  });
  test(
    'Empty and future periods have no fictitious confirmed alcohol-free days',
    () {
      final now = DateTime(2026, 3, 25);
      final future = StatisticsSummary(
        [],
        StatisticsRange.forPeriod(StatisticsPeriod.month, DateTime(2026, 4)),
        now,
      );
      expect(future.elapsedDays, 0);
      expect(future.unloggedDays, 0);
      expect(future.knownCostFt, 0);
      expect(future.missingPriceCount, 0);
    },
  );
  test('Full March contains 31 observed days across spring clock change', () {
    final summary = StatisticsSummary(
      [],
      StatisticsRange.forPeriod(StatisticsPeriod.month, DateTime(2026, 3)),
      DateTime(2026, 4, 1),
    );
    expect(summary.elapsedDays, 31);
    expect(summary.unloggedDays, 31);
  });
  test('UTC instants group by their local civil date', () {
    final instant = DateTime.utc(2026, 3, 28, 23, 30);
    final local = instant.toLocal();
    expect(
      StatisticsRange.day(instant),
      DateTime(local.year, local.month, local.day),
    );
    if (Platform.environment['TZ'] == 'Europe/Budapest') {
      expect(StatisticsRange.day(instant), DateTime(2026, 3, 29));
    }
  });
}
