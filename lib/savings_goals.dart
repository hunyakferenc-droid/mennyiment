import 'app_language.dart';
import 'savings_milestones.dart';
import 'menti_goal_world.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavingsDrink {
  final DateTime time;
  final double? priceFt;
  const SavingsDrink({required this.time, this.priceFt});
}

class SavingsGoal {
  final String id;
  final String title;
  final int targetFt;
  final int savedFt;
  final String emoji;
  const SavingsGoal({required this.id, required this.title, required this.targetFt,
    required this.savedFt, required this.emoji});

  SavingsGoal copyWith({int? savedFt}) => SavingsGoal(id: id, title: title,
    targetFt: targetFt, savedFt: savedFt ?? this.savedFt, emoji: emoji);

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'targetFt': targetFt,
    'savedFt': savedFt, 'emoji': emoji};

  factory SavingsGoal.fromJson(Map<String, dynamic> j) => SavingsGoal(
    id: j['id'] as String, title: j['title'] as String,
    targetFt: (j['targetFt'] as num).toInt(),
    savedFt: (j['savedFt'] as num).toInt(),
    emoji: j['emoji'] as String? ?? '🎯');
}

class SavingsGoalsPage extends StatefulWidget {
  final List<SavingsDrink> drinks;
  const SavingsGoalsPage({super.key, required this.drinks});
  @override
  State<SavingsGoalsPage> createState() => _SavingsGoalsPageState();
}

class _SavingsGoalsPageState extends State<SavingsGoalsPage> {
  static const _goalsKey = 'mennyiment_savings_goals_v1';
  static const _baselineKey = 'mennyiment_savings_baseline_v1';
  static const _orange = Color(0xFFFF9E2C);
  static const _panel = Color(0xFF181521);
  final List<SavingsGoal> _goals = [];
  int? _baseline;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_goalsKey);
      final loaded = raw == null ? <SavingsGoal>[] :
        (jsonDecode(raw) as List).map((e) => SavingsGoal.fromJson(
          Map<String, dynamic>.from(e as Map))).where((e) =>
            e.title.isNotEmpty && e.targetFt > 0 && e.savedFt >= 0).toList();
      if (!mounted) { return; }
      setState(() {
        _goals..clear()..addAll(loaded);
        _baseline = p.getInt(_baselineKey);
      });
    } catch (e) {
      debugPrint('Megtakarítási célok betöltése: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appStrings(context).uiGoalsCouldNotBeLoaded)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_goalsKey, jsonEncode(_goals.map((e) => e.toJson()).toList()));
    } catch (e) {
      debugPrint('Célok mentése: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appStrings(context).uiSavingFailedPleaseTryAgain)));
      }
    }
  }

  String _ft(num value) => localeCurrency(value,Localizations.localeOf(context).languageCode);

  Future<int?> _askAmount(String title, {int? initial, bool allowZero = false}) async {
    final ctrl = TextEditingController(text: initial?.toString() ?? '');
    final answer = await showDialog<int>(context: context, builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(controller: ctrl, autofocus: true,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: appStrings(context).uiAmountHuf)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(appStrings(context).uiCancel)),
        FilledButton(onPressed: () {
          final n = int.tryParse(ctrl.text.trim().replaceAll(' ', ''));
          if (n == null || n < (allowZero ? 0 : 1) || n > 1000000000) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text(appStrings(context).uiEnterAValidAmount)));
            return;
          }
          Navigator.pop(ctx, n);
        }, child: Text(appStrings(context).uiSave)),
      ],
    ));
    // Do not dispose dialog controllers before route exit animation completes.
    return answer;
  }

  Future<void> _editBaseline() async {
    final n = await _askAmount(appStrings(context).uiPreviousAverageMonthlyDrinkSpending, initial: _baseline,
      allowZero: true);
    if (!mounted || n == null) return;
    final p = await SharedPreferences.getInstance();
    await p.setInt(_baselineKey, n);
    if (mounted) setState(() => _baseline = n);
  }

  Future<void> _newGoal() async {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String emoji = '🎯';
    final newGoal = await showDialog<SavingsGoal>(context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, refresh) => AlertDialog(
        title: Text(appStrings(context).uiNewSavingsGoal),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, maxLength: 40,
              decoration: InputDecoration(labelText: appStrings(context).uiGoalName, hintText: appStrings(context).uiForExampleAHoliday)),
            TextField(controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: appStrings(context).uiTargetAmountHuf)),
            Wrap(spacing: 8, children: ['🎯','🚗','🏖️','🏠','💻','🎁'].map((e) =>
              ChoiceChip(label: Text(e), selected: emoji == e,
                onSelected: (_) => refresh(() => emoji = e))).toList()),
          ],
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(appStrings(context).uiCancel)),
          FilledButton(onPressed: () {
            final title = titleController.text.trim();
            final target = int.tryParse(amountController.text.trim().replaceAll(' ', ''));
            if (title.isEmpty || target == null || target <= 0 || target > 1000000000) {
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                content: Text(appStrings(context).uiEnterAGoalNameAndAValidAmount)));
              return;
            }
            Navigator.pop(ctx, SavingsGoal(id: DateTime.now().microsecondsSinceEpoch.toString(),
              title: title, targetFt: target, savedFt: 0, emoji: emoji));
          }, child: Text(appStrings(context).uiCreate)),
        ],
      )));
    if (newGoal == null || !mounted) return;
    setState(() => _goals.add(newGoal));
    await _save();
  }

  Future<void> _addSaved(SavingsGoal goal) async {
    final n = await _askAmount(appStrings(context).uiMoneyActuallySetAside);
    if (n == null || !mounted) return;
    final index = _goals.indexWhere((g) => g.id == goal.id);
    if (index < 0) return;
    if (_goals[index].savedFt + n > 1000000000) return;
    setState(() => _goals[index] = _goals[index].copyWith(savedFt: _goals[index].savedFt + n));
    await _save();
  }

  Future<void> _delete(SavingsGoal goal) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(appStrings(context).uiDeleteThisGoal),
      content: Text(appStrings(context).uiDeleteSavingsGoal((goal.title).toString())),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(appStrings(context).uiCancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(appStrings(context).uiDelete))],
    ));
    if (ok != true || !mounted) return;
    setState(() => _goals.removeWhere((g) => g.id == goal.id));
    await _save();
  }

  Widget _card(Widget child) => Container(width: double.infinity,
    padding: const EdgeInsets.all(18), margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white12)), child: child);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthly = widget.drinks.where((d) => d.time.year == now.year &&
      d.time.month == now.month && !d.time.isAfter(now)).toList();
    final known = monthly.fold<double>(0, (s, d) => s + (d.priceFt ?? 0));
    final missing = monthly.where((d) => d.priceFt == null).length;
    final days = DateTime(now.year, now.month + 1, 0).day;
    final baselineElapsed = _baseline == null ? null : _baseline! * now.day / days;
    final estimated = (baselineElapsed == null || missing > 0) ? null :
      (baselineElapsed - known).clamp(0.0, double.infinity);
    return Scaffold(
      backgroundColor: const Color(0xFF0C0A10),
      appBar: AppBar(backgroundColor: const Color(0xFF0C0A10),
        title: Text(appStrings(context).uiMySavingsGoals)),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _orange, foregroundColor: Colors.black,
        onPressed: _loading ? null : _newGoal,
        icon: const Icon(Icons.add), label: Text(appStrings(context).uiNewGoal)),
      body: _loading ? const Center(child: CircularProgressIndicator()) :
        Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), children: [
            Text(appStrings(context).uiMennyiment22, style: TextStyle(color: _orange,
              fontWeight: FontWeight.w800, letterSpacing: 1.4)),
            const SizedBox(height: 6),
            Text(appStrings(context).uiSaveForWhatMattersToYou,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(appStrings(context).uiEstimatedSavingsProratedMonth,
                style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 9),
              Text(estimated == null ? appStrings(context).uiCannotBeCalculated : _ft(estimated),
                style: const TextStyle(fontSize: 27, color: _orange,
                  fontWeight: FontWeight.w800)),
              const SizedBox(height: 9),
              Text(appStrings(context).uiKnownMonthlySpending((_ft(known)).toString())),
              if (missing > 0) Text(appStrings(context).uiMissingSavingsPrices((missing).toString()),
                style: const TextStyle(color: Colors.orangeAccent)),
              const SizedBox(height: 6),
              Text(_baseline == null ? appStrings(context).uiSetYourPreviousMonthlyAverage :
                appStrings(context).uiPreviousWholeMonth((_ft(_baseline!)).toString())),
              const SizedBox(height: 9),
              OutlinedButton.icon(onPressed: _editBaseline,
                icon: const Icon(Icons.edit), label: Text(appStrings(context).uiSetPreviousAverage)),
              const SizedBox(height: 6),
              Text(appStrings(context).uiTheEstimateComparesTheProratedPreviousMonthlyAverageWith,
                style: TextStyle(fontSize: 12, color: Colors.white60)),
            ])),
            const SizedBox(height: 7),
            _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(appStrings(context).uiMentiSWorld, style: TextStyle(color: _orange,
                fontWeight: FontWeight.w800, letterSpacing: 1.3)),
              const SizedBox(height: 8),
              Text(appStrings(context).uiLookAtWhatYouHaveAchieved,
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(appStrings(context).uiMentiCelebratesMilestonesBasedOnTheMoneyYouActually),
              const SizedBox(height: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: _orange,
                  foregroundColor: Colors.black),
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => MentiGoalWorldPage(goals: _goals.map((g) =>
                    MentiWorldGoal(title: g.title, emoji: g.emoji,
                      savedFt: g.savedFt, targetFt: g.targetFt)).toList()))),
                icon: const Icon(Icons.auto_awesome),
                label: Text(appStrings(context).uiOpenMentiSWorld),
              ),
            ])),
            const SizedBox(height: 7),
            Text(appStrings(context).uiMoneyActuallySetAside2, style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(appStrings(context).uiTotalGoalSavings((_ft(_goals.fold<int>(0,(s,g)=>s+g.savedFt))).toString()),
              style: const TextStyle(color: _orange, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            if (_goals.isEmpty) _card(Text(appStrings(context).uiNoGoalsYetCreateOneForAHolidayA)),
            ..._goals.map((g) => _card(Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Text(g.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 10), Expanded(child: Text(g.title,
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700))),
                  IconButton(tooltip: appStrings(context).uiDeleteGoal, onPressed: () => _delete(g),
                    icon: const Icon(Icons.delete_outline))]),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: (g.savedFt / g.targetFt).clamp(0.0, 1.0),
                  backgroundColor: Colors.white12, color: _orange, minHeight: 9,
                  borderRadius: BorderRadius.circular(8)),
                const SizedBox(height: 9),
                Text('${_ft(g.savedFt)} / ${_ft(g.targetFt)}'),
                Text(appStrings(context).uiPercentComplete(((g.savedFt/g.targetFt*100).clamp(0.0,100.0).round()).toString()),
                  style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                MentiGoalMilestones(savedFt: g.savedFt, targetFt: g.targetFt),
                const SizedBox(height: 10),
                OutlinedButton.icon(onPressed: () => _addSaved(g),
                  icon: const Icon(Icons.savings_outlined),
                  label: Text(appStrings(context).uiAddMoneySetAside)),
              ]))),
            const SizedBox(height: 10),
            Text(appStrings(context).uiTheseAmountsAreManualRecordsWithNoBankAccount,
              style: TextStyle(color: Colors.white60, fontSize: 12)),
          ]))),
    );
  }
}
