import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Calendar arithmetic intentionally avoids 24-hour durations across DST.
DateTime challengeDay(DateTime d, [int offset = 0]) =>
    DateTime(d.year, d.month, d.day + offset);
DateTime challengeMonday(DateTime d) => challengeDay(d, 1 - d.weekday);
String challengeDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class ChallengeStore {
  ChallengeStore({Future<SharedPreferences> Function()? open})
      : open = open ?? SharedPreferences.getInstance;
  static const key = 'mennyiment_weekly_challenges_v1';
  final Future<SharedPreferences> Function() open;
  Map<String, dynamic> data = {'version': 1, 'weeks': <String, dynamic>{}};
  bool writable = false;
  bool busy = false;

  Future<void> load() async {
    writable = false;
    final raw = (await open()).getString(key);
    if (raw != null) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      if (decoded['version'] != 1 || decoded['weeks'] is! Map) {
        throw const FormatException('Unsupported challenge data');
      }
      for (final week in (decoded['weeks'] as Map).values) {
        final w = week as Map;
        for (final item in w.values) {
          final c = item as Map;
          if (c['goal'] is! int || (c['goal'] as int) < 1 ||
              (c['goal'] as int) > 7 || c['days'] is! List ||
              !(c['days'] as List).every((d) => d is String) ||
              !['active', 'skipped', 'stopped'].contains(c['status']) ||
              c['title'] is! String) {
            throw const FormatException('Invalid challenge');
          }
        }
      }
      data = decoded;
    }
    writable = true;
  }

  Map<String, dynamic> week(DateTime day) => Map<String, dynamic>.from(
      (data['weeks'] as Map)[challengeDate(challengeMonday(day))] as Map? ?? {});

  /// Publish state only after confirmed persistence; retain unknown fields.
  Future<bool> put(DateTime day, String id, Map<String, dynamic> item) async {
    if (!writable || busy) return false;
    busy = true;
    try {
      final next = jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
      final weeks = next['weeks'] as Map<String, dynamic>;
      final weekKey = challengeDate(challengeMonday(day));
      final week = Map<String, dynamic>.from(weeks[weekKey] as Map? ?? {});
      week[id] = item;
      weeks[weekKey] = week;
      if (!await (await open()).setString(key, jsonEncode(next))) return false;
      data = next;
      return true;
    } catch (_) {
      return false;
    } finally {
      busy = false;
    }
  }
}

class WeeklyChallengesPage extends StatefulWidget {
  const WeeklyChallengesPage({super.key, this.store, this.clock});
  final ChallengeStore? store;
  final DateTime Function()? clock;
  @override
  State<WeeklyChallengesPage> createState() => _WeeklyChallengesPageState();
}

class _WeeklyChallengesPageState extends State<WeeklyChallengesPage>
    with WidgetsBindingObserver {
  late final ChallengeStore store = widget.store ?? ChallengeStore();
  DateTime get now => (widget.clock ?? DateTime.now)();
  int back = 0;
  bool loading = true;
  bool saving = false;
  String? error;
  Set<String> journalDays = {};
  String t(String hu, String en) =>
      Localizations.localeOf(context).languageCode == 'en' ? en : hu;
  DateTime get monday => challengeDay(challengeMonday(now), -7 * back);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    load();
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !saving) load();
  }
  Future<void> load() async {
    try {
      await store.load();
      final prefs = await store.open();
      final raw = prefs.getString('mennyiment_wellbeing_v1');
      final days = <String>{};
      if (raw != null) {
        for (final entry in jsonDecode(raw) as List) {
          final date = DateTime.parse((entry as Map)['day'] as String);
          if (!challengeDay(date).isAfter(challengeDay(now))) {
            days.add(challengeDate(date));
          }
        }
      }
      journalDays = days;
      error = null;
    } catch (_) {
      error = 'load';
    }
    if (mounted) setState(() => loading = false);
  }
  Future<void> save(String id, Map<String, dynamic> item, DateTime expectedWeek) async {
    if (challengeMonday(now) != expectedWeek) {
      setState(() {});
      return;
    }
    if (saving || back != 0) return;
    final week = monday;
    setState(() => saving = true);
    final ok = await store.put(week, id, item);
    if (!mounted) return;
    setState(() => saving = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t(
          'A mentés nem sikerült. Próbáld újra.', 'Could not save. Please retry.'))));
    }
  }
  Future<void> edit(String id, String title, Map<String, dynamic>? old) async {
    final expectedWeek = monday;
    final name = TextEditingController(text: old?['title'] as String? ?? '');
    var goal = old?['goal'] as int? ?? 4;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, update) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (id == 'custom') TextField(controller: name, maxLength: 120,
              decoration: InputDecoration(labelText: t('Saját heti cél', 'Your weekly goal'))),
          Text(t('Heti napok száma', 'Days per week')),
          DropdownButton<int>(value: goal, items: [for (var n = 1; n <= 7; n++)
            DropdownMenuItem(value: n, child: Text('$n'))],
            onChanged: (v) => update(() => goal = v!)),
        ])),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('Mégse', 'Cancel'))),
          FilledButton(onPressed: () {
            if (id == 'custom' && name.text.trim().isEmpty) return;
            Navigator.pop(ctx, <String, dynamic>{...?(old),
              'title': id == 'custom' ? name.text.trim() : '',
              'goal': goal, 'status': old?['status'] ?? 'active',
              'days': old?['days'] ?? <String>[]});
          }, child: Text(t('Mentés', 'Save')))],
      )),
    );
    // The dialog route may still be animating with the controller attached.
    if (result != null && mounted) await save(id, result, expectedWeek);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    name.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final week = monday;
    final items = store.week(week);
    final today = challengeDate(now);
    final dates = {for (var i = 0; i < 7; i++)
      if (!challengeDay(week, i).isAfter(challengeDay(now)))
        challengeDate(challengeDay(week, i))};
    int count(String id, Map item) => (id == 'journal' ? journalDays :
        (item['days'] as List).whereType<String>().toSet()).intersection(dates).length;
    final titles = {
      'reflection': t('Tudatos önellenőrzés', 'Mindful self-check'),
      'journal': t('Következetes közérzetnapló', 'Consistent wellbeing journal'),
      'habit': t('Tudatos szokás: rövid napi szünet', 'Mindful habit: a short daily pause'),
      'custom': t('Saját heti cél', 'Your weekly goal'),
    };
    final enabled = back == 0 && !saving && store.writable && error == null;
    return Scaffold(
      appBar: AppBar(title: Text(t('Heti személyes kihívások', 'Personal weekly challenges'))),
      body: loading ? const Center(child: CircularProgressIndicator()) :
      Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 700),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Text(t('A saját tempódban. Minden kihívás választható, kihagyható vagy megszakítható büntetés nélkül. Nincs XP-jutalom vagy levonás.',
            'At your own pace. Every challenge is optional and can be skipped or stopped without penalty. No XP rewards or deductions.')),
          Row(children: [IconButton(onPressed: saving ? null : () => setState(() => back++),
            tooltip: t('Előző hét', 'Previous week'), icon: const Icon(Icons.chevron_left)),
            Expanded(child: Text('${challengeDate(week)} – ${challengeDate(challengeDay(week, 6))}', textAlign: TextAlign.center)),
            IconButton(onPressed: back == 0 || saving ? null : () => setState(() => back--),
              tooltip: t('Következő hét', 'Next week'), icon: const Icon(Icons.chevron_right))]),
          if (error != null) ...[
            Text(t('Az adatok nem olvashatók. Nem írjuk felül őket.', 'Data could not be read. It will not be overwritten.')),
            TextButton(onPressed: saving ? null : load, child: Text(t('Újrapróbálás', 'Retry')))],
          for (final entry in titles.entries) Card(child: Padding(
            padding: const EdgeInsets.all(16), child: Builder(builder: (_) {
              final item = items[entry.key] as Map<String, dynamic>?;
              final active = item?['status'] == 'active';
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(entry.key == 'custom' && item != null ? item['title'] as String : entry.value,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                if (item != null) Text('${count(entry.key, item)} / ${item['goal']} ${t('nap', 'days')}'),
                if (item != null && !active) Text(item['status'] == 'skipped'
                    ? t('Kihagyva – nincs büntetés.', 'Skipped – no penalty.')
                    : t('Megszakítva – nincs büntetés.', 'Stopped – no penalty.')),
                if (entry.key == 'journal') Text(t('A mentett közérzetnapló napjai számítanak. Ital rögzítése nem szükséges.',
                    'Counts days with a saved wellbeing entry. No drink entry is needed.')),
                Wrap(spacing: 8, children: [
                  if (item == null || active) TextButton(onPressed: enabled
                      ? () => edit(entry.key, entry.value, item) : null,
                    child: Text(item == null ? t('Kiválasztás', 'Choose') : t('Cél módosítása', 'Edit goal'))),
                  if (active && entry.key != 'journal') TextButton(onPressed: enabled &&
                      !(item!['days'] as List).contains(today) ? () => save(entry.key,
                      {...item!, 'days': [...item['days'] as List, today]}, week) : null,
                    child: Text(t('Ma megtettem', 'I did this today'))),
                  if (item == null || active) TextButton(onPressed: enabled ? () => save(entry.key,
                    {...?item, 'title': item?['title'] ?? '', 'goal': item?['goal'] ?? 4,
                      'days': item?['days'] ?? <String>[], 'status': item == null ? 'skipped' : 'stopped'}, week) : null,
                    child: Text(item == null ? t('Ezen a héten kihagyom', 'Skip this week') : t('Megszakítás', 'Stop'))),
                ]),
              ]);
            }))),
          const SizedBox(height: 16),
          Text(t('Heti fejlődési összefoglaló', 'Weekly progress summary'),
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
          for (final entry in titles.entries)
            if (items[entry.key] != null) Text('${entry.value}: ${count(entry.key, items[entry.key] as Map)} / ${(items[entry.key] as Map)['goal']}'),
          Text('${t('Közérzetnaplóval kitöltött napok', 'Days with wellbeing entries')}: ${journalDays.intersection(dates).length} / ${dates.length}'),
          Text(t('A hiányzó bejegyzés ismeretlen adat, nem alkoholmentes nap. Ezek a kihívások nem jelölnek alkoholmentességet. A cél módosítása csak a kiválasztott hetet érinti; a korábbi napok megmaradnak.',
            'A missing entry is unknown, not an alcohol-free day. These challenges do not label alcohol-free days. Editing a goal affects only the selected week; previous check-ins are retained.')),
          OutlinedButton(onPressed: saving ? null : load, child: Text(t('Összefoglaló frissítése', 'Refresh summary'))),
        ]))),
    );
  }
}
