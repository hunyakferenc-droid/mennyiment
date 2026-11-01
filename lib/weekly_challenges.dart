import 'dart:convert';
import 'dart:async';
import 'app_language.dart';
import 'menti_access.dart';
import 'menti_experience_settings.dart';
import 'menti_completion.dart';
import 'menti_reactions.dart';
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
  String? _raw;
  static Future<void>? _pending;
  static Future<T> _serial<T>(Future<T> Function() action) async {
    final previous = _pending;
    final gate = Completer<void>();
    _pending = gate.future;
    try {
      if (previous != null) await previous;
      return await action();
    } finally {
      if (identical(_pending, gate.future)) _pending = null;
      gate.complete();
    }
  }


  Future<void> load() => _serial(() async {
    writable = false;
    final prefs = await open();
    await prefs.reload();
    final raw = prefs.get(key);
    data = decodeDocument(raw);
    _raw = raw as String?;
    writable = true;
  });

  /// Pure decoder shared with read-only views; never migrates or persists.
  static Map<String, dynamic> decodeDocument(Object? raw) {
    if (raw != null && raw is! String) throw const FormatException('Invalid challenges type');
    if (raw != null) {
      final decoded = jsonDecode(raw as String) as Map<String, dynamic>;
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
      return decoded;
    } else {
      return {'version': 1, 'weeks': <String, dynamic>{}};
    }
  }

  Map<String, dynamic> week(DateTime day) => Map<String, dynamic>.from(
      (data['weeks'] as Map)[challengeDate(challengeMonday(day))] as Map? ?? {});

  /// Publish state only after confirmed persistence; retain unknown fields.
  Future<bool> put(DateTime day, String id, Map<String, dynamic> item) async {
    if (!writable || busy) return false;
    busy = true;
    return _serial(() async {
    SharedPreferences? prefs;
    try {
      prefs = await open();
      await prefs.reload();
      // Another screen changed the document: require a refresh, never erase it.
      if (prefs.getString(key) != _raw) {
        writable = false;
        return false;
      }
      final next = jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
      final weeks = next['weeks'] as Map<String, dynamic>;
      final weekKey = challengeDate(challengeMonday(day));
      final week = Map<String, dynamic>.from(weeks[weekKey] as Map? ?? {});
      week[id] = item;
      weeks[weekKey] = week;
      final encoded = jsonEncode(next);
      if (!await prefs.setString(key, encoded)) {
        await prefs.reload();
        return false;
      }
      _raw = encoded;
      data = next;
      return true;
    } catch (_) {
      try { await prefs?.reload(); } catch (_) { /* Leave confirmed state intact. */ }
      return false;
    } finally {
      busy = false;
    }
    });
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
  DateTime get now => (widget.clock ?? DateTime.now)().toLocal();
  int back = 0;
  bool loading = true;
  bool saving = false;
  String? error;
  Set<String> journalDays = {};
  MentiMood? _reaction;
  int _reactionSequence = 0;
  String? _observedWeek;

  int _count(String id, Map item, DateTime week, DateTime asOf) =>
      recordedGoalDays(id == 'journal' && item['status'] == 'active'
          ? journalDays : (item['days'] as List).cast<String>(), week, asOf);
  Timer? _timer;
  late String _shownDay;
  DateTime get monday => challengeDay(challengeMonday(now), -7 * back);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _shownDay = challengeDate(now);
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted || saving || loading) return;
      final day = challengeDate(now);
      if (_shownDay != day) {
        _shownDay = day;
        load();
      }
    });
    load();
  }
  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !saving) load();
  }
  Future<void> load() async {
    if (saving || !mounted) return;
    final week = monday;
    final previous = store.week(week)['journal'] as Map?;
    final before = previous == null ? 0 : _count('journal', previous, week, now);
    final compare = !loading && error == null && back == 0 &&
        _observedWeek == challengeDate(week);
    setState(() { loading = true; _reaction = null; });
    try {
      await store.load();
      final prefs = await store.open();
      final raw = prefs.getString('mennyiment_wellbeing_v1');
      final days = raw == null ? <String>{} : recordedWellbeingDays(raw, now);
      journalDays = days;
      error = null;
      final current = store.week(week)['journal'] as Map?;
      if (mounted && MentiExperienceScope.reactionsOf(context) && compare && challengeMonday(now) == week && previous != null && current != null &&
          previous['status'] == 'active' && current['status'] == 'active' &&
          crossedRecordedGoal(before: before, after: _count('journal', current, week, now),
            previousTarget: previous['goal'] as int, target: current['goal'] as int)) {
        _reaction = MentiMood.challengeCompleted;
        _reactionSequence++;
      }
      _observedWeek = challengeDate(week);
    } catch (failure, stack) {
      debugPrint('Challenge load failure: ${failure.runtimeType}\n$stack');
      error = 'load';
    }
    if (mounted) setState(() => loading = false);
  }
  Future<void> save(String id, Map<String, dynamic> item, DateTime expectedWeek) async {
    if(id=='journal' && !MentiAccessScope.adultOf(context)) return;
    if (challengeMonday(now) != expectedWeek) {
      setState(() {});
      return;
    }
    if (saving || loading || error != null || back != 0) return;
    final week = monday;
    final previous = store.week(week)[id] as Map?;
    final before = previous == null ? 0 : _count(id, previous, week, now);
    setState(() { saving = true; _reaction = null; });
    final ok = await store.put(week, id, item);
    if (!mounted) return;
    setState(() {
      saving = false;
      final current = store.week(week)[id] as Map?;
      if (MentiExperienceScope.reactionsOf(context) && ok && previous != null && current != null && challengeMonday(now) == week &&
          previous['status'] == 'active' && current['status'] == 'active' &&
          crossedRecordedGoal(before: before, after: _count(id, current, week, now),
            previousTarget: previous['goal'] as int, target: current['goal'] as int)) {
        _reaction = MentiMood.challengeCompleted;
        _reactionSequence++;
      }
    });
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appStrings(context).challengeSaveError)));
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
              decoration: InputDecoration(labelText: appStrings(context).challengeCustom)),
          Text(appStrings(context).challengeDaysPerWeek),
          DropdownButton<int>(value: goal, items: [for (var n = 1; n <= 7; n++)
            DropdownMenuItem(value: n, child: Text('$n'))],
            onChanged: (v) => update(() => goal = v!)),
        ])),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(appStrings(context).challengeCancel)),
          FilledButton(onPressed: () {
            if (id == 'custom' && name.text.trim().isEmpty) return;
            Navigator.pop(ctx, <String, dynamic>{...?(old),
              'title': id == 'custom' ? name.text.trim() : '',
              'goal': goal, 'status': old?['status'] ?? 'active',
              'days': old?['days'] ?? <String>[]});
          }, child: Text(appStrings(context).challengeSave))],
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
    int count(String id, Map item) => _count(id, item, week, now);
    final titles = {
      'reflection': appStrings(context).challengeReflection,
      if(MentiAccessScope.adultOf(context)) 'journal': appStrings(context).challengeJournal,
      'habit': appStrings(context).challengeHabit,
      'custom': appStrings(context).challengeCustom,
    };
    final enabled = back == 0 && !saving && store.writable && error == null;
    return Scaffold(
      appBar: AppBar(title: Text(appStrings(context).challengeTitle)),
      body: loading ? const Center(child: CircularProgressIndicator()) :
      Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 700),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Text(appStrings(context).challengeOptional),
          if (_reaction != null) MentiReactionCard(mood: _reaction!,
            bubbleKey: const ValueKey('challenge-reaction'), eventToken: _reactionSequence),
          Row(children: [IconButton(onPressed: saving ? null : () => setState(() { back++; _reaction = null; }),
            tooltip: appStrings(context).challengePrevious, icon: const Icon(Icons.chevron_left)),
            Expanded(child: Text('${challengeDate(week)} – ${challengeDate(challengeDay(week, 6))}', textAlign: TextAlign.center)),
            IconButton(onPressed: back == 0 || saving ? null : () => setState(() { back--; _reaction = null; }),
              tooltip: appStrings(context).challengeNext, icon: const Icon(Icons.chevron_right))]),
          if (error != null) ...[
            Text(appStrings(context).challengeLoadError),
            TextButton(onPressed: saving ? null : load, child: Text(appStrings(context).challengeRetry))],
          for (final entry in titles.entries) Card(child: Padding(
            padding: const EdgeInsets.all(16), child: Builder(builder: (_) {
              final item = items[entry.key] as Map<String, dynamic>?;
              final active = item?['status'] == 'active';
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(entry.key == 'custom' && item != null ? item['title'] as String : entry.value,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                if (item != null) Text('${count(entry.key, item)} / ${item['goal']} ${appStrings(context).challengeDays}'),
                if (item != null && !active) Text(item['status'] == 'skipped'
                    ? appStrings(context).challengeSkipped
                    : appStrings(context).challengeStopped),
                if (entry.key == 'journal') Text(appStrings(context).challengeJournalHint),
                Wrap(spacing: 8, children: [
                  if (item == null || active) TextButton(onPressed: enabled
                      ? () => edit(entry.key, entry.value, item) : null,
                    child: Text(item == null ? appStrings(context).challengeChoose : appStrings(context).challengeEdit)),
                  if (active && entry.key != 'journal') TextButton(onPressed: enabled &&
                      !(item!['days'] as List).contains(today) ? () => save(entry.key,
                      {...item, 'days': [...item['days'] as List, today]}, week) : null,
                    child: Text(appStrings(context).challengeDoneToday)),
                  if (item == null || active) TextButton(onPressed: enabled ? () => save(entry.key,
                    {...?item, 'title': item?['title'] ?? '', 'goal': item?['goal'] ?? 4,
                      'days': entry.key == 'journal' && item != null
                        ? journalDays.intersection(dates).toList() : item?['days'] ?? <String>[], 'status': item == null ? 'skipped' : 'stopped'}, week) : null,
                    child: Text(item == null ? appStrings(context).challengeSkip : appStrings(context).challengeStop)),
                ]),
              ]);
            }))),
          const SizedBox(height: 16),
          Text(appStrings(context).challengeSummary,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
          for (final entry in titles.entries)
            if (items[entry.key] != null) Text('${entry.value}: ${count(entry.key, items[entry.key] as Map)} / ${(items[entry.key] as Map)['goal']}'),
          if(MentiAccessScope.adultOf(context)) Text('${appStrings(context).challengeJournalDays}: ${journalDays.intersection(dates).length} / ${dates.length}'),
          Text(appStrings(context).challengeCaution),
          OutlinedButton(onPressed: saving ? null : load, child: Text(appStrings(context).challengeRefresh)),
        ]))),
    );
  }
}
