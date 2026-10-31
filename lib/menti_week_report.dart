import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'wellbeing_journal.dart';

/// Kizárólag olvasható adatok a meglévő italnaplóból.
class MentiWeekDrink {
  final DateTime time;
  final double grams;
  final double? priceFt;
  const MentiWeekDrink({required this.time, required this.grams, this.priceFt});
}

class MentiWeekReportPage extends StatefulWidget {
  final List<MentiWeekDrink> drinks;
  const MentiWeekReportPage({super.key, required this.drinks});

  @override
  State<MentiWeekReportPage> createState() => _MentiWeekReportPageState();
}

class _MentiWeekReportPageState extends State<MentiWeekReportPage> {
  static const _key = 'mennyiment_wellbeing_v1';
  static const _mint = Color(0xFF76E4B8);
  static const _panel = Color(0xFF172923);
  final Map<String, WellbeingEntry> _journal = {};
  bool _loading = true;
  int _weeksBack = 0;

  DateTime _date(DateTime value) => DateTime(value.year, value.month, value.day);
  String _keyFor(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  DateTime get _weekStart {
    final monday = _date(DateTime.now());
    return monday.subtract(Duration(days: monday.weekday - 1 + 7 * _weeksBack));
  }
  DateTime get _weekEnd => _weekStart.add(const Duration(days: 7));

  @override
  void initState() {
    super.initState();
    _loadJournal();
  }

  Future<void> _loadJournal() async {
    final next = <String, WellbeingEntry>{};
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        for (final item in jsonDecode(raw) as List<dynamic>) {
          try {
            final entry = WellbeingEntry.fromJson(
                Map<String, dynamic>.from(item as Map));
            next[_keyFor(entry.day)] = entry;
          } catch (error) {
            debugPrint('Hibás közérzetbejegyzés kihagyva: $error');
          }
        }
      }
    } catch (error) {
      debugPrint('Közérzetnapló olvasási hiba: $error');
    }
    if (!mounted) return;
    setState(() {
      _journal..clear()..addAll(next);
      _loading = false;
    });
  }

  Future<void> _openDailyJournal() async {
    await Navigator.push<void>(context,
        MaterialPageRoute(builder: (_) => const WellbeingJournalPage()));
    if (mounted) await _loadJournal();
  }

  String _formatDate(DateTime d) => '${d.month}. ${d.day.toString().padLeft(2, '0')}.';
  String _ft(double n) => n.round().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ');
  Widget _card(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: _panel,
      borderRadius: BorderRadius.circular(22)),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final start = _weekStart;
    final end = _weekEnd;
    final endDay = end.subtract(const Duration(days: 1));
    final now = DateTime.now();
    final thisWeek = widget.drinks.where((d) =>
        !d.time.isBefore(start) && d.time.isBefore(end) &&
        !d.time.isAfter(now)).toList();
    final known = thisWeek.fold<double>(0, (sum, d) => sum + (d.priceFt ?? 0));
    final unknown = thisWeek.where((d) => d.priceFt == null).length;
    final grams = thisWeek.fold<double>(0, (sum, d) => sum + d.grams);
    final moods = <WellbeingEntry>[];
    final dayCounts = <int>[];
    for (var i = 0; i < 7; i++) {
      final day = start.add(Duration(days: i));
      final entry = _journal[_keyFor(day)];
      if (entry != null && !day.isAfter(_date(now))) moods.add(entry);
      dayCounts.add(thisWeek.where((d) =>
          _keyFor(d.time) == _keyFor(day)).length);
    }
    final avgMood = moods.isEmpty ? null :
        moods.map((e) => e.mood).reduce((a, b) => a + b) / moods.length;
    final avgSleep = moods.isEmpty ? null :
        moods.map((e) => e.sleepQuality).reduce((a, b) => a + b) / moods.length;
    final symptomDays = moods.where((e) => e.hangover > 0).length;
    final loggedDays = dayCounts.where((n) => n > 0).length;
    final observed = List.generate(7, (i) => start.add(Duration(days: i)))
        .where((d) => !d.isAfter(_date(now))).length;
    final message = moods.isEmpty
        ? 'Menti: A közérzetnapló segíthet észrevenni, hogyan alakulnak a napjaid.'
        : unknown > 0
            ? 'Menti: Néhány ital ára még hiányzik. Így a költési összeg csak részleges.'
            : 'Menti: Köszi, hogy foglalkozol a szokásaiddal. A tudatos megfigyelés fontos lépés!';

    return Scaffold(
      appBar: AppBar(title: const Text('Heti Menti-jelentés')),
      body: _loading ? const Center(child: CircularProgressIndicator()) :
      Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          const Text('A heted egy helyen',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Önbevalláson alapuló naplóösszesítő, nem egészségügyi értékelés.',
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          Row(children: [
            IconButton(onPressed: () => setState(() => _weeksBack++),
                icon: const Icon(Icons.chevron_left), tooltip: 'Előző hét'),
            Expanded(child: Text('${_formatDate(start)} – ${_formatDate(endDay)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17))),
            IconButton(onPressed: _weeksBack == 0 ? null :
                () => setState(() => _weeksBack--),
                icon: const Icon(Icons.chevron_right), tooltip: 'Következő hét'),
          ]),
          const SizedBox(height: 12),
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Menti üzenete', style: TextStyle(color: _mint,
                fontWeight: FontWeight.bold, fontSize: 17)),
            const SizedBox(height: 8), Text(message),
          ])),
          const SizedBox(height: 12),
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Naplózott fogyasztás',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            Text('${thisWeek.length} ital • ${grams.toStringAsFixed(1)} g tiszta alkohol'),
            const SizedBox(height: 6),
            Text('Ismert költés: ${_ft(known)} Ft'),
            if (unknown > 0) Text('$unknown ital ára ismeretlen; ez nem teljes összeg.',
                style: const TextStyle(color: Colors.amber)),
            const SizedBox(height: 6),
            Text('Naplózott itallal érintett napok: $loggedDays / $observed'),
            const SizedBox(height: 8),
            const Text('A bejegyzés nélküli nap nem bizonyít alkoholmentességet.',
                style: TextStyle(fontSize: 12, color: Colors.white70)),
          ])),
          const SizedBox(height: 12),
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Napi bejegyzések',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            for (var i = 0; i < 7; i++) Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(children: [
                SizedBox(width: 47, child: Text(_formatDate(start.add(Duration(days: i))),
                    style: const TextStyle(fontSize: 12))),
                Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    minHeight: 12,
                    value: dayCounts[i] / (dayCounts.reduce((a, b) => a > b ? a : b) == 0
                        ? 1 : dayCounts.reduce((a, b) => a > b ? a : b)),
                    color: _mint,
                    backgroundColor: Colors.white12,
                  ))),
                SizedBox(width: 46, child: Text(' ${dayCounts[i]}',
                    textAlign: TextAlign.right)),
              ]),
            ),
          ])),
          const SizedBox(height: 12),
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Közérzet és alvás',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            Text('Kitöltött napok: ${moods.length} / $observed'),
            const SizedBox(height: 6),
            Text('Átlagos hangulat: ${avgMood == null ? 'nincs adat' : '${avgMood.toStringAsFixed(1)} / 5'}'),
            Text('Átlagos alvásminőség: ${avgSleep == null ? 'nincs adat' : '${avgSleep.toStringAsFixed(1)} / 5'}'),
            Text('Másnapossági tünetet jelzett napok: $symptomDays'),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: _openDailyJournal,
                icon: const Icon(Icons.edit_note),
                label: const Text('Napi közérzet kitöltése')),
          ])),
          const SizedBox(height: 14),
          const Text('Az adatok hiánya nem nulla fogyasztást vagy jó közérzetet jelent. '
              'A kimutatás összefüggéseket segít megfigyelni, de nem igazol ok-okozatot '
              'és nem alkalmas a józanság megállapítására.',
              style: TextStyle(fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 20),
        ])),
      ),
    );
  }
}
