/// Read-only projection of a drink; existing persisted Drink data is unchanged.
class StatisticsDrink {
  final String name;
  final int ml;
  final double percent;
  final DateTime time;
  final double? priceFt;

  const StatisticsDrink({
    required this.name,
    required this.ml,
    required this.percent,
    required this.time,
    this.priceFt,
  });

  double get grams => ml * percent / 100 * 0.789;
  bool get hasKnownPrice =>
      priceFt != null && priceFt!.isFinite && priceFt! >= 0;
}

enum StatisticsPeriod { week, month, year }

/// Local calendar boundaries, with an inclusive start and exclusive end.
class StatisticsRange {
  const StatisticsRange(this.start, this.end);
  final DateTime start;
  final DateTime end;

  static DateTime day(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static DateTime addDays(DateTime date, int days) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day + days);
  }

  // Count civil dates, not elapsed 24-hour durations across DST transitions.
  static int calendarDays(DateTime start, DateTime end) => DateTime.utc(
    end.year,
    end.month,
    end.day,
  ).difference(DateTime.utc(start.year, start.month, start.day)).inDays;

  factory StatisticsRange.forPeriod(StatisticsPeriod period, DateTime anchor) {
    final date = day(anchor);
    switch (period) {
      case StatisticsPeriod.week:
        final start = addDays(date, 1 - date.weekday);
        return StatisticsRange(start, addDays(start, 7));
      case StatisticsPeriod.month:
        return StatisticsRange(
          DateTime(date.year, date.month),
          DateTime(date.year, date.month + 1),
        );
      case StatisticsPeriod.year:
        return StatisticsRange(DateTime(date.year), DateTime(date.year + 1));
    }
  }

  bool contains(DateTime time) => !time.isBefore(start) && time.isBefore(end);
  int get days => calendarDays(start, end);

  DateTime observedEnd(DateTime now) {
    final tomorrow = addDays(now, 1);
    return end.isBefore(tomorrow) ? end : tomorrow;
  }
}

class StatisticsSummary {
  StatisticsSummary(Iterable<StatisticsDrink> drinks, this.range, DateTime now)
    : items = List.unmodifiable(
        drinks.where((drink) => range.contains(drink.time)),
      ),
      observedEnd = range.observedEnd(now);

  final List<StatisticsDrink> items;
  final StatisticsRange range;
  final DateTime observedEnd;

  int get pricedCount => items.where((drink) => drink.hasKnownPrice).length;
  int get missingPriceCount => items.length - pricedCount;
  double get knownCostFt => items
      .where((drink) => drink.hasKnownPrice)
      .fold(0, (sum, drink) => sum + drink.priceFt!);

  int get elapsedDays {
    final count = StatisticsRange.calendarDays(range.start, observedEnd);
    return count < 0 ? 0 : count;
  }

  /// A missing record is not proof of an alcohol-free day.
  int get unloggedDays {
    final loggedDays = items
        .where((drink) => drink.time.isBefore(observedEnd))
        .map((drink) => StatisticsRange.day(drink.time))
        .toSet()
        .length;
    final count = elapsedDays - loggedDays;
    return count < 0 ? 0 : count;
  }
}
