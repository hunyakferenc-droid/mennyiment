import 'dart:convert';
import 'weekly_challenges.dart';
import 'app_language.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Csak olvasási adatmodell: a meglévő italnapló tárolását nem módosítjuk.
class PersonalGoalDrink {
  const PersonalGoalDrink({required this.time, this.priceFt});
  final DateTime time;
  final double? priceFt;
}

class PersonalGoalsPage extends StatefulWidget {
  const PersonalGoalsPage({super.key, required this.drinks});
  final List<PersonalGoalDrink> drinks;

  @override
  State<PersonalGoalsPage> createState() => _PersonalGoalsPageState();
}

class _PersonalGoalsPageState extends State<PersonalGoalsPage> {
  static const _key = 'mennyiment_personal_goals_v1';
  static const _mint = Color(0xFF76E4B8);
  static const _panel = Color(0xFF172923);
  int? _weeklyBudget;
  int _reflectionGoal = 4;
  final Set<String> _reflectionDays = {};
  bool _loading = true;
  DateTime _week = _monday(DateTime.now());

  static DateTime _monday(DateTime day) {
    final midnight = DateTime(day.year, day.month, day.day);
    return midnight.subtract(Duration(days: midnight.weekday - 1));
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _money(num n) => n.round().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        if (!mounted) return;
        setState(() {
          final n = (data['weeklyBudget'] as num?)?.toInt();
          _weeklyBudget = n == null || n < 0 ? null : n;
          _reflectionGoal = ((data['reflectionGoal'] as num?)?.toInt() ?? 4)
              .clamp(1, 7);
          _reflectionDays.addAll(
              (data['reflectionDays'] as List<dynamic>? ?? [])
                  .whereType<String>());
        });
      }
    } catch (e) {
      debugPrint('Személyes célok betöltése sikertelen: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode({
        'weeklyBudget': _weeklyBudget,
        'reflectionGoal': _reflectionGoal,
        'reflectionDays': _reflectionDays.toList(),
      }));
    } catch (e) {
      debugPrint('Személyes célok mentése sikertelen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Nem sikerült menteni a célokat.'),
        ));
      }
    }
  }

  Future<void> _editNumber({required bool budget}) async {
    final controller = TextEditingController(
      text: budget ? (_weeklyBudget?.toString() ?? '') : '$_reflectionGoal',
    );
    final value = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(budget ? 'Heti ital-költségkeret (Ft)' : 'Heti önellenőrzések célja'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: budget ? 'Például 10000' : '1–7 nap',
            helperText: budget
                ? 'A nullás keret is megengedett.'
                : 'Naponta legfeljebb egy önellenőrzés.',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Mégse')),
          FilledButton(onPressed: () {
            final parsed = int.tryParse(controller.text.trim());
            if (parsed == null || (budget && (parsed < 0 || parsed > 100000000)) ||
                (!budget && (parsed < 1 || parsed > 7))) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(
                content: Text('Érvénytelen célérték.'),
              ));
              return;
            }
            Navigator.pop(dialogContext, parsed);
          }, child: const Text('Mentés')),
        ],
      ),
    );
    controller.dispose();
    if (value == null || !mounted) return;
    setState(() {
      if (budget) {
        _weeklyBudget = value;
      } else {
        _reflectionGoal = value;
      }
    });
    await _save();
  }

  Future<void> _checkIn() async {
    final today = _dateKey(DateTime.now());
    if (_reflectionDays.contains(today)) return;
    setState(() => _reflectionDays.add(today));
    await _save();
  }

  Widget _card(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    margin: const EdgeInsets.only(bottom: 14),
    decoration: BoxDecoration(
      color: _panel,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
    ),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final end = _week.add(const Duration(days: 7));
    final entries = widget.drinks.where((d) =>
        !d.time.isBefore(_week) && d.time.isBefore(end)).toList();
    final spent = entries.fold<double>(0, (sum, d) => sum + (d.priceFt ?? 0));
    final unknown = entries.where((d) => d.priceFt == null).length;
    final checks = List.generate(7, (i) => _dateKey(_week.add(Duration(days: i))))
        .where(_reflectionDays.contains).length;
    final today = DateTime.now();
    final current = _monday(today) == _week;
    final checkToday = _reflectionDays.contains(_dateKey(today));
    final overBudget = _weeklyBudget != null && spent > _weeklyBudget!;
    final clearlyUnderBudget = _weeklyBudget != null && !overBudget && unknown == 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Személyes céljaim')),
      body: _loading ? const Center(child: CircularProgressIndicator()) :
      Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          FilledButton.icon(
            onPressed: () => Navigator.push<void>(context, MaterialPageRoute(
              builder: (_) => const WeeklyChallengesPage())),
            icon: const Icon(Icons.flag_outlined),
            label: Text(appStrings(context).challengeTitle),
          ),
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('A saját tempódban', style: TextStyle(
                fontSize: 23, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Itt te döntöd el, mit szeretnél követni. A naplózásért és a tudatos átgondolásért dolgozunk, nem az elfogyasztott italokért.'),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              IconButton(onPressed: () => setState(() =>
                  _week = _week.subtract(const Duration(days: 7))),
                  icon: const Icon(Icons.chevron_left), tooltip: 'Előző hét'),
              Text('${_week.month}.${_week.day.toString().padLeft(2, '0')}. – '
                  '${end.subtract(const Duration(days: 1)).month}.'
                  '${end.subtract(const Duration(days: 1)).day.toString().padLeft(2, '0')}.',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(onPressed: current ? null : () => setState(() =>
                  _week = _week.add(const Duration(days: 7))),
                  icon: const Icon(Icons.chevron_right), tooltip: 'Következő hét'),
            ]),
          ])),
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Heti ital-költségkeret', style: TextStyle(
                fontSize: 19, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Rögzített költés: ${_money(spent)} Ft',
                style: const TextStyle(fontSize: 22, color: _mint, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(_weeklyBudget == null ? 'Még nincs keret beállítva.' :
                'Saját heti keret: ${_money(_weeklyBudget!)} Ft'),
            if (_weeklyBudget != null && _weeklyBudget! > 0) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(value: (spent / _weeklyBudget!).clamp(0.0, 1.0)),
            ],
            const SizedBox(height: 8),
            Text(unknown > 0
                ? '$unknown ital ára hiányzik. A költés csak részösszeg, így a keret teljesítése nem igazolható.'
                : overBudget ? 'A rögzített költés meghaladja a keretet.'
                : clearlyUnderBudget ? 'A rögzített költés a kereten belül van.'
                : 'A kerethez állíts be egy személyes célt.',
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
            TextButton.icon(onPressed: () => _editNumber(budget: true),
                icon: const Icon(Icons.edit_outlined), label: const Text('Keret szerkesztése')),
          ])),
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Heti tudatos önellenőrzés', style: TextStyle(
                fontSize: 19, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('$checks / $_reflectionGoal alkalom',
                style: const TextStyle(fontSize: 22, color: _mint, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: (checks / _reflectionGoal).clamp(0.0, 1.0)),
            const SizedBox(height: 12),
            Wrap(spacing: 7, children: List.generate(7, (i) {
              final day = _week.add(Duration(days: i));
              return Chip(label: Text(['H','K','Sz','Cs','P','Sz','V'][i]),
                avatar: Icon(_reflectionDays.contains(_dateKey(day))
                    ? Icons.check_circle : Icons.circle_outlined,
                    size: 17, color: _reflectionDays.contains(_dateKey(day))
                    ? _mint : Colors.white54));
            })),
            const SizedBox(height: 8),
            FilledButton.icon(onPressed: current && !checkToday ? _checkIn : null,
                icon: const Icon(Icons.task_alt),
                label: Text(checkToday && current ? 'Mai önellenőrzés kész' :
                    current ? 'Ma átgondoltam a napomat' : 'Csak az aktuális héten rögzíthető')),
            TextButton.icon(onPressed: () => _editNumber(budget: false),
                icon: const Icon(Icons.tune), label: const Text('Heti cél módosítása')),
          ])),
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Menti gondolata', style: TextStyle(fontSize: 19,
                fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(checks >= _reflectionGoal
                ? 'Szép munka, teljesítetted a heti önellenőrzési célodat!'
                : checks == 0
                    ? 'Nem kell tökéletes nap. Egy rövid átgondolás is jó kezdet.'
                    : 'Már $checks alkalommal megálltál átgondolni a napodat. Csak így tovább!'),
            const SizedBox(height: 10),
            const Text('A hiányzó naplóbejegyzés nem bizonyít alkoholmentes napot. Az itt látható költések önbevalláson alapulnak.',
                style: TextStyle(fontSize: 12, color: Colors.white70)),
          ])),
        ]),
      )),
    );
  }
}
