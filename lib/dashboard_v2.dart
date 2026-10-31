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
        title: Text(money ? 'Havi költségkeret (Ft)' : 'Havi naplózott ital nélküli napok célja'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: money ? 'Pl. 15000' : 'Pl. 15'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Mégse')),
          FilledButton(onPressed: () {
            final value = int.tryParse(controller.text.trim());
            if (value == null || value < 0 || (money && value > 100000000) || (!money && value > 31)) {
              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Érvénytelen célérték')));
              return;
            }
            Navigator.pop(ctx, value);
          }, child: const Text('Mentés')),
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
      ? 'Menti: Még nincs naplózott ital ebben a hónapban. 🌱'
      : 'Menti: A tudatos követés a lényeg. Haladj a saját tempódban! 💜';
    return Scaffold(
      appBar: AppBar(title: const Text('✨ MennyiMent? 2.0')),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(onPressed: () => setState(() => month = DateTime(month.year, month.month - 1)), icon: const Icon(Icons.chevron_left)),
          Text('${month.year}. ${month.month.toString().padLeft(2, '0')}.', style: Theme.of(context).textTheme.titleLarge),
          IconButton(onPressed: isCurrent || month.isAfter(DateTime(now.year, now.month)) ? null : () => setState(() => month = DateTime(month.year, month.month + 1)), icon: const Icon(Icons.chevron_right)),
        ]),
        _section('💜 Menti üzenete', Text(message)),
        _section('💰 Kiadások', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Rögzített költés: ${_knownCost.toStringAsFixed(0)} Ft', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(_unknownCount == 0 ? 'Minden naplózott italhoz tartozik ár.' : '$_unknownCount ital ára ismeretlen – az összeg nem teljes.'),
          const SizedBox(height: 10),
          Text('Havi keret: ${budget == null ? 'nincs beállítva' : '$budget Ft'}'),
          if (budget != null && budget! > 0) LinearProgressIndicator(value: (_knownCost / budget!).clamp(0.0, 1.0)),
          TextButton.icon(onPressed: () => _editGoal(money: true), icon: const Icon(Icons.edit), label: const Text('Keret beállítása')),
        ])),
        _section('🎯 Személyes célok', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Naplózott ital nélküli napok: $_unrecordedDays / $_observedDays'),
          const Text('Ez nem bizonyítja az alkoholmentességet: csak a naplóban nincs bejegyzés.', style: TextStyle(fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 8),
          Text('Havi cél: ${daysGoal == null ? 'nincs beállítva' : '$daysGoal nap'}'),
          if (daysGoal != null && daysGoal! > 0) LinearProgressIndicator(value: (_unrecordedDays / daysGoal!).clamp(0.0, 1.0)),
          TextButton.icon(onPressed: () => _editGoal(money: false), icon: const Icon(Icons.edit), label: const Text('Napcél beállítása')),
        ])),
        _section('📅 Fogyasztási naptár', Column(children: [
           Row(children: [for (final day in ['H', 'K', 'Sz', 'Cs', 'P', 'Sz', 'V']) Expanded(child: Center(child: Text(day)))]),
          const SizedBox(height: 8),
          ...List.generate(((_daysInMonth + DateTime(month.year, month.month, 1).weekday - 2) ~/ 7) + 1, (week) =>
            Row(children: List.generate(7, (weekday) {
              final day = week * 7 + weekday - DateTime(month.year, month.month, 1).weekday + 2;
              if (day < 1 || day > _daysInMonth) return const Expanded(child: SizedBox(height: 44));
              final items = _monthly.where((d) => d.time.day == day).toList();
              final inFuture = DateTime(month.year, month.month, day).isAfter(_date(now));
              return Expanded(child: Padding(padding: const EdgeInsets.all(2), child: Tooltip(
                message: '$day.: ${items.length} naplózott ital',
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
          const Text('Lila: van naplózott ital • Zöld: nincs naplózott ital • Szürke: jövőbeli nap', style: TextStyle(fontSize: 12)),
        ])),
        _section('📊 Havi összesítés', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${_monthly.length} ital • ${_grams.toStringAsFixed(1)} g tiszta alkohol'),
          const SizedBox(height: 8),
          if (top.isEmpty) const Text('Még nincs adat.') else
          ...top.take(5).map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text('${e.key}: ${e.value} alkalom'))),
        ])),
        const SizedBox(height: 12),
        const Text('Az adatok önbevalláson alapulnak. Nem alkalmasak a józanság vagy vezetési képesség megállapítására.', style: TextStyle(fontSize: 12, color: Colors.white70)),
      ]),
    );
  }
}
