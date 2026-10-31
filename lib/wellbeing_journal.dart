import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Self-reported wellbeing notes. Stored locally, independently of drink records.
class WellbeingEntry {
  final DateTime day;
  final int mood;
  final int sleepQuality;
  final int hangover;
  final String note;

  const WellbeingEntry({required this.day, required this.mood,
    required this.sleepQuality, required this.hangover, required this.note});

  Map<String, dynamic> toJson() => {
    'day': DateTime(day.year, day.month, day.day).toIso8601String(),
    'mood': mood, 'sleep': sleepQuality, 'hangover': hangover, 'note': note,
  };

  factory WellbeingEntry.fromJson(Map<String, dynamic> value) => WellbeingEntry(
    day: DateTime.parse(value['day'] as String),
    mood: (value['mood'] as num).toInt().clamp(1, 5),
    sleepQuality: (value['sleep'] as num).toInt().clamp(1, 5),
    hangover: (value['hangover'] as num).toInt().clamp(0, 4),
    note: (value['note'] as String?) ?? '',
  );
}

class WellbeingJournalPage extends StatefulWidget {
  const WellbeingJournalPage({super.key});
  @override
  State<WellbeingJournalPage> createState() => _WellbeingJournalPageState();
}

class _WellbeingJournalPageState extends State<WellbeingJournalPage> {
  static const _key = 'mennyiment_wellbeing_v1';
  static const _green = Color(0xFF76E4B8);
  final Map<String, WellbeingEntry> _entries = {};
  DateTime _day = DateTime.now();
  int _mood = 3;
  int _sleep = 3;
  int _hangover = 0;
  bool _loading = true;
  final _note = TextEditingController();

  String _dayKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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
        final values = jsonDecode(raw) as List<dynamic>;
        for (final item in values) {
          final entry = WellbeingEntry.fromJson(Map<String, dynamic>.from(item as Map));
          _entries[_dayKey(entry.day)] = entry;
        }
      }
    } catch (e) {
      debugPrint('Közérzetnapló betöltési hiba: $e');
    }
    if (!mounted) return;
    _select(_day, update: false);
    setState(() => _loading = false);
  }

  void _select(DateTime d, {bool update = true}) {
    final entry = _entries[_dayKey(d)];
    void assign() {
      _day = d;
      _mood = entry?.mood ?? 3;
      _sleep = entry?.sleepQuality ?? 3;
      _hangover = entry?.hangover ?? 0;
      _note.text = entry?.note ?? '';
    }
    if (update) { setState(assign); } else { assign(); }
  }

  Future<void> _pickDay() async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: _day,
      firstDate: DateTime(2020), lastDate: DateTime(now.year, now.month, now.day));
    if (picked != null) _select(picked);
  }

  Future<void> _save() async {
    final entry = WellbeingEntry(day: _day, mood: _mood,
      sleepQuality: _sleep, hangover: _hangover, note: _note.text.trim());
    setState(() => _entries[_dayKey(_day)] = entry);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(_entries.values.map((e) => e.toJson()).toList()));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A napi közérzeted mentve.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A mentés nem sikerült. Próbáld újra.')));
      }
    }
  }

  Future<void> _delete() async {
    setState(() => _entries.remove(_dayKey(_day)));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_entries.values.map((e) => e.toJson()).toList()));
    if (mounted) _select(_day);
  }

  Widget _rating(String title, String subtitle, int current, int min, int max,
      ValueChanged<int> onChanged, List<String> labels) {
    return Card(child: Padding(padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 12),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (var n = min; n <= max; n++) ChoiceChip(
            label: Text('$n'), selected: n == current,
            onSelected: (_) => setState(() => onChanged(n)),
            selectedColor: const Color(0xFF285C47),
          ),
        ]),
        const SizedBox(height: 8),
        Text(labels[current - min], style: const TextStyle(color: _green)),
      ])));
  }

  @override
  Widget build(BuildContext context) {
    final history = _entries.values.toList()..sort((a, b) => b.day.compareTo(a.day));
    final savedToday = _entries.containsKey(_dayKey(_day));
    return Scaffold(
      appBar: AppBar(title: const Text('Közérzetnapló')),
      body: _loading ? const Center(child: CircularProgressIndicator()) :
      Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 680),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          const Text('Hogy érzed magad?', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('A közérzeted és az alvásod is fontos. Nincs jó vagy rossz válasz.',
            style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: _pickDay, icon: const Icon(Icons.calendar_month),
            label: Text('${_day.year}. ${_day.month.toString().padLeft(2, '0')}. ${_day.day.toString().padLeft(2, '0')}.')),
          _rating('Hangulat', '1 = nagyon rossz, 5 = nagyon jó', _mood, 1, 5,
            (v) => _mood = v, const ['Nagyon rossz', 'Rossz', 'Közepes', 'Jó', 'Nagyon jó']),
          _rating('Alvásminőség', 'A legutóbbi alvásod saját értékelése', _sleep, 1, 5,
            (v) => _sleep = v, const ['Nagyon rossz', 'Rossz', 'Közepes', 'Jó', 'Nagyon jó']),
          _rating('Másnaposság tünetei', '0 = nincs, 4 = nagyon erős', _hangover, 0, 4,
            (v) => _hangover = v, const ['Nincs', 'Enyhe', 'Közepes', 'Erős', 'Nagyon erős']),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: TextField(
            controller: _note, minLines: 2, maxLines: 5, maxLength: 500,
            decoration: const InputDecoration(labelText: 'Megjegyzés (nem kötelező)',
              hintText: 'Mi befolyásolta ma a közérzeted?', border: OutlineInputBorder()),
          ))),
          const SizedBox(height: 8),
          FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save_outlined),
            label: Text(savedToday ? 'Bejegyzés frissítése' : 'Nap mentése'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52))),
          if (savedToday) TextButton.icon(onPressed: _delete,
            icon: const Icon(Icons.delete_outline), label: const Text('E napi bejegyzés törlése')),
          const SizedBox(height: 28),
          Text('Korábbi napok (${history.length})',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (history.isEmpty) const Text('Még nincs mentett nap.',
            style: TextStyle(color: Colors.white70)),
          for (final item in history.take(60)) Card(child: ListTile(
            leading: const Icon(Icons.favorite_outline, color: _green),
            title: Text('${item.day.year}. ${item.day.month}. ${item.day.day}.'),
            subtitle: Text('Hangulat ${item.mood}/5 • Alvás ${item.sleepQuality}/5 • Tünetek ${item.hangover}/4${item.note.isEmpty ? '' : '\n${item.note}'}'),
            isThreeLine: item.note.isNotEmpty,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _select(item.day),
          )),
          const SizedBox(height: 16),
          const Text('A feljegyzések önbevalláson alapulnak, nem orvosi értékelések. Súlyos tünetek esetén kérj egészségügyi segítséget.',
            style: TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
      )),
    );
  }
  @override
  void dispose() { _note.dispose(); super.dispose(); }
}
