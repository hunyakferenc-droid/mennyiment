import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'statistics_summary.dart';
import 'app_language.dart';

import 'package:intl/intl.dart';

export 'statistics_summary.dart';

class StatisticsPage extends StatefulWidget {
  final List<StatisticsDrink> drinks;
  final DateTime Function() clock;

  const StatisticsPage({
    super.key,
    required this.drinks,
    this.clock = DateTime.now,
  });

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  StatisticsPeriod period = StatisticsPeriod.week;
  late DateTime anchor;

  @override
  void initState() {
    super.initState();
    anchor = StatisticsRange.day(widget.clock());
  }

  DateTime _day(DateTime d) => StatisticsRange.day(d);
  StatisticsRange get _range => StatisticsRange.forPeriod(period, anchor);
  DateTime get _start => _range.start;
  DateTime get _end => _range.end;

  void _move(int amount) {
    setState(() {
      switch (period) {
        case StatisticsPeriod.week:
          anchor = StatisticsRange.addDays(anchor, 7 * amount);
        case StatisticsPeriod.month:
          anchor = DateTime(anchor.year, anchor.month + amount, 1);
        case StatisticsPeriod.year:
          anchor = DateTime(anchor.year + amount, 1, 1);
      }
    });
  }

  String _date(DateTime d) =>
      DateFormat.yMd(appStrings(context).localeName).format(d);
  String _number(num n) =>
      NumberFormat('0.0', appStrings(context).localeName).format(n);

  @override
  Widget build(BuildContext context) {
    final strings = appStrings(context);
    final summary = StatisticsSummary(widget.drinks, _range, widget.clock());
    final items = summary.items;
    final totalGrams = items.fold<double>(0, (s, d) => s + d.grams);
    final totalMl = items.fold<int>(0, (s, d) => s + d.ml);
    final days = <DateTime, List<StatisticsDrink>>{};
    for (final d in items) {
      days.putIfAbsent(_day(d.time), () => []).add(d);
    }
    final zeroDays = summary.unloggedDays;
    final counts = <String, int>{};
    for (final d in items) {
      counts[d.name] = (counts[d.name] ?? 0) + 1;
    }
    final ranked = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final hours = List<int>.filled(24, 0);
    for (final d in items) {
      hours[d.time.toLocal().hour]++;
    }
    final peak = hours.reduce(math.max);
    final peakHour = peak == 0 ? null : hours.indexOf(peak);

    final bars = <double>[];
    final labels = <String>[];
    if (period == StatisticsPeriod.year) {
      for (var m = 0; m < 12; m++) {
        final monthStart = DateTime(_start.year, m + 1);
        final monthEnd = DateTime(_start.year, m + 2);
        bars.add(
          items
              .where(
                (d) =>
                    !d.time.isBefore(monthStart) && d.time.isBefore(monthEnd),
              )
              .fold<double>(0, (s, d) => s + d.grams),
        );
        labels.add('${m + 1}');
      }
    } else {
      final count = _range.days;
      for (var i = 0; i < count; i++) {
        final day = StatisticsRange.addDays(_start, i);
        bars.add((days[day] ?? []).fold<double>(0, (s, d) => s + d.grams));
        labels.add(
          period == StatisticsPeriod.week
              ? DateFormat.E(strings.localeName).format(day)
              : '${i + 1}',
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(strings.statistics)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<StatisticsPeriod>(
            segments: [
              ButtonSegment(
                value: StatisticsPeriod.week,
                label: Text(strings.week),
              ),
              ButtonSegment(
                value: StatisticsPeriod.month,
                label: Text(strings.month),
              ),
              ButtonSegment(
                value: StatisticsPeriod.year,
                label: Text(strings.year),
              ),
            ],
            selected: {period},
            onSelectionChanged: (v) => setState(() {
              period = v.first;
              anchor = StatisticsRange.day(widget.clock());
            }),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                onPressed: () => _move(-1),
                tooltip: strings.previousPeriod,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  '${_date(_start)} – ${_date(StatisticsRange.addDays(_end, -1))}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: () => _move(1),
                tooltip: strings.nextPeriod,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _stat(
                strings.drinks,
                strings.drinkCount(items.length),
                Icons.local_drink,
              ),
              _stat(
                strings.pureAlcohol,
                strings.grams(_number(totalGrams)),
                Icons.analytics_outlined,
              ),
              _stat(
                strings.drinkVolume,
                strings.litres(_number(totalMl / 1000)),
                Icons.water_drop_outlined,
              ),
              _stat(
                strings.unloggedDays,
                strings.dayCount(zeroDays),
                Icons.event_available_outlined,
              ),
              _stat(
                strings.knownSpending,
                localeCurrency(summary.knownCostFt, strings.localeName),
                Icons.payments_outlined,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            items.isEmpty
                ? strings.noSpendingData
                : summary.missingPriceCount > 0
                ? strings.partialPrices(summary.missingPriceCount)
                : strings.completePrices,
            key: const ValueKey('statistics-price-coverage'),
          ),
          const SizedBox(height: 24),
          Text(
            strings.alcoholByPeriod,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: _Bars(values: bars, labels: labels),
          ),
          const SizedBox(height: 22),
          Text(
            strings.frequentDrinks,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (ranked.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(strings.noDrinks),
            ),
          for (final entry in ranked.take(8))
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(entry.key),
              trailing: Text(strings.drinkCount(entry.value)),
            ),
          const SizedBox(height: 12),
          Text(
            strings.drinkingTimes,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            peakHour == null
                ? strings.noPeriodData
                : strings.peakTime(
                    DateFormat.Hm(strings.localeName)
                        .format(DateTime(2026, 1, 1, peakHour)),
                    DateFormat.Hm(strings.localeName)
                        .format(DateTime(2026, 1, 1, (peakHour + 1) % 24)),
                    peak,
                  ),
          ),
          const SizedBox(height: 24),
          Text(
            strings.statisticsCaution,
            style: TextStyle(fontSize: 12, color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _stat(String title, String value, IconData icon) => SizedBox(
    width: 160,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.deepPurpleAccent),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Bars extends StatelessWidget {
  const _Bars({required this.values, required this.labels});
  final List<double> values;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final maxValue = values.isEmpty ? 0.0 : values.reduce(math.max);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < values.length; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Tooltip(
                    message: appStrings(context).grams(
                      NumberFormat(
                        '0.0',
                        appStrings(context).localeName,
                      ).format(values[i]),
                    ),
                    child: Container(
                      height: maxValue == 0
                          ? 2
                          : math.max(2, 155 * values[i] / maxValue),
                      decoration: BoxDecoration(
                        color: Colors.deepPurpleAccent,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    labels[i],
                    style: TextStyle(fontSize: values.length > 12 ? 8 : 11),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
