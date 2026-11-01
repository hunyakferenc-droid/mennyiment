import 'app_language.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_v2.dart';

/// Pénzügyi áttekintés a meglévő italnapló alapján.
/// Nem módosítja az italnapló mentett adatait.
class FinanceCenterPage extends StatefulWidget {
  final List<V2Drink> drinks;
  const FinanceCenterPage({super.key, required this.drinks});

  @override
  State<FinanceCenterPage> createState() => _FinanceCenterPageState();
}

class _FinanceCenterPageState extends State<FinanceCenterPage> {
  static const _baselineKey = 'mennyiment_finance_baseline_v1';
  static const _budgetKey = 'mennyiment_budget_v2';
  static const _mint = Color(0xFF76E4B8);
  static const _panel = Color(0xFF172923);
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  int? baseline;
  int? budget;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      baseline = p.getInt(_baselineKey);
      budget = p.getInt(_budgetKey);
    });
  }

  String _ft(num value) => localeCurrency(value,Localizations.localeOf(context).languageCode);

  Future<void> _editValue({required bool isBaseline}) async {
    final current = isBaseline ? baseline : budget;
    final ctrl = TextEditingController(text: current?.toString() ?? '');
    final value = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isBaseline ? appStrings(context).uiPreviousAverageMonthlyDrinkSpending : appStrings(context).uiMonthlyBudget),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: appStrings(context).uiAmountInHuf, hintText: appStrings(context).uiEG30000),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(appStrings(context).uiCancel)),
          FilledButton(onPressed: () {
            final n = int.tryParse(ctrl.text.trim().replaceAll(' ', ''));
            if (n == null || n < 0 || n > 100000000) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text(appStrings(context).uiEnterAnAmountBetween0And100000000)));
              return;
            }
            Navigator.pop(ctx, n);
          }, child: Text(appStrings(context).uiSave)),
        ],
      ),
    );
    ctrl.dispose();
    if (value == null || !mounted) return;
    final p = await SharedPreferences.getInstance();
    final ok = await p.setInt(isBaseline ? _baselineKey : _budgetKey, value);
    if (!mounted) return;
    if (ok) {
      setState(() {
        if (isBaseline) { baseline = value; } else { budget = value; }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appStrings(context).uiSavingFailed)));
    }
  }

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: _panel,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white12),
    ),
    child: child,
  );

  Widget _bar({required double value, required String label, required String detail}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing:12,runSpacing:4,alignment:WrapAlignment.spaceBetween,children:[Text(label),Text(detail)]),
        const SizedBox(height: 5),
        LinearProgressIndicator(
          value: value.clamp(0.0, 1.0),
          minHeight: 8,
          borderRadius: BorderRadius.circular(12),
          color: _mint,
          backgroundColor: Colors.white12,
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final thisMonth = month.year == now.year && month.month == now.month;
    final monthDays = DateTime(month.year, month.month + 1, 0).day;
    final elapsed = thisMonth ? now.day : monthDays;
    final entries = widget.drinks.where((d) =>
      d.time.year == month.year && d.time.month == month.month &&
      !d.time.isAfter(now)).toList();
    final cost = entries.fold<double>(0, (sum, d) => sum + (d.priceFt ?? 0));
    final missing = entries.where((d) => d.priceFt == null).length;
    final complete = missing == 0;
    final weekly = List<double>.filled(5, 0);
    for (final d in entries) {
      weekly[((d.time.day - 1) ~/ 7).clamp(0, 4).toInt()] += d.priceFt ?? 0;
    }
    final maxWeekly = weekly.fold<double>(0, (m, n) => n > m ? n : m);
    final elapsedReference = baseline == null ? null : baseline! * elapsed / monthDays;
    final difference = elapsedReference == null ? null : elapsedReference - cost;
    final canCompare = baseline != null && complete;
    final future = month.isAfter(DateTime(now.year, now.month));

    return Scaffold(
      appBar: AppBar(title: Text(appStrings(context).uiFinanceCenter)),
      body: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(padding: const EdgeInsets.all(18), children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            IconButton(tooltip: appStrings(context).uiPreviousMonth, onPressed: () => setState(() =>
              month = DateTime(month.year, month.month - 1)),
              icon: const Icon(Icons.chevron_left)),
            Expanded(child:Text('${month.year}. ${month.month.toString().padLeft(2, '0')}.',textAlign:TextAlign.center,
              style:const TextStyle(fontSize:21,fontWeight:FontWeight.bold))),
            IconButton(tooltip: appStrings(context).uiNextMonth,
              onPressed: thisMonth || future ? null : () => setState(() =>
                month = DateTime(month.year, month.month + 1)),
              icon: const Icon(Icons.chevron_right)),
          ]),
          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(appStrings(context).uiRecordedDrinkSpending, style: TextStyle(color: _mint, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(_ft(cost), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(appStrings(context).uiDrinkPriceCounts((entries.length).toString(),(missing).toString()),
              style: const TextStyle(color: Colors.white70)),
            if (!complete) Padding(padding: EdgeInsets.only(top: 8),
              child: Text(appStrings(context).uiThisTotalIsIncompleteBecauseSomePricesAreMissing,
                style: TextStyle(color: Colors.amberAccent))),
          ])),
          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(appStrings(context).uiMonthlyBudget, style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(budget == null ? appStrings(context).uiNotSetYet : _ft(budget!)),
            if (budget != null && budget! > 0) _bar(
              value: cost / budget!, label: appStrings(context).uiUsed,
              detail: '${(cost / budget! * 100).round()}%'),
            if (budget != null && budget == 0)
              Text(appStrings(context).uiTheBudgetIsZeroAPercentageCannotBeCalculated),
            TextButton.icon(onPressed: () => _editValue(isBaseline: false),
              icon: const Icon(Icons.edit), label: Text(appStrings(context).uiEditBudget)),
          ])),
          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(appStrings(context).uiEstimatedChangeFromPreviousHabits,
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(baseline == null ? appStrings(context).uiSetYourPreviousAverageMonthlyDrinkSpending
              : appStrings(context).uiPreviousMonthlyValue((_ft(baseline!)).toString())),
            const SizedBox(height: 6),
            if (canCompare && difference != null) ...[
              Text('${difference >= 0 ? '+' : '−'}${_ft(difference.abs())}',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _mint)),
              Text(appStrings(context).uiComparisonDays((elapsed).toString(),(monthDays).toString()),
                style: const TextStyle(color: Colors.white70)),
            ] else if (baseline != null && !complete)
              Text(appStrings(context).uiAddTheMissingDrinkPricesBeforeComparing),
            const SizedBox(height: 9),
            Text(appStrings(context).uiThisIsAnEstimateNotVerifiedSavingsYouProvide,
              style: TextStyle(color: Colors.white70, fontSize: 12)),
            TextButton.icon(onPressed: () => _editValue(isBaseline: true),
              icon: const Icon(Icons.tune), label: Text(appStrings(context).uiSetPreviousMonthlyAverage)),
          ])),
          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(appStrings(context).uiWeeklySpending, style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...List.generate(5, (i) {
              final start = i * 7 + 1;
              final end = (start + 6).clamp(1, monthDays);
              if (start > monthDays) return const SizedBox.shrink();
              return _bar(value: maxWeekly == 0 ? 0 : weekly[i] / maxWeekly,
                label: appStrings(context).uiDaysValue('$start–$end'), detail: _ft(weekly[i]));
            }),
            if (!complete) Text(appStrings(context).uiTheChartIncludesKnownPricesOnly,
              style: TextStyle(fontSize: 12, color: Colors.white70)),
          ])),
          Text(appStrings(context).uiFinancialFiguresAreSelfReportedThisJournalCannotEstablish,
            style: TextStyle(fontSize: 12, color: Colors.white70)),
        ]),
      )),
    );
  }
}
