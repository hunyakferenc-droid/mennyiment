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
        const SnackBar(content: Text('A célok betöltése nem sikerült.')));
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
        const SnackBar(content: Text('Nem sikerült menteni. Próbáld újra.')));
      }
    }
  }

  String _ft(num value) => '${value.round().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ' ')} Ft';

  Future<int?> _askAmount(String title, {int? initial, bool allowZero = false}) async {
    final ctrl = TextEditingController(text: initial?.toString() ?? '');
    final answer = await showDialog<int>(context: context, builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(controller: ctrl, autofocus: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Összeg (Ft)')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Mégse')),
        FilledButton(onPressed: () {
          final n = int.tryParse(ctrl.text.trim().replaceAll(' ', ''));
          if (n == null || n < (allowZero ? 0 : 1) || n > 1000000000) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(content: Text('Érvényes összeget adj meg.')));
            return;
          }
          Navigator.pop(ctx, n);
        }, child: const Text('Mentés')),
      ],
    ));
    // Do not dispose dialog controllers before route exit animation completes.
    return answer;
  }

  Future<void> _editBaseline() async {
    final n = await _askAmount('Korábbi átlagos havi italköltés', initial: _baseline,
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
        title: const Text('Új megtakarítási cél'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, maxLength: 40,
              decoration: const InputDecoration(labelText: 'Cél neve', hintText: 'Például: nyaralás')),
            TextField(controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Célösszeg (Ft)')),
            Wrap(spacing: 8, children: ['🎯','🚗','🏖️','🏠','💻','🎁'].map((e) =>
              ChoiceChip(label: Text(e), selected: emoji == e,
                onSelected: (_) => refresh(() => emoji = e))).toList()),
          ],
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Mégse')),
          FilledButton(onPressed: () {
            final title = titleController.text.trim();
            final target = int.tryParse(amountController.text.trim().replaceAll(' ', ''));
            if (title.isEmpty || target == null || target <= 0 || target > 1000000000) {
              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                content: Text('Add meg a cél nevét és egy érvényes összeget.')));
              return;
            }
            Navigator.pop(ctx, SavingsGoal(id: DateTime.now().microsecondsSinceEpoch.toString(),
              title: title, targetFt: target, savedFt: 0, emoji: emoji));
          }, child: const Text('Létrehozás')),
        ],
      )));
    if (newGoal == null || !mounted) return;
    setState(() => _goals.add(newGoal));
    await _save();
  }

  Future<void> _addSaved(SavingsGoal goal) async {
    final n = await _askAmount('Ténylegesen félretett pénz');
    if (n == null || !mounted) return;
    final index = _goals.indexWhere((g) => g.id == goal.id);
    if (index < 0) return;
    if (_goals[index].savedFt + n > 1000000000) return;
    setState(() => _goals[index] = _goals[index].copyWith(savedFt: _goals[index].savedFt + n));
    await _save();
  }

  Future<void> _delete(SavingsGoal goal) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Cél törlése?'),
      content: Text('A(z) ${goal.title} cél és a hozzá rögzített összeg törlődik a naplóból. Ez nem mozgat valódi pénzt.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Mégse')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Törlés'))],
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
        title: const Text('Megtakarítási céljaim')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _orange, foregroundColor: Colors.black,
        onPressed: _loading ? null : _newGoal,
        icon: const Icon(Icons.add), label: const Text('Új cél')),
      body: _loading ? const Center(child: CircularProgressIndicator()) :
        Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), children: [
            const Text('MENNYIMENT? 5.0', style: TextStyle(color: _orange,
              fontWeight: FontWeight.w800, letterSpacing: 1.4)),
            const SizedBox(height: 6),
            const Text('Spórolj arra, ami igazán számít!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Becsült megtakarítás – időarányos hónap',
                style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 9),
              Text(estimated == null ? 'Nem számolható' : _ft(estimated),
                style: const TextStyle(fontSize: 27, color: _orange,
                  fontWeight: FontWeight.w800)),
              const SizedBox(height: 9),
              Text('Ismert havi italköltés: ${_ft(known)}'),
              if (missing > 0) Text('$missing ital ára hiányzik – a becslés nem készíthető el.',
                style: const TextStyle(color: Colors.orangeAccent)),
              const SizedBox(height: 6),
              Text(_baseline == null ? 'Állítsd be a korábbi havi átlagodat.' :
                'Korábbi teljes havi átlag: ${_ft(_baseline!)}'),
              const SizedBox(height: 9),
              OutlinedButton.icon(onPressed: _editBaseline,
                icon: const Icon(Icons.edit), label: const Text('Korábbi átlag beállítása')),
              const SizedBox(height: 6),
              const Text('A becslés a korábbi havi átlag időarányos részét hasonlítja a naplózott költéshez. Nem ténylegesen félretett pénz, és hiányos napló esetén pontatlan lehet.',
                style: TextStyle(fontSize: 12, color: Colors.white60)),
            ])),
            const SizedBox(height: 7),
            _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('MENTI VILÁGA', style: TextStyle(color: _orange,
                fontWeight: FontWeight.w800, letterSpacing: 1.3)),
              const SizedBox(height: 8),
              const Text('Nézd meg, mit értél el!',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text('A valóban félretett összegek alapján Menti különböző mérföldköveket ünnepel veled.'),
              const SizedBox(height: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: _orange,
                  foregroundColor: Colors.black),
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => MentiGoalWorldPage(goals: _goals.map((g) =>
                    MentiWorldGoal(title: g.title, emoji: g.emoji,
                      savedFt: g.savedFt, targetFt: g.targetFt)).toList()))),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Menti világának megnyitása'),
              ),
            ])),
            const SizedBox(height: 7),
            const Text('Valóban félretett pénz', style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Összesen a célokban: ${_ft(_goals.fold<int>(0, (s, g) => s + g.savedFt))}',
              style: const TextStyle(color: _orange, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            if (_goals.isEmpty) _card(const Text('Még nincs célod. Hozz létre például egy nyaralást, autót vagy saját elképzelést!')),
            ..._goals.map((g) => _card(Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Text(g.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 10), Expanded(child: Text(g.title,
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700))),
                  IconButton(tooltip: 'Cél törlése', onPressed: () => _delete(g),
                    icon: const Icon(Icons.delete_outline))]),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: (g.savedFt / g.targetFt).clamp(0.0, 1.0),
                  backgroundColor: Colors.white12, color: _orange, minHeight: 9,
                  borderRadius: BorderRadius.circular(8)),
                const SizedBox(height: 9),
                Text('${_ft(g.savedFt)} / ${_ft(g.targetFt)}'),
                Text('${(g.savedFt / g.targetFt * 100).clamp(0.0, 100.0).round()}% teljesítve',
                  style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                MentiGoalMilestones(savedFt: g.savedFt, targetFt: g.targetFt),
                const SizedBox(height: 10),
                OutlinedButton.icon(onPressed: () => _addSaved(g),
                  icon: const Icon(Icons.savings_outlined),
                  label: const Text('Félretett összeg hozzáadása')),
              ]))),
            const SizedBox(height: 10),
            const Text('A rögzített összegek kézi feljegyzések, nem kapcsolódnak bankszámlához. Az alkalmazás nem tesz át pénzt egyik számláról a másikra.',
              style: TextStyle(color: Colors.white60, fontSize: 12)),
          ]))),
    );
  }
}
