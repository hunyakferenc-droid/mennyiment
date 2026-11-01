import 'app_language.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class V2Drink {
  final String name;
  final DateTime time;
  final double grams;
  final double? priceFt;
  const V2Drink({required this.name, required this.time, required this.grams, this.priceFt});
}

class DashboardV2Page extends StatefulWidget {
  final List<V2Drink> drinks;
  const DashboardV2Page({super.key, required this.drinks});
  @override
  State<DashboardV2Page> createState() => _DashboardV2PageState();
}

class _DashboardV2PageState extends State<DashboardV2Page> {
  static const _budgetKey = 'mennyiment_budget_v2';
  static const _daysKey = 'mennyiment_days_goal_v2';
  int? budget;
  int? daysGoal;
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      budget = prefs.getInt(_budgetKey);
      daysGoal = prefs.getInt(_daysKey);
    });
  }

  DateTime _date(DateTime d) => DateTime(d.year, d.month, d.day);
  List<V2Drink> get _monthly => widget.drinks.where((d) =>
    d.time.year == month.year && d.time.month == month.month).toList();
  int get _daysInMonth => DateTime(month.year, month.month + 1, 0).day;
  int get _observedDays {
    final now = DateTime.now();
    if (month.isAfter(DateTime(now.year, now.month))) return 0;
    if (month.year == now.year && month.month == now.month) return now.day;
    return _daysInMonth;
  }
  int get _unrecordedDays {
    final logged = _monthly.where((d) => d.time.isBefore(DateTime.now().add(const Duration(days: 1))))
      .map((d) => _date(d.time)).toSet().length;
    return (_observedDays - logged).clamp(0, _observedDays).toInt();
  }
  double get _knownCost => _monthly.fold(0.0, (sum, d) => sum + (d.priceFt ?? 0));
  int get _unknownCount => _monthly.where((d) => d.priceFt == null).length;
  double get _grams => _monthly.fold(0.0, (sum, d) => sum + d.grams);

  Future<void> _editGoal({required bool money}) async {
    final controller = TextEditingController(text: (money ? budget : daysGoal)?.toString() ?? '');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(money ? appStrings(context).uiMonthlyBudgetHuf : appStrings(context).uiMonthlyGoalForDaysWithoutDrinkEntries),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: money ? appStrings(context).uiEG15000 : appStrings(context).uiEG15),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(appStrings(context).uiCancel)),
          FilledButton(onPressed: () {
            final value = int.tryParse(controller.text.trim());
            if (value == null || value < 0 || (money && value > 100000000) || (!money && value > 31)) {
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(appStrings(context).uiInvalidGoalValue)));
              return;
            }
            Navigator.pop(ctx, value);
          }, child: Text(appStrings(context).uiSave)),
        ],
      ),
    );
    if (result == null || !mounted) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(money ? _budgetKey : _daysKey, result);
    if (mounted) setState(() { if (money) { budget = result; } else { daysGoal = result; } });
  }

  Widget _section(String title, Widget child) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12), child],
    )),
  );

  @override
  Widget build(BuildContext context) {
    final byName = <String, int>{};
    for (final d in _monthly) { byName[d.name] = (byName[d.name] ?? 0) + 1; }
    final top = byName.entries.toList()..sort((a,b) => b.value.compareTo(a.value));
    final now = DateTime.now();
    final isCurrent = month.year == now.year && month.month == now.month;
    final message = _monthly.isEmpty
      ? appStrings(context).uiMentiNoDrinksHaveBeenLoggedThisMonthYet
      : appStrings(context).uiMentiMindfulTrackingIsWhatMattersGoAtYour;
    return Scaffold(
      appBar: AppBar(title: Text('✨ MennyiMent? 2.2')),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(onPressed: () => setState(() => month = DateTime(month.year, month.month - 1)), icon: const Icon(Icons.chevron_left)),
          Expanded(child:Text('${month.year}. ${month.month.toString().padLeft(2, '0')}.',textAlign:TextAlign.center,style: Theme.of(context).textTheme.titleLarge)),
          IconButton(onPressed: isCurrent || month.isAfter(DateTime(now.year, now.month)) ? null : () => setState(() => month = DateTime(month.year, month.month + 1)), icon: const Icon(Icons.chevron_right)),
        ]),
        _section(appStrings(context).uiAMessageFromMenti, Text(message)),
        _section(appStrings(context).uiSpending, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(appStrings(context).uiRecordedSpendingValue((localeCurrency(_knownCost,Localizations.localeOf(context).languageCode)).toString()), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(_unknownCount == 0 ? appStrings(context).uiEveryLoggedDrinkHasAPrice : appStrings(context).uiUnknownPricesTotal((_unknownCount).toString())),
          const SizedBox(height: 10),
          Text(appStrings(context).uiMonthlyBudgetValue((budget==null?appStrings(context).uiNotSet:localeCurrency(budget!,Localizations.localeOf(context).languageCode)).toString())),
          if (budget != null && budget! > 0) LinearProgressIndicator(value: (_knownCost / budget!).clamp(0.0, 1.0)),
          TextButton.icon(onPressed: () => _editGoal(money: true), icon: const Icon(Icons.edit), label: Text(appStrings(context).uiSetBudget)),
        ])),
        _section(appStrings(context).uiPersonalGoals, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(appStrings(context).uiUnrecordedDays((_unrecordedDays).toString(),(_observedDays).toString())),
          Text(appStrings(context).uiThisDoesNotProveAnAlcoholFreeDayThere, style: TextStyle(fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 8),
          Text(appStrings(context).uiMonthlyGoalValue((daysGoal==null?appStrings(context).uiNotSet:appStrings(context).uiDaysValue(daysGoal.toString())).toString())),
          if (daysGoal != null && daysGoal! > 0) LinearProgressIndicator(value: (_unrecordedDays / daysGoal!).clamp(0.0, 1.0)),
          TextButton.icon(onPressed: () => _editGoal(money: false), icon: const Icon(Icons.edit), label: Text(appStrings(context).uiSetDaysGoal)),
        ])),
        _section(appStrings(context).uiDrinkJournalCalendar, Column(children: [
           Row(children: [for (final day in List.generate(7,(i)=>MaterialLocalizations.of(context).narrowWeekdays[(i+1)%7])) Expanded(child: Center(child: Text(day)))]),
          const SizedBox(height: 8),
          ...List.generate(((_daysInMonth + DateTime(month.year, month.month, 1).weekday - 2) ~/ 7) + 1, (week) =>
            Row(children: List.generate(7, (weekday) {
              final day = week * 7 + weekday - DateTime(month.year, month.month, 1).weekday + 2;
              if (day < 1 || day > _daysInMonth) return const Expanded(child: SizedBox(height: 44));
              final items = _monthly.where((d) => d.time.day == day).toList();
              final inFuture = DateTime(month.year, month.month, day).isAfter(_date(now));
              return Expanded(child: Padding(padding: const EdgeInsets.all(2), child: Tooltip(
                message: appStrings(context).uiDayDrinks((day).toString(),(items.length).toString()),
                child: Container(height: 40, alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: inFuture ? Colors.white10 : items.isEmpty ? Colors.green.withValues(alpha: 0.18) : Colors.deepPurple.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(8)),
                  child: Text('$day', style: TextStyle(color: inFuture ? Colors.white38 : Colors.white)),
                ),
              )));
            })),
          ),
          const SizedBox(height: 8),
          Text(appStrings(context).uiPurpleDrinkLoggedGreenNoDrinkLoggedGrayFuture, style: TextStyle(fontSize: 12)),
        ])),
        _section(appStrings(context).uiMonthlySummary, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(appStrings(context).uiDrinksAndGrams((_monthly.length).toString(),(_grams.toStringAsFixed(1)).toString())),
          const SizedBox(height: 8),
          if (top.isEmpty) Text(appStrings(context).uiNoDataYet) else
          ...top.take(5).map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text(appStrings(context).uiNameOccurrences((e.key).toString(),(e.value).toString())))),
        ])),
        const SizedBox(height: 12),
        Text(appStrings(context).uiTheseAreSelfReportedRecordsTheyCannotEstablishSobriety, style: TextStyle(fontSize: 12, color: Colors.white70)),
      ]),
    );
  }
}
