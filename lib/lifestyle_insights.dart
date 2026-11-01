import 'app_language.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'wellbeing_journal.dart';

/// Olvasási modell: a korábbi italnapló mentéseit nem módosítja.
class InsightDrink {
  final DateTime time;
  final double grams;
  final double? priceFt;
  const InsightDrink({required this.time, required this.grams, this.priceFt});
}

class InsightSummary {
  final int drinks;
  final int priced;
  final double knownFt;
  final double grams;
  final int wellbeingDays;
  final double? moodAverage;
  final double? sleepAverage;
  final double? hangoverAverage;
  const InsightSummary({required this.drinks, required this.priced,
    required this.knownFt, required this.grams, required this.wellbeingDays,
    this.moodAverage, this.sleepAverage, this.hangoverAverage});
  bool get pricesComplete => drinks == priced;
}

class InsightsCalculator {
  static DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);
  static InsightSummary summarize(List<InsightDrink> drinks,
      List<WellbeingEntry> wellbeing, DateTime start, DateTime end) {
    final filtered = drinks.where((d) => !d.time.isBefore(start) && d.time.isBefore(end)).toList();
    final entries = wellbeing.where((e) => !e.day.isBefore(start) && e.day.isBefore(end)).toList();
    double? average(Iterable<num> numbers) {
      final values = numbers.toList();
      return values.isEmpty ? null : values.fold<double>(0, (s, v) => s + v.toDouble()) / values.length;
    }
    return InsightSummary(
      drinks: filtered.length,
      priced: filtered.where((d) => d.priceFt != null).length,
      knownFt: filtered.fold<double>(0, (s, d) => s + (d.priceFt ?? 0)),
      grams: filtered.fold<double>(0, (s, d) => s + d.grams),
      wellbeingDays: entries.length,
      moodAverage: average(entries.map((e) => e.mood)),
      sleepAverage: average(entries.map((e) => e.sleepQuality)),
      hangoverAverage: average(entries.map((e) => e.hangover)),
    );
  }
  /// A következő napi közérzetet párosítja az előző nap italmennyiségével.
  /// Leíró megfigyelés, nem okozati vagy orvosi következtetés.
  static List<(double, WellbeingEntry)> nextDayPairs(
      List<InsightDrink> drinks, List<WellbeingEntry> wellbeing) {
    final byDay = <DateTime, double>{};
    for (final drink in drinks) {
      final d = day(drink.time);
      byDay[d] = (byDay[d] ?? 0) + drink.grams;
    }
    final result = <(double, WellbeingEntry)>[];
    for (final entry in wellbeing) {
      final previous = day(entry.day).subtract(const Duration(days: 1));
      // Csak az italnaplózott napok szerepelnek: a hiányzó nap nem bizonyított nulla.
      if (byDay.containsKey(previous)) result.add((byDay[previous]!, entry));
    }
    return result;
  }
}

class LifestyleInsightsPage extends StatefulWidget {
  final List<InsightDrink> drinks;
  const LifestyleInsightsPage({super.key, required this.drinks});
  @override
  State<LifestyleInsightsPage> createState() => _LifestyleInsightsPageState();
}

class _LifestyleInsightsPageState extends State<LifestyleInsightsPage> {
  static const _key = 'mennyiment_wellbeing_v1';
  List<WellbeingEntry> _entries = [];
  bool _loading = true;
  String? _error;
  DateTime _anchor = InsightsCalculator.day(DateTime.now());

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      final decoded = raw == null ? <dynamic>[] : jsonDecode(raw) as List<dynamic>;
      final values = decoded.map((item) => WellbeingEntry.fromJson(Map<String, dynamic>.from(item as Map))).toList();
      if (!mounted) return;
      setState(() { _entries = values; _loading = false; _error = null; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = appStrings(context).uiTheWellbeingJournalCouldNotBeLoaded; });
    }
  }
  Widget _card(String title, Widget body) => Card(child: Padding(
    padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12), body])));
  String _ft(double n) => localeCurrency(n,Localizations.localeOf(context).languageCode);
  String _avg(double? n, {int max = 5}) => n == null ? appStrings(context).uiNoData : '${n.toStringAsFixed(1)} / $max';
  Widget _line(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 5),
    child: Wrap(spacing:12,runSpacing:4,alignment:WrapAlignment.spaceBetween,children:[Text(label),Text(value,style:const TextStyle(fontWeight:FontWeight.bold))]));

  @override
  Widget build(BuildContext context) {
    final end = _anchor.add(const Duration(days: 1));
    final start = end.subtract(const Duration(days: 7));
    final previousStart = start.subtract(const Duration(days: 7));
    final current = InsightsCalculator.summarize(widget.drinks, _entries, start, end);
    final previous = InsightsCalculator.summarize(widget.drinks, _entries, previousStart, start);
    final pairs = InsightsCalculator.nextDayPairs(widget.drinks, _entries)
      .where((p) => !p.$2.day.isBefore(start) && p.$2.day.isBefore(end)).toList();
    final allWithPrice = current.pricesComplete && previous.pricesComplete;
    final difference = previous.knownFt - current.knownFt;
    final message = current.wellbeingDays == 0
      ? appStrings(context).uiMentiYouCanRecordYourMoodTooItHelps
      : current.drinks == 0
        ? appStrings(context).uiMentiNoDrinksAreRecordedThisWeekWeCannot
        : appStrings(context).uiMentiYourOwnRecordsAreComingTogetherLookFor;
    return Scaffold(
      appBar: AppBar(title: Text(appStrings(context).uiLifestyleInsights), actions: [IconButton(
        tooltip: appStrings(context).uiRefresh, onPressed: _load, icon: const Icon(Icons.refresh))]),
      body: _loading ? const Center(child: CircularProgressIndicator()) :
      _error != null ? Center(child: Text(_error!)) : Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760), child: ListView(
          padding: const EdgeInsets.all(16), children: [
            Row(children: [IconButton(onPressed: () => setState(() => _anchor = _anchor.subtract(const Duration(days: 7))), icon: const Icon(Icons.chevron_left)),
              Expanded(child: Text('${start.year}.${start.month}.${start.day}. – ${_anchor.year}.${_anchor.month}.${_anchor.day}.',
                textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
              IconButton(onPressed: _anchor.isBefore(InsightsCalculator.day(DateTime.now()))
                ? () => setState(() => _anchor = _anchor.add(const Duration(days: 7))) : null,
                icon: const Icon(Icons.chevron_right))]),
            _card(appStrings(context).uiMentiSWeeklyMessage, Text(message)),
            _card(appStrings(context).uiThePast7Days, Column(children: [
              _line(appStrings(context).uiLoggedDrinks, appStrings(context).uiItemsValue((current.drinks).toString())),
              _line(appStrings(context).uiPureAlcoholRecorded, '${current.grams.toStringAsFixed(1)} g'),
              _line(appStrings(context).uiKnownSpending, _ft(current.knownFt)),
              if (!current.pricesComplete) Text(appStrings(context).uiPartialDrinkSpending((current.drinks-current.priced).toString()),
                style: const TextStyle(color: Colors.orangeAccent)),
              _line(appStrings(context).uiWellbeingEntries, appStrings(context).uiDaysValue((current.wellbeingDays).toString())),
              _line(appStrings(context).uiAverageMood, _avg(current.moodAverage)),
              _line(appStrings(context).uiAverageSleepQuality, _avg(current.sleepAverage)),
              _line(appStrings(context).uiAverageHangoverSymptoms, _avg(current.hangoverAverage, max: 4)),
            ])),
            _card(appStrings(context).uiCompareWithThePrevious7Days, Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                _line(appStrings(context).uiDrinksPreviousPeriod, appStrings(context).uiItemsValue((previous.drinks).toString())),
                _line(appStrings(context).uiDrinksCurrentPeriod, appStrings(context).uiItemsValue((current.drinks).toString())),
                _line(appStrings(context).uiSpendingDifference, allWithPrice
                  ? '${difference >= 0 ? appStrings(context).uiLess : appStrings(context).uiMore} ${_ft(difference.abs())}' : appStrings(context).uiIncompletePrices),
                const SizedBox(height: 6),
                Text(appStrings(context).uiThisIsADifferenceInRecordedSpendingNotVerified,
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              ])),
            _card(appStrings(context).uiPreviousDayAndNextDayWellbeing, Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(appStrings(context).uiPairedDays((pairs.length).toString())),
                const SizedBox(height: 8),
                if (pairs.isEmpty) Text(appStrings(context).uiThereAreNoPairedRecordsWithADrinkOn),
                for (final pair in pairs.take(7)) Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5), child: Text(
                    appStrings(context).uiPairedWellbeing(('${pair.$2.day.month}.${pair.$2.day.day}').toString(),(pair.$1.toStringAsFixed(1)).toString(),(pair.$2.mood).toString(),(pair.$2.sleepQuality).toString(),(pair.$2.hangover).toString()))),
                const SizedBox(height: 8),
                Text(appStrings(context).uiManyFactorsAffectWellbeingCorrelationDoesNotProveCausation,
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              ])),
            const SizedBox(height: 16),
            Text(appStrings(context).uiAllRecordsAreLocalAndSelfReportedThisJournal,
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          ]))));
  }
}
