import 'drink_journal.dart';
import 'statistics_summary.dart';

enum JournalPeriod { all, day, week, month, year }

enum JournalPrice { all, missing, known }

enum JournalOrder { newest, oldest, priceHighest }

/// A read-only projection. Sorting never changes the persisted journal order.
class JournalQuery {
  const JournalQuery({
    this.search = '',
    this.period = JournalPeriod.all,
    this.price = JournalPrice.all,
    this.order = JournalOrder.newest,
  });

  final String search;
  final JournalPeriod period;
  final JournalPrice price;
  final JournalOrder order;

  static bool hasPrice(Drink drink) =>
      drink.priceFt != null &&
      drink.priceFt!.isFinite &&
      drink.priceFt! >= 0 &&
      drink.priceFt! <= 10000000;

  static String normalize(String value) {
    var result = value.toLowerCase();
    const accented = 'áéíóöőúüű';
    const plain = 'aeiooouuu';
    for (var i = 0; i < accented.length; i++) {
      result = result.replaceAll(accented[i], plain[i]);
    }
    return result.trim();
  }

  StatisticsRange? range(DateTime anchor) {
    switch (period) {
      case JournalPeriod.all:
        return null;
      case JournalPeriod.day:
        final start = StatisticsRange.day(anchor);
        return StatisticsRange(start, StatisticsRange.addDays(start, 1));
      case JournalPeriod.week:
        return StatisticsRange.forPeriod(StatisticsPeriod.week, anchor);
      case JournalPeriod.month:
        return StatisticsRange.forPeriod(StatisticsPeriod.month, anchor);
      case JournalPeriod.year:
        return StatisticsRange.forPeriod(StatisticsPeriod.year, anchor);
    }
  }

  List<Drink> apply(
    Iterable<Drink> drinks,
    DateTime anchor, {
    String Function(Drink)? label,
  }) {
    final bounds = range(anchor);
    final terms = normalize(search).split(RegExp(r'\s+'));
    final selected = drinks.indexed.where((entry) {
      final drink = entry.$2;
      if (bounds != null && !bounds.contains(drink.time)) return false;
      final known = hasPrice(drink);
      if (price == JournalPrice.missing && known) return false;
      if (price == JournalPrice.known && !known) return false;
      final name = normalize('${drink.name} ${label?.call(drink) ?? ''}');
      return terms.every(name.contains);
    }).toList();
    selected.sort((a, b) {
      final left = a.$2;
      final right = b.$2;
      int comparison;
      if (order == JournalOrder.priceHighest) {
        final leftKnown = hasPrice(left);
        final rightKnown = hasPrice(right);
        comparison = leftKnown == rightKnown ? 0 : (leftKnown ? -1 : 1);
        if (comparison == 0 && leftKnown) {
          comparison = right.priceFt!.compareTo(left.priceFt!);
        }
        if (comparison != 0) return comparison;
      }
      comparison = order == JournalOrder.oldest
          ? left.time.compareTo(right.time)
          : right.time.compareTo(left.time);
      return comparison != 0 ? comparison : a.$1.compareTo(b.$1);
    });
    return List.unmodifiable(selected.map((entry) => entry.$2));
  }
}

class JournalTotals {
  JournalTotals(Iterable<Drink> drinks) {
    for (final drink in drinks) {
      count++;
      ml += drink.ml;
      if (JournalQuery.hasPrice(drink)) {
        pricedCount++;
        knownCost += drink.priceFt!;
      }
    }
  }
  int count = 0;
  int ml = 0;
  int pricedCount = 0;
  double knownCost = 0;
  int get missingCount => count - pricedCount;
}
