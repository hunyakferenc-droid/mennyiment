import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'menti_memory.dart';
import 'menti_movement_cards.dart';
import 'menti_ui.dart';
import 'menti_rhythm.dart';
import 'personal_goal_store.dart';

const maiMentiEnabled = bool.fromEnvironment('MENTI_DAILY_REVIEW');

enum _Adventure {
  arrival,
  rhythm,
  seated,
  checkIn,
  active,
  replay,
  finish,
  memory;

  String title(bool hu) => switch (this) {
    memory => hu ? 'Menti Emlékminta' : 'Menti Memory Pattern',
    arrival => hu ? 'Megérkezés Mentihez' : 'Arrive with Menti',
    rhythm => hu ? 'Ritmusösvény' : 'Rhythm trail',
    seated => hu ? 'Kényelmes mozdulatok' : 'Gentle moves',
    checkIn => hu ? 'Egy perc magadra' : 'A minute for yourself',
    active => hu ? 'Mozgásszünet' : 'Movement break',
    replay => hu ? 'Ritmus újra' : 'Rhythm replay',
    finish => hu ? 'Heti visszatekintés' : 'Look back on the week',
  };
}

const _chapters = [
  [
    _Adventure.arrival,
    _Adventure.rhythm,
    _Adventure.seated,
    _Adventure.checkIn,
    _Adventure.active,
    _Adventure.replay,
    _Adventure.finish,
  ],
  [
    _Adventure.memory,
    _Adventure.seated,
    _Adventure.checkIn,
    _Adventure.rhythm,
    _Adventure.memory,
    _Adventure.active,
    _Adventure.finish,
  ],
  [
    _Adventure.active,
    _Adventure.memory,
    _Adventure.replay,
    _Adventure.seated,
    _Adventure.checkIn,
    _Adventure.rhythm,
    _Adventure.finish,
  ],
  [
    _Adventure.checkIn,
    _Adventure.replay,
    _Adventure.memory,
    _Adventure.active,
    _Adventure.rhythm,
    _Adventure.memory,
    _Adventure.finish,
  ],
];

String _chapterName(int index, bool hu) => (hu
    ? ['Próbahét', 'A felfedezés hete', 'A lendület hete', 'Hazatérés']
    : ['Trial Week', 'Discovery Week', 'Momentum Week', 'Coming Home'])[index];

class MaiMenti extends StatefulWidget {
  const MaiMenti({
    super.key,
    required this.character,
    required this.name,
    this.clock = DateTime.now,
  });
  final Widget character;
  final String name;
  final DateTime Function() clock;

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

  DateTime get _now => _trial ? _day : widget.clock();
  final _record = MentiClubStore(key: MentiClubStore.dailyRhythmKey);
  final _trialRecord = MentiClubStore(key: MentiClubStore.dailyRhythmTestKey);
  final _adventures = MentiClubStore(key: MentiClubStore.adventureWeekKey);
  final _trialAdventures = MentiClubStore(
    key: MentiClubStore.adventureWeekTestKey,
  );
  final _journey = MentiClubStore(key: MentiClubStore.journeyKey);
  final _trialJourney = MentiClubStore(key: MentiClubStore.journeyTestKey);
  final _memory = MentiClubStore(key: MentiClubStore.memoryKey);
  final _trialMemory = MentiClubStore(key: MentiClubStore.memoryTestKey);

  MentiClubStore get _firstWeek => _trial ? _trialAdventures : _adventures;
  MentiClubStore get _laterWeeks => _trial ? _trialJourney : _journey;
  MentiClubStore get _memoryRecord => _trial ? _trialMemory : _memory;
  MentiClubStore get _week =>
      _firstWeek.record.days.length < 7 ? _firstWeek : _laterWeeks;
  int get _chapter => math.min(_completed ~/ 7, 3);
  bool _canCompleteOn(DateTime day) {
    final date = clubDay(day);
    return [
      _firstWeek.record.last,
      _laterWeeks.record.last,
    ].whereType<String>().every((last) => date.compareTo(last) > 0);
  }

  int get _rhythmBest =>
      math.max(_firstWeek.record.best, _laterWeeks.record.best);
  bool _adventureOpen = false;
  int _moodPulse = 0;
  int get _completed =>
      _firstWeek.record.days.length + _laterWeeks.record.days.length;
  bool get _adventureAvailable =>
      !_busy &&
      !_adventureOpen &&
      _week.ready &&
      _completed < 28 &&
      _canCompleteOn(_day);

  MentiClubStore get _activeRecord => _trial ? _trialRecord : _record;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _day = widget.clock();
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
    _adventures.dispose();
    _trialAdventures.dispose();
    _journey.dispose();
    _trialJourney.dispose();
    _memory.dispose();
    _trialMemory.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_busy) {
      _refreshPending = true;
      return;
    }
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final trialDay = prefs.getString(_testDateKey);
      final trial = trialDay != null;
      final day = trialDay == null ? widget.clock() : parseClubDay(trialDay);
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
      final week = trial ? _trialAdventures : _adventures;
      final journey = trial ? _trialJourney : _journey;
      final memory = trial ? _trialMemory : _memory;
      await Future.wait([
        record.load(),
        week.load(),
        journey.load(),
        memory.load(),
      ]);
      if (!record.ready || !week.ready || !journey.ready || !memory.ready) {
        throw StateError('Rhythm record unavailable');
      }
      if (!mounted) return;
      setState(() {
        _trial = trial;
        _day = day;
        _moods = moods;
        _goalTarget = goal.reflectionGoal;
        _goalCount = trial
            ? 0
            : goal.reflectionDays
                  .toSet()
                  .where(
                    (date) =>
                        date.compareTo(clubDay(monday)) >= 0 &&
                        date.compareTo(clubDay(day)) <= 0,
                  )
                  .length;
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

  Future<void> _answer(
    int mood, {
    Future<ClubSave> Function()? completeAdventure,
  }) => _write(() async {
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
    if (completeAdventure != null) {
      final result = await completeAdventure();
      if (result == ClubSave.failed) throw StateError('Adventure completion');
    }
    if (!mounted) return;
    final controller = MentiAnimationScope.of(context)?.controller;
    // Thinking is the only existing exact-look clip suited to this moment.
    final shown =
        mood <= 2 &&
        controller?.request(
              MentiLifeReaction.thinking,
              token: 'mai-mood-${clubDay(day)}-$mood',
              manual: true,
            ) ==
            true;
    if (!shown) {
      setState(() => _moodPulse++);
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
      MaterialPageRoute(
        builder: (_) => _MaiRhythm(record: _activeRecord, day: _now),
      ),
    );
    if (!mounted) return;
    await _load();
    if (played == true && mounted && !_failed) _openWeek();
  }

  Future<void> _openMemory({Future<ClubSave> Function()? onComplete}) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => MentiMemory(
            store: _memoryRecord,
            onComplete: onComplete,
            resultCharacter: (passed) => _RhythmResultMenti(completed: passed),
          ),
        ),
      );

  Future<void> _startAdventure({_Adventure? replay}) async {
    if (replay == null && !_adventureAvailable) return;
    if (replay != null && (_completed != 28 || _adventureOpen)) return;
    if (clubDay(_now) != clubDay(_day)) {
      await _load();
      return;
    }
    final week = _week;
    final before = _completed;
    final adventure = replay ?? _chapters[_chapter][_completed % 7];
    final day = _day;
    Future<ClubSave> complete({int? score}) async {
      if (replay != null) return ClubSave.alreadyToday;
      if (clubDay(_now) != clubDay(day)) return ClubSave.failed;
      await week.load();
      if (!week.ready || clubDay(_now) != clubDay(day)) return ClubSave.failed;
      if (!_canCompleteOn(day)) return ClubSave.alreadyToday;
      final expected = before < 7 ? before : before - 7;
      if (week.record.days.length != expected) return ClubSave.alreadyToday;
      return week.completeAdventure(day, rhythmScore: score);
    }

    setState(() => _adventureOpen = true);
    try {
      switch (adventure) {
        case _Adventure.arrival:
        case _Adventure.checkIn:
        case _Adventure.finish:
          final mood = await showDialog<int>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(_adventureQuestion(adventure, context)),
              content: Wrap(
                spacing: 4,
                children: [
                  for (var rating = 1; rating <= 5; rating++)
                    OutlinedButton(
                      key: ValueKey('adventure-mood-$rating'),
                      onPressed: () => Navigator.of(context).pop(rating),
                      child: Text('$rating'),
                    ),
                ],
              ),
            ),
          );
          if (mood != null && mounted && clubDay(_now) == clubDay(day)) {
            await _answer(
              mood,
              completeAdventure: replay == null ? complete : null,
            );
          }
          break;
        case _Adventure.rhythm:
        case _Adventure.replay:
          await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => _MaiRhythm(
                record: replay == null ? week : _activeRecord,
                day: day,
                quickPattern: adventure == _Adventure.replay,
                adventureSave: replay != null
                    ? null
                    : (score) => score == 3
                          ? complete(score: score)
                          : Future.value(ClubSave.alreadyToday),
              ),
            ),
          );
          break;
        case _Adventure.memory:
          await _openMemory(onComplete: replay == null ? complete : null);
          break;
        case _Adventure.seated:
        case _Adventure.active:
          await Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => MentiMovementCards(
                store: week,
                initiallySeated: adventure == _Adventure.seated,
                onComplete: complete,
              ),
            ),
          );
          break;
      }
      if (!mounted) return;
      await _load();
      if (mounted && !_failed && _completed > before && _completed % 7 == 0) {
        _openAdventureMap(summary: _completed ~/ 7 - 1);
      }
    } finally {
      if (mounted) setState(() => _adventureOpen = false);
    }
  }

  String _adventureQuestion(_Adventure adventure, BuildContext context) {
    final s = appStrings(context);
    final hu = s.localeName == 'hu';
    return switch (adventure) {
      _Adventure.checkIn =>
        hu
            ? 'Hogy vagy a hét közepén?'
            : 'How are you feeling halfway through?',
      _Adventure.finish =>
        hu
            ? 'Milyen érzéssel zárod a hetet?'
            : 'How do you feel at the end of this week?',
      _ => s.dailyMood,
    };
  }

  String _adventureProgress(bool hu, int completed, int best) => hu
      ? 'Teljesített kalandok: $completed / 28 · Legjobb Ritmus: $best / 3'
      : 'Adventures completed: $completed / 28 · Best Rhythm: $best / 3';

  void _openAdventureMap({int? summary}) {
    final s = appStrings(context);
    final hu = s.localeName == 'hu';
    final completed = _completed;
    final chapter = _chapter;
    final available = completed < 28 && _canCompleteOn(_day);
    final dates = [..._firstWeek.record.days, ..._laterWeeks.record.days];
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(hu ? 'Menti útja' : 'Menti’s Journey')),
          body: MentiPageBody(
            children: [
              LinearProgressIndicator(value: completed / 28),
              Text(
                _adventureProgress(hu, completed, _rhythmBest),
                key: const ValueKey('adventure-week-result'),
              ),
              if (summary != null) ...[
                const Center(child: _RhythmResultMenti(completed: true)),
                Text(
                  completed == 28
                      ? (hu
                            ? 'Végigjártad Menti útját!'
                            : 'You finished Menti’s Journey!')
                      : (hu
                            ? 'Végigjártad a hetet!'
                            : 'You finished the week!'),
                  key: const ValueKey('adventure-week-finished'),
                ),
              ],
              if (completed < 28 && !available) Text(s.adventureNoPenalty),
              for (final (weekIndex, stations) in _chapters.indexed)
                ExpansionTile(
                  initiallyExpanded: weekIndex == (summary ?? chapter),
                  title: Text(
                    '${weekIndex + 1}. ${_chapterName(weekIndex, hu)}',
                  ),
                  subtitle: Text(
                    hu
                        ? '${(completed - weekIndex * 7).clamp(0, 7)} / 7 teljesítve'
                        : '${(completed - weekIndex * 7).clamp(0, 7)} / 7 completed',
                  ),
                  children: [
                    if (completed >= (weekIndex + 1) * 7)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          hu
                              ? '${widget.name} · 7 állomás · ${stations.where((a) => a == _Adventure.memory || a == _Adventure.rhythm || a == _Adventure.replay).length} játék'
                              : '${widget.name} · 7 stations · ${stations.where((a) => a == _Adventure.memory || a == _Adventure.rhythm || a == _Adventure.replay).length} games',
                        ),
                      ),
                    for (final (index, adventure) in stations.indexed)
                      MentiAdventureStation(
                        title: '${index + 1}. ${adventure.title(hu)}',
                        done: weekIndex * 7 + index < completed,
                        current: weekIndex * 7 + index == completed,
                        details: [
                          if (weekIndex * 7 + index < dates.length)
                            Text(
                              DateFormat.MMMd(s.localeName).format(
                                parseClubDay(dates[weekIndex * 7 + index]),
                              ),
                            ),
                          if (weekIndex * 7 + index == completed && available)
                            FilledButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                unawaited(_startAdventure());
                              },
                              child: Text(
                                hu ? 'Kaland indítása' : 'Start adventure',
                              ),
                            ),
                          if (completed == 28 && adventure != _Adventure.finish)
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                unawaited(_startAdventure(replay: adventure));
                              },
                              child: Text(
                                hu ? 'Újrajátszás' : 'Replay station',
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openWeek() {
    final s = appStrings(context);
    final hu = s.localeName == 'hu';
    final date = DateFormat.MMMd(s.localeName);
    final days = [
      for (var offset = 6; offset >= 0; offset--)
        DateTime(_day.year, _day.month, _day.day - offset),
    ];
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(hu ? 'Az elmúlt hét' : 'The last seven days'),
          ),
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
              Text(
                hu
                    ? 'Holnap új közérzetjelzés vár.'
                    : 'Check in again tomorrow.',
              ),
            ],
          ),
        ),
      ),
    );
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
    final earlier = _moods.entries
        .where((entry) => entry.key.compareTo(yesterday) < 0)
        .firstOrNull;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: _moodPulse.toDouble()),
                  duration:
                      _moodPulse > 0 && MentiMotionScope.animateOf(context)
                      ? const Duration(milliseconds: 450)
                      : Duration.zero,
                  child: widget.character,
                  builder: (context, progress, child) => Transform.translate(
                    offset: Offset(0, -3 * math.sin(progress * math.pi)),
                    child: child,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hu ? 'Mai Menti' : 'Today with Menti',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(widget.name),
                      if (_trial) Text(s.clubTestDate(date)),
                    ],
                  ),
                ),
              ],
            ),
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
                Semantics(
                  liveRegion: true,
                  child: Text(switch (mood) {
                    <= 2 =>
                      hu
                          ? 'Mára egy kis lépés is elég.'
                          : 'A small step is enough today.',
                    3 => hu ? 'Értem. Jó, hogy szántál erre egy percet.' : 'I hear you. Thanks for taking a minute to check in.',
                    _ =>
                      hu
                          ? 'Örülök, hogy jól vagy. Köszönöm, hogy bejelentkeztél.'
                          : 'I’m glad you’re feeling good. Thanks for checking in.',
                  }),
                ),
              if (_week.ready) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(value: _completed / 28),
                const SizedBox(height: 6),
                Text(
                  _adventureProgress(hu, _completed, _rhythmBest),
                  key: const ValueKey('adventure-home-progress'),
                ),
                if (_completed < 28) ...[
                  Text(
                    _chapters[_chapter][_completed % 7].title(hu),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  FilledButton.icon(
                    key: const ValueKey('adventure-start'),
                    onPressed: _adventureAvailable ? _startAdventure : null,
                    icon: const Icon(Icons.explore),
                    label: Text(hu ? 'Mai kaland' : 'Today’s adventure'),
                  ),
                  if (!_adventureAvailable && !_busy && !_adventureOpen)
                    Text(
                      hu
                          ? 'A következő kaland holnap vár.'
                          : 'Your next adventure is tomorrow.',
                    ),
                ],
                OutlinedButton(
                  key: const ValueKey('adventure-week-map'),
                  onPressed: _busy || _adventureOpen ? null : _openAdventureMap,
                  child: Text(
                    hu ? 'Menti útja – térkép' : 'Menti’s Journey map',
                  ),
                ),
              ],
              FilledButton.icon(
                key: const ValueKey('mai-play'),
                onPressed: _busy ? null : _play,
                icon: const Icon(Icons.play_arrow),
                label: Text(s.rhythmPlay),
              ),
              OutlinedButton.icon(
                key: const ValueKey('mai-memory'),
                onPressed: _busy ? null : _openMemory,
                icon: const Icon(Icons.extension_outlined),
                label: Text(hu ? 'Menti Emlékminta' : 'Menti Memory Pattern'),
              ),
              if (yesterdayMood != null || yesterdayScore != null)
                Text(
                  hu
                      ? 'Tegnap · Közérzet: ${yesterdayMood ?? '–'} / 5 · Ritmus: ${yesterdayScore ?? '–'} / 3'
                      : 'Yesterday · Mood: ${yesterdayMood ?? '–'} / 5 · Rhythm: ${yesterdayScore ?? '–'} / 3',
                  key: const ValueKey('mai-yesterday'),
                ),
              if (yesterdayMood == null &&
                  yesterdayScore == null &&
                  earlier != null)
                Text(
                  hu
                      ? 'Utolsó közérzetjelzés: ${earlier.value} / 5'
                      : 'Last mood check-in: ${earlier.value} / 5',
                ),
              TextButton(
                key: const ValueKey('mai-week'),
                onPressed: _busy ? null : _openWeek,
                child: Text(hu ? 'Heti áttekintés' : 'Weekly overview'),
              ),
              if (_trial)
                OutlinedButton(
                  key: const ValueKey('mai-next-day'),
                  onPressed: _busy
                      ? null
                      : () => _setTrialDay(nextClubTrialDay(_day)),
                  child: Text(s.clubNextDay),
                ),
              TextButton(
                key: const ValueKey('mai-test-clock'),
                onPressed: _busy
                    ? null
                    : () => _setTrialDay(_trial ? null : DateTime(2030, 1, 1)),
                child: Text(
                  _trial
                      ? (hu ? 'Vissza a valós naphoz' : 'Back to the real date')
                      : s.clubTestMode,
                ),
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
  const _MaiRhythm({
    required this.record,
    required this.day,
    this.adventureSave,
    this.quickPattern = false,
  });
  final bool quickPattern;
  final Future<ClubSave> Function(int)? adventureSave;
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
  Timer? _beat;
  bool _missedBeat = false;
  bool _early = false;

  int get _secondsPerMove => widget.quickPattern ? 5 : 9;

  @override
  void dispose() {
    _beat?.cancel();
    super.dispose();
  }

  void _armBeat() {
    _beat?.cancel();
    _beat = Timer(Duration(seconds: _secondsPerMove), () {
      if (!mounted || game.phase != RhythmPhase.input) return;
      final hu = appStrings(context).localeName == 'hu';
      setState(() {
        _missedBeat = true;
        _feedback = hu
            ? 'Késői koppintás. Lejárt az idő.'
            : 'Too late. Time ran out.';
      });
      unawaited(_save());
    });
  }

  void _hit(RhythmAction action) {
    if (_ended || _saving) return;
    final s = appStrings(context);
    final hu = s.localeName == 'hu';
    if (game.phase == RhythmPhase.demonstration) {
      setState(() {
        _early = true;
        _feedback = hu
            ? 'Korai koppintás. Előbb nyomd meg: Mehet.'
            : 'Too soon. Press Ready first.';
      });
      return;
    }
    _beat?.cancel();
    setState(() {
      game.press(action);
      _feedback = game.phase == RhythmPhase.mistake
          ? s.rhythmMistake
          : (hu ? 'Találat!' : 'Correct!');
    });
    if (_ended) {
      unawaited(_save());
    } else if (game.phase == RhythmPhase.input) {
      _armBeat();
    }
  }

  bool get _ended =>
      _missedBeat ||
      game.phase == RhythmPhase.finished ||
      game.phase == RhythmPhase.mistake;

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    final result =
        await (widget.adventureSave?.call(game.completed) ??
            widget.record.dailyRhythm(game.completed, widget.day));
    if (!mounted) return;
    setState(() {
      _saving = false;
      _failed = result == ClubSave.failed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = appStrings(context);
    String label(RhythmAction action) => switch (action) {
      RhythmAction.stretch => s.rhythmStretch,
      RhythmAction.left => s.rhythmLeft,
      RhythmAction.right => s.rhythmRight,
    };
    final demo = game.phase == RhythmPhase.demonstration;
    final actions = RhythmAction.values;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(
          LogicalKeyboardKey.digit1,
          includeRepeats: false,
        ): () =>
            _hit(actions[0]),
        const SingleActivator(
          LogicalKeyboardKey.digit2,
          includeRepeats: false,
        ): () =>
            _hit(actions[1]),
        const SingleActivator(
          LogicalKeyboardKey.digit3,
          includeRepeats: false,
        ): () =>
            _hit(actions[2]),
      },
      child: Focus(
        autofocus: true,
        child: _buildGame(context, s.localeName == 'hu', label, demo),
      ),
    );
  }

  Widget _buildGame(
    BuildContext context,
    bool hu,
    String Function(RhythmAction) label,
    bool demo,
  ) {
    final s = appStrings(context);
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(title: Text(s.rhythmTitle)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_ended)
              Center(
                child: _RhythmResultMenti(
                  key: ValueKey(game.phase),
                  completed: game.phase == RhythmPhase.finished,
                ),
              ),
            Semantics(
              liveRegion: true,
              child: Text(
                _ended
                    ? (hu
                          ? 'Eredmény: ${game.completed} / 3'
                          : 'Result: ${game.completed} / 3')
                    : s.rhythmRound(game.round),
              ),
            ),
            if (demo) ...[
              Text(
                hu
                    ? '$_secondsPerMove másodperc mozdulatonként'
                    : '$_secondsPerMove seconds per move',
              ),
              Text(
                game.round == 1
                    ? (hu
                          ? 'Nézd meg a mozdulatot. A Mehet után válaszd ugyanezt.'
                          : 'Look at the move. After Ready, tap the matching button.')
                    : (hu ? 'Jegyezd meg a sorrendet' : 'Remember the order'),
              ),
              for (final (index, action) in game.sequence.indexed)
                Text(
                  '${index + 1}. ${label(action)}',
                  key: ValueKey('mai-cue-$index'),
                ),
              FilledButton(
                key: const ValueKey('mai-ready'),
                onPressed: () {
                  setState(() {
                    while (game.phase == RhythmPhase.demonstration) {
                      game.next();
                    }
                    _feedback = null;
                    _early = false;
                  });
                  _armBeat();
                },
                child: Text(hu ? 'Mehet' : 'Ready'),
              ),
            ],
            if (!demo && !_ended) ...[
              Text(
                s.rhythmYourTurn(game.entered, game.sequence.length),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (game.round == 1)
                Text(
                  hu
                      ? 'Most koppints az előbb látott mozdulatra.'
                      : 'Now tap the move you just saw.',
                ),
            ],
            if (!_ended)
              for (final action in RhythmAction.values)
                OutlinedButton(
                  key: ValueKey('mai-hit-${action.name}'),
                  onPressed: () => _hit(action),
                  child: Text(label(action)),
                ),
            if (!_ended)
              Text(
                hu
                    ? 'Billentyűzet: 1, 2, 3 fentről lefelé.'
                    : 'Keyboard: 1, 2, 3 from top to bottom.',
              ),
            if (_feedback != null)
              Semantics(
                liveRegion: true,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    _missedBeat || _early || game.phase == RhythmPhase.mistake
                        ? Icons.error_outline
                        : Icons.check_circle_outline,
                  ),
                  title: Text(_feedback!),
                ),
              ),
            if (_ended) ...[
              Text(_best(hu, widget.record.record.best)),
              if (!_saving && !_failed)
                Text(
                  hu
                      ? 'Szép munka, köszönöm a játékot!'
                      : 'Well played. Thanks for joining in!',
                ),
              Text(
                game.completed > _previous
                    ? (hu ? 'Új rekord!' : 'New personal best!')
                    : hu
                    ? '${math.max(0, _previous - game.completed)} körre a rekordtól'
                    : '${math.max(0, _previous - game.completed)} rounds from your best',
              ),
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
                onPressed: _saving || _failed
                    ? null
                    : () => setState(() {
                        _previous = widget.record.record.best;
                        _feedback = null;
                        _missedBeat = false;
                        game.restart();
                      }),
                child: Text(s.rhythmNew),
              ),
              TextButton(
                key: const ValueKey('mai-end-week'),
                onPressed: _saving || _failed
                    ? null
                    : () => Navigator.of(context).pop(true),
                child: Text(
                  widget.adventureSave != null
                      ? (hu ? 'Vissza a kalandhoz' : 'Back to the adventure')
                      : (hu ? 'Heti áttekintés' : 'Weekly overview'),
                ),
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
    if (look != null &&
        controller != null &&
        !_requested &&
        MentiMotionScope.animateOf(context)) {
      _requested = true;
      // The player registers its visible host first. Never queue a reaction
      // for a result that the player has already dismissed.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
          controller.request(
            widget.completed
                ? MentiLifeReaction.congratulation
                : MentiLifeReaction.thinking,
            token: 'mai-result-${identityHashCode(this)}',
            manual: true,
          );
        });
        WidgetsBinding.instance.ensureVisualUpdate();
      });
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: MentiMotionScope.animateOf(context)
          ? const Duration(milliseconds: 520)
          : Duration.zero,
      child: look == null
          ? const MentiFitnessArtwork()
          : MentiAnimationPlayer(look: look, size: 120),
      builder: (_, progress, child) => Transform.translate(
        offset: Offset(0, -4 * math.sin(progress * math.pi)),
        child: child,
      ),
    );
  }
}
