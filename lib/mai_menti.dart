import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_language.dart';
import 'daily_menti_store.dart';
import 'menti_club_store.dart';
import 'menti_animation_player.dart';
import 'menti_reaction_engine.dart';
import 'menti_collection_model.dart';
import 'menti_collection_widgets.dart';
import 'menti_fitness.dart';
import 'menti_life_events.dart';
import 'menti_motion.dart';
import 'menti_rhythm.dart';
import 'personal_goal_store.dart';

const maiMentiEnabled = bool.fromEnvironment('MENTI_DAILY_REVIEW');

class MaiMenti extends StatefulWidget {
  const MaiMenti({super.key, required this.character, required this.name});
  final Widget character;
  final String name;

  @override
  State<MaiMenti> createState() => _MaiMentiState();
}

class _MaiMentiState extends State<MaiMenti> with WidgetsBindingObserver {
  static const _testDateKey = 'mennyiment_mai_menti_test_date_v1';
  static const _testMoodPrefix = 'mennyiment_mai_menti_test_mood_v1_';
  static String _moodKey(DateTime day) => '$_testMoodPrefix${clubDay(day)}';
  bool _trial = false;
  bool _busy = false;
  bool _failed = false;
  bool _refreshPending = false;
  Map<String, int> _moods = {};
  late DateTime _day;
  late final Timer _timer;
  int _goalCount = 0;
  int _goalTarget = 4;

  DateTime get _now => _trial ? _day : DateTime.now();
  final _record = MentiClubStore(key: MentiClubStore.dailyRhythmKey);
  final _trialRecord = MentiClubStore(
    key: MentiClubStore.dailyRhythmTestKey,
  );
  MentiClubStore get _activeRecord => _trial ? _trialRecord : _record;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _day = DateTime.now();
    _load();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!_trial && clubDay(_now) != clubDay(_day)) _load();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  @override
  void dispose() {
    _timer.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _record.dispose();
    _trialRecord.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_busy) {
      _refreshPending = true;
      return;
    }
    setState(() { _busy = true; _failed = false; });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final trialDay = prefs.getString(_testDateKey);
      final trial = trialDay != null;
      final day = trialDay == null ? DateTime.now() : parseClubDay(trialDay);
      final moods = <String, int>{};
      final monday = DateTime(day.year, day.month, day.day - day.weekday + 1);
      final goal = PersonalGoalStore();
      await goal.load();
      if (!goal.writable) throw StateError('Goal data unavailable');
      for (var offset = 0; offset < 7; offset++) {
        final date = DateTime(day.year, day.month, day.day - offset);
        final mood = trial
            ? prefs.getInt(_moodKey(date))
            : (await DailyMentiStore.load(date))['mood'] as int?;
        if (mood != null && mood >= 1 && mood <= 5) moods[clubDay(date)] = mood;
      }
      final record = trial ? _trialRecord : _record;
      await record.load();
      if (!record.ready) throw StateError('Rhythm record unavailable');
      if (!mounted) return;
      setState(() {
        _trial = trial;
        _day = day;
        _moods = moods;
        _goalTarget = goal.reflectionGoal;
        _goalCount = trial ? 0 : goal.reflectionDays.toSet().where((date) =>
            date.compareTo(clubDay(monday)) >= 0 &&
            date.compareTo(clubDay(day)) <= 0).length;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        if (_refreshPending) {
          _refreshPending = false;
          unawaited(_load());
        }
      }
    }
  }

  Future<void> _write(Future<void> Function() action) async {
    if (_busy || _failed) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        if (!_failed) await _load();
      }
    }
  }

  Future<void> _answer(int mood) => _write(() async {
    final day = _now;
    // Reject a tap on yesterday's card while a clock rollover is pending.
    if (clubDay(day) != clubDay(_day)) return;
    if (_trial) {
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setInt(_moodKey(day), mood)) throw StateError('Mood');
    } else {
      final answer = await DailyMentiStore.load(day);
      await DailyMentiStore.save(
        date: day,
        mood: mood,
        energy: answer['energy'] as int?,
        goal: answer['goal'] as String? ?? '',
        evening: answer['evening'] as String? ?? '',
      );
    }
    if (!mounted) return;
    final controller = MentiAnimationScope.of(context)?.controller;
    // Thinking is the only existing exact-look clip suited to this moment.
    final shown = mood <= 2 && controller?.request(
      MentiLifeReaction.thinking,
      token: 'mai-mood-${clubDay(day)}-$mood',
      manual: true,
    ) == true;
    if (!shown) {
      MentiLifeEvents.instance.emit(
        mood <= 2 ? MentiLifeEvent.difficultDay : MentiLifeEvent.checkInSaved,
      );
    }
  });

  Future<void> _setTrialDay(DateTime? date) => _write(() async {
    final prefs = await SharedPreferences.getInstance();
    final ok = date == null
        ? await prefs.remove(_testDateKey)
        : await prefs.setString(_testDateKey, clubDay(date));
    if (!ok) throw StateError('Test date');
  });

  Future<void> _play() async {
    final played = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => _MaiRhythm(record: _activeRecord, day: _now)),
    );
    if (!mounted) return;
    await _load();
    if (played == true && mounted && !_failed) _openWeek();
  }

  void _openWeek() {
    final s = appStrings(context);
    final hu = s.localeName == 'hu';
    final date = DateFormat.MMMd(s.localeName);
    final days = [
      for (var offset = 6; offset >= 0; offset--)
        DateTime(_day.year, _day.month, _day.day - offset),
    ];
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (context) => Scaffold(
        appBar: AppBar(title: Text(hu ? 'Az elmúlt hét' : 'The last seven days')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(s.dailyMood, style: Theme.of(context).textTheme.titleMedium),
            for (final day in days)
              Text('${date.format(day)} · ${_moods[clubDay(day)] ?? '–'}'),
            const SizedBox(height: 16),
            if (!_trial) ...[
              Text(hu ? 'Személyes cél' : 'Personal goal'),
              Text(s.goalProgress(_goalCount, _goalTarget)),
            ],
            Text(_best(hu, _activeRecord.record.best)),
            Text(hu ? 'Holnap új közérzetjelzés vár.' : 'Check in again tomorrow.'),
          ],
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = appStrings(context);
    final hu = s.localeName == 'hu';
    final mood = _moods[clubDay(_day)];
    final date = DateFormat.MMMd(s.localeName).format(_day);
    final yesterday = clubDay(DateTime(_day.year, _day.month, _day.day - 1));
    final yesterdayMood = _moods[yesterday];
    final yesterdayScore = _activeRecord.record.scoreOn(yesterday);
    final earlier = _moods.entries.where((entry) =>
        entry.key.compareTo(yesterday) < 0).firstOrNull;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              widget.character,
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hu ? 'Mai Menti' : 'Today with Menti',
                    style: Theme.of(context).textTheme.titleLarge),
                  Text(widget.name),
                  if (_trial) Text(s.clubTestDate(date)),
                ],
              )),
            ]),
            if (_failed)
              TextButton(onPressed: _load, child: Text(s.homeRetryProgress))
            else ...[
              Text(s.dailyMood),
              Wrap(
                spacing: 4,
                children: [
                  for (var rating = 1; rating <= 5; rating++)
                    ChoiceChip(
                      key: ValueKey('mai-mood-$rating'),
                      label: Text('$rating'),
                      selected: mood == rating,
                      onSelected: _busy ? null : (_) => _answer(rating),
                    ),
                ],
              ),
              if (mood != null)
                Semantics(liveRegion: true, child: Text(mood <= 2
                    ? (hu ? 'Mára egy kis lépés is elég.' : 'A small step is enough today.')
                    : (hu ? 'Köszönöm, hogy bejelentkeztél.' : 'Thanks for checking in.'))),
              FilledButton.icon(
                key: const ValueKey('mai-play'),
                onPressed: _busy ? null : _play,
                icon: const Icon(Icons.play_arrow),
                label: Text(s.rhythmPlay),
              ),
              if (yesterdayMood != null || yesterdayScore != null)
                Text(
                  hu
                    ? 'Tegnap · Közérzet: ${yesterdayMood ?? '–'} / 5 · Ritmus: ${yesterdayScore ?? '–'} / 3'
                    : 'Yesterday · Mood: ${yesterdayMood ?? '–'} / 5 · Rhythm: ${yesterdayScore ?? '–'} / 3',
                  key: const ValueKey('mai-yesterday'),
                ),
              if (yesterdayMood == null && yesterdayScore == null && earlier != null)
                Text(hu
                    ? 'Utolsó közérzetjelzés: ${earlier.value} / 5'
                    : 'Last mood check-in: ${earlier.value} / 5'),
              TextButton(
                key: const ValueKey('mai-week'),
                onPressed: _busy ? null : _openWeek,
                child: Text(hu ? 'Heti áttekintés' : 'Weekly overview'),
              ),
              if (_trial)
                OutlinedButton(
                  key: const ValueKey('mai-next-day'),
                  onPressed: _busy ? null : () => _setTrialDay(
                    nextClubTrialDay(_day)),
                  child: Text(s.clubNextDay),
                ),
              TextButton(
                key: const ValueKey('mai-test-clock'),
                onPressed: _busy ? null : () => _setTrialDay(
                  _trial ? null : DateTime(2030, 1, 1)),
                child: Text(_trial
                    ? (hu ? 'Vissza a valós naphoz' : 'Back to the real date')
                    : s.clubTestMode),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _best(bool hu, int score) =>
    hu ? 'Ritmusrekord: $score / 3' : 'Rhythm best: $score / 3';

class _MaiRhythm extends StatefulWidget {
  const _MaiRhythm({required this.record, required this.day});
  final DateTime day;
  final MentiClubStore record;

  @override
  State<_MaiRhythm> createState() => _MaiRhythmState();
}

class _MaiRhythmState extends State<_MaiRhythm> {
  final game = MentiRhythm(initialLength: 1, roundLimit: 3);
  late int _previous = widget.record.record.best;
  bool _saving = false;
  bool _failed = false;
  String? _feedback;

  bool get _ended =>
      game.phase == RhythmPhase.finished || game.phase == RhythmPhase.mistake;

  Future<void> _save() async {
    if (_saving) return;
    setState(() { _saving = true; _failed = false; });
    final result = await widget.record.dailyRhythm(game.completed, widget.day);
    if (!mounted) return;
    setState(() { _saving = false; _failed = result == ClubSave.failed; });
  }

  @override
  Widget build(BuildContext context) {
    final s = appStrings(context);
    final hu = s.localeName == 'hu';
    String label(RhythmAction action) => switch (action) {
      RhythmAction.stretch => s.rhythmStretch,
      RhythmAction.left => s.rhythmLeft,
      RhythmAction.right => s.rhythmRight,
    };
    final demo = game.phase == RhythmPhase.demonstration;
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(title: Text(s.rhythmTitle)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_ended)
              Center(child: _RhythmResultMenti(
                key: ValueKey(game.phase),
                completed: game.phase == RhythmPhase.finished,
              )),
            Semantics(liveRegion: true, child: Text(_ended
                ? (hu ? 'Eredmény: ${game.completed} / 3' : 'Result: ${game.completed} / 3')
                : s.rhythmRound(game.round))),
            if (demo) ...[
              Text(game.round == 1
                  ? (hu ? 'Nézd meg a mozdulatot. A Mehet után válaszd ugyanezt.'
                        : 'Look at the move. After Ready, tap the matching button.')
                  : (hu ? 'Jegyezd meg a sorrendet' : 'Remember the order')),
              for (final (index, action) in game.sequence.indexed)
                Text('${index + 1}. ${label(action)}', key: ValueKey('mai-cue-$index')),
              FilledButton(
                key: const ValueKey('mai-ready'),
                onPressed: () => setState(() {
                  while (game.phase == RhythmPhase.demonstration) { game.next(); }
                  _feedback = null;
                }),
                child: Text(hu ? 'Mehet' : 'Ready'),
              ),
            ],
            if (!demo && !_ended) ...[
              Text(s.rhythmYourTurn(game.entered, game.sequence.length),
                style: Theme.of(context).textTheme.titleMedium),
              if (game.round == 1)
                Text(hu ? 'Most koppints az előbb látott mozdulatra.'
                    : 'Now tap the move you just saw.'),
              for (final action in RhythmAction.values)
                OutlinedButton(
                  key: ValueKey('mai-hit-${action.name}'),
                  onPressed: () {
                    setState(() {
                      game.press(action);
                      _feedback = game.phase == RhythmPhase.mistake
                          ? s.rhythmMistake
                          : (hu ? 'Találat!' : 'Correct!');
                    });
                    if (_ended) unawaited(_save());
                  },
                  child: Text(label(action)),
                ),
            ],
            if (_feedback != null)
              Semantics(liveRegion: true, child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(game.phase == RhythmPhase.mistake
                    ? Icons.error_outline : Icons.check_circle_outline),
                title: Text(_feedback!),
              )),
            if (_ended) ...[
              Text(_best(hu, widget.record.record.best)),
              if (!_saving && !_failed)
                Text(hu ? 'Szép munka, köszönöm a játékot!' : 'Well played. Thanks for joining in!'),
              Text(game.completed > _previous
                  ? (hu ? 'Új rekord!' : 'New personal best!')
                  : hu
                    ? '${math.max(0, _previous - game.completed)} körre a rekordtól'
                    : '${math.max(0, _previous - game.completed)} rounds from your best'),
              if (_saving) Text(s.clubSaving),
              if (_failed)
                TextButton(
                  onPressed: () async {
                    await widget.record.load();
                    if (mounted) await _save();
                  },
                  child: Text(s.homeRetryProgress),
                ),
              FilledButton(
                key: const ValueKey('mai-replay'),
                onPressed: _saving || _failed ? null : () => setState(() {
                  _previous = widget.record.record.best;
                  _feedback = null;
                  game.restart();
                }),
                child: Text(s.rhythmNew),
              ),
              TextButton(
                key: const ValueKey('mai-end-week'),
                onPressed: _saving || _failed ? null : () => Navigator.of(context).pop(true),
                child: Text(hu ? 'Heti áttekintés' : 'Weekly overview'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


/// The selected character stays mounted through the result, including when a
/// matching own clip is absent or motion is disabled.
class _RhythmResultMenti extends StatefulWidget {
  const _RhythmResultMenti({super.key, required this.completed});
  final bool completed;

  @override
  State<_RhythmResultMenti> createState() => _RhythmResultMentiState();
}

class _RhythmResultMentiState extends State<_RhythmResultMenti> {
  bool _requested = false;

  @override
  Widget build(BuildContext context) {
    final complete = CompleteLookScope.of(context);
    final look = complete?.selection.active == true
        ? CompleteLook.find(complete!.selection.lookId)
        : null;
    final controller = MentiAnimationScope.of(context)?.controller;
    if (look != null && controller != null && !_requested &&
        MentiMotionScope.animateOf(context)) {
      _requested = true;
      // The player registers its visible host first. Never queue a reaction
      // for a result that the player has already dismissed.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
          controller.request(
            widget.completed ? MentiLifeReaction.congratulation
                             : MentiLifeReaction.thinking,
            token: 'mai-result-${identityHashCode(this)}',
            manual: true,
          );
        });
        WidgetsBinding.instance.ensureVisualUpdate();
      });
    }
    return look == null
        ? const MentiFitnessArtwork()
        : MentiAnimationPlayer(look: look, size: 120);
  }
}
