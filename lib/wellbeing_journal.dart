import 'dart:convert';
import 'app_language.dart';
import 'menti_access.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Self-reported wellbeing notes. Stored locally, independently of drink records.
class WellbeingEntry {
  final DateTime day;
  final int mood;
  final int sleepQuality;
  final int hangover;
  final String note;
  final Map<String,dynamic> extras;

  const WellbeingEntry({required this.day, required this.mood,
    required this.sleepQuality, required this.hangover, required this.note, this.extras=const {}});

  Map<String, dynamic> toJson() => {...extras,
    'day': DateTime(day.year, day.month, day.day).toIso8601String(),
    'mood': mood, 'sleep': sleepQuality, 'hangover': hangover, 'note': note,
  };

  factory WellbeingEntry.fromJson(Map<String, dynamic> value) => WellbeingEntry(
    day: DateTime.parse(value['day'] as String),
    mood: (value['mood'] as num).toInt().clamp(1, 5),
    sleepQuality: (value['sleep'] as num).toInt().clamp(1, 5),
    hangover: (value['hangover'] as num).toInt().clamp(0, 4),
    note: (value['note'] as String?) ?? '', extras:Map<String,dynamic>.from(value),
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
  bool _loading = true, _saving = false, _writable = false;
  Object? _raw;
  String? _error;
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
      await prefs.reload();
      _raw = prefs.get(_key);
      final raw = _raw;
      if(raw!=null && raw is! String) throw const FormatException('Invalid wellbeing data');
      if (raw != null) {
        final values = jsonDecode(raw as String) as List<dynamic>;
        for (final item in values) {
          final entry = WellbeingEntry.fromJson(Map<String, dynamic>.from(item as Map));
          _entries[_dayKey(entry.day)] = entry;
        }
      }
      _writable = true; _error = null;
    } catch (_) { _writable = false; _error = 'load'; }
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

  Future<bool> _persist(Map<String,WellbeingEntry> next) async {
    if(_loading || _saving || !_writable) return false;
    setState(() { _saving=true; _error=null; });
    try {
      final prefs=await SharedPreferences.getInstance();await prefs.reload();
      if(prefs.get(_key)!=_raw) throw StateError('Concurrent wellbeing change');
      final encoded=jsonEncode(next.values.map((e)=>e.toJson()).toList());
      if(!await prefs.setString(_key,encoded)) throw StateError('Unconfirmed wellbeing write');
      _raw=encoded;
      if(!mounted) return true;
      setState(() { _entries..clear()..addAll(next); });
      return true;
    } catch (_) {
      try { await (await SharedPreferences.getInstance()).reload(); } catch (_) { _writable=false; }
      if(mounted) setState(()=>_error='save');
      return false;
    } finally { if(mounted) setState(()=>_saving=false); }
  }
  Future<void> _save() async {
    final entry=WellbeingEntry(day:_day,mood:_mood,sleepQuality:_sleep,
      hangover:_hangover,note:_note.text.trim(),extras:_entries[_dayKey(_day)]?.extras??const {});
    final ok=await _persist({..._entries,_dayKey(_day):entry});
    if(mounted && ok) { ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content:Text(appStrings(context).wellbeingSaved))); }
  }
  Future<void> _delete() async {
    final next={..._entries}..remove(_dayKey(_day));
    if(await _persist(next) && mounted) _select(_day);
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
            onSelected: _saving || !_writable ? null : (_) => setState(() => onChanged(n)),
            selectedColor: const Color(0xFF285C47),
          ),
        ]),
        const SizedBox(height: 8),
        Text(labels[current - min], style: const TextStyle(color: _green)),
      ])));
  }

  @override
  Widget build(BuildContext context) {
    final s = appStrings(context);
    final adult = MentiAccessScope.adultOf(context);
    final history = _entries.values.toList()..sort((a, b) => b.day.compareTo(a.day));
    final savedToday = _entries.containsKey(_dayKey(_day));
    return Scaffold(
      appBar: AppBar(title: Text(s.wellbeing)),
      body: _loading ? const Center(child: CircularProgressIndicator()) :
      Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 680),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          if(_error!=null) Text(_error=='load' ? s.wellbeingReadError : s.startSaveError),
          Text(s.wellbeingQuestion, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(s.wellbeingBody,
            style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: _saving ? null : _pickDay, icon: const Icon(Icons.calendar_month),
            label: Text('${_day.year}. ${_day.month.toString().padLeft(2, '0')}. ${_day.day.toString().padLeft(2, '0')}.')),
          _rating(s.wellbeingMood, s.wellbeingScale, _mood, 1, 5,
            (v) => _mood = v, [s.wellbeingVeryBad,s.wellbeingBad,s.wellbeingMedium,s.wellbeingGood,s.wellbeingVeryGood]),
          _rating(s.wellbeingSleep, s.wellbeingSleepHint, _sleep, 1, 5,
            (v) => _sleep = v, [s.wellbeingVeryBad,s.wellbeingBad,s.wellbeingMedium,s.wellbeingGood,s.wellbeingVeryGood]),
          if(adult) _rating(s.wellbeingHangover, s.wellbeingHangoverHint, _hangover, 0, 4,
            (v) => _hangover = v, [s.wellbeingNone,s.wellbeingMild,s.wellbeingMedium,s.wellbeingStrong,s.wellbeingVeryStrong]),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: TextField(
            controller: _note, enabled: !_saving && _writable, minLines: 2, maxLines: 5, maxLength: 500,
            decoration: InputDecoration(labelText: s.wellbeingNote,
              hintText: s.wellbeingNoteHint, border: OutlineInputBorder()),
          ))),
          const SizedBox(height: 8),
          FilledButton.icon(onPressed: _saving || !_writable ? null : _save, icon: const Icon(Icons.save_outlined),
            label: Text(savedToday ? s.wellbeingUpdate : s.wellbeingSave),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52))),
          if (savedToday) TextButton.icon(onPressed: _saving || !_writable ? null : _delete,
            icon: const Icon(Icons.delete_outline), label: Text(s.wellbeingDelete)),
          const SizedBox(height: 28),
          Text(s.wellbeingHistory(history.length),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (history.isEmpty) Text(s.wellbeingEmpty,
            style: TextStyle(color: Colors.white70)),
          for (final item in history.take(60)) Card(child: ListTile(
            leading: const Icon(Icons.favorite_outline, color: _green),
            title: Text('${item.day.year}. ${item.day.month}. ${item.day.day}.'),
            subtitle: Text('${s.wellbeingSummary(item.mood,item.sleepQuality)}${adult ? ' • ${s.wellbeingSymptoms(item.hangover)}' : ''}${item.note.isEmpty ? '' : '\n${item.note}'}'),
            isThreeLine: item.note.isNotEmpty,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _select(item.day),
          )),
          const SizedBox(height: 16),
          Text(s.wellbeingCaution,
            style: TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
      )),
    );
  }
  @override
  void dispose() { _note.dispose(); super.dispose(); }
}
