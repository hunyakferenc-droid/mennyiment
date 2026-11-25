import 'dart:convert';

import 'data_backup.dart';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

String clubDay(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
DateTime nextClubTrialDay(DateTime day) =>
    DateTime(day.year, day.month, day.day + 1);

DateTime parseClubDay(String raw) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) {
    throw const FormatException('Invalid club date');
  }
  final y = int.parse(raw.substring(0, 4)),
      m = int.parse(raw.substring(5, 7)),
      d = int.parse(raw.substring(8, 10));
  final day = DateTime(y, m, d);
  if (clubDay(day) != raw) throw const FormatException('Invalid club date');
  return day;
}

class MentiClubRecord {
  const MentiClubRecord({
    this.best = 0,
    this.days = const [],
    this.last,
    this.extras = const {},
  });
  final int best;
  final List<String> days;
  final String? last;
  final Map<String, dynamic> extras;
  static MentiClubRecord decode(Object? raw) {
    if (raw == null) return const MentiClubRecord();
    if (raw is! String) throw const FormatException('Invalid club storage');
    final j = decodeBackupJson(raw);
    if (j is! Map<String, dynamic> ||
        j['version'] != 1 ||
        j['best'] is! int ||
        j['best'] < 0 ||
        j['best'] > 5 ||
        j['days'] is! List ||
        j['days'].length > 7 ||
        (j['last'] != null && j['last'] is! String)) {
      throw const FormatException('Unknown club storage');
    }
    final days = <String>[];
    for (final d in j['days']) {
      if (d is! String) throw const FormatException('Invalid club day');
      parseClubDay(d);
      if (days.contains(d) ||
          (days.isNotEmpty && d.compareTo(days.last) <= 0)) {
        throw const FormatException('Duplicate or unordered club day');
      }
      days.add(d);
    }
    final last = j['last'] as String?;
    if (last != null) parseClubDay(last);
    if (days.isNotEmpty && last != days.last) {
      throw const FormatException('Club last day mismatch');
    }
    return MentiClubRecord(
      best: j['best'],
      days: List.unmodifiable(days),
      last: last,
      extras: Map.unmodifiable({
        for (final e in j.entries)
          if (!['version', 'best', 'days', 'last'].contains(e.key))
            e.key: e.value,
      }),
    );
  }

  int? scoreOn(String day) {
    final scores = extras['dailyScores'];
    final score = scores is Map ? scores[day] : null;
    return score is int && score >= 0 && score <= 3 ? score : null;
  }

  String encode() => jsonEncode({
    ...extras,
    'version': 1,
    'best': best,
    'days': days,
    'last': last,
  });
}

enum ClubSave { saved, alreadyToday, full, failed }

/// REVIEW-only local record, separate from journal/XP and from demonstration data.
/// Unknown or corrupt snapshots are read-only; never automatically reset.
class MentiClubStore extends ChangeNotifier {
  MentiClubStore({
    this.key = normalKey,
    DateTime Function()? clock,
    Future<SharedPreferences> Function()? open,
  }) : clock = clock ?? DateTime.now,
       open = open ?? SharedPreferences.getInstance;
  static const normalKey = 'mennyiment_fitness_club_v1',
      testKey = 'mennyiment_fitness_club_test_v1',
      dailyRhythmKey = 'mennyiment_mai_menti_rhythm_v1',
      dailyRhythmTestKey = 'mennyiment_mai_menti_test_rhythm_v1';
  static final Set<String> _writing = {};
  final String key;
  final DateTime Function() clock;
  final Future<SharedPreferences> Function() open;
  MentiClubRecord record = const MentiClubRecord();
  bool ready = false, saving = false, _disposed = false;
  String? error;
  Object? _snapshot;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    if (saving || _disposed) return;
    try {
      final p = await open();
      await p.reload();
      final raw = p.get(key);
      final next = MentiClubRecord.decode(raw);
      _snapshot = raw;
      record = next;
      ready = true;
      error = null;
    } catch (_) {
      ready = false;
      error = 'load';
    }
    _notify();
  }

  Future<ClubSave> rhythm(int rounds) =>
      _save(rounds: rounds, complete: rounds == 5);
  Future<ClubSave> dailyRhythm(int rounds, DateTime date) {
    if ((key != dailyRhythmKey && key != dailyRhythmTestKey) ||
        rounds < 0 || rounds > 3) {
      return Future.value(ClubSave.failed);
    }
    return _save(rounds: rounds, scoreDay: clubDay(date));
  }

  Future<ClubSave> cards() => _save(complete: true);
  Future<ClubSave> newChallenge() => _save(reset: true);
  Future<ClubSave> _save({
    int? rounds,
    bool complete = false,
    bool reset = false,
    String? scoreDay,
  }) async {
    if (!ready ||
        saving ||
        _disposed ||
        _writing.contains(key) ||
        (rounds != null && (rounds < 0 || rounds > 5)) ||
        (reset && record.days.length != 7)) {
      return ClubSave.failed;
    }
    saving = true;
    _writing.add(key);
    error = null;
    _notify();
    try {
      final p = await open();
      await p.reload();
      if (p.containsKey('__mennyiment_restore_rollback_v1') ||
          p.get(key) != _snapshot) {
        ready = false;
        throw StateError('Stale club snapshot');
      }
      final today = clubDay(clock());
      if (complete &&
          record.last != null &&
          today.compareTo(record.last!) < 0) {
        throw StateError('Club clock moved backwards');
      }
      final days = List<String>.of(record.days);
      var last = record.last, result = ClubSave.saved;
      if (reset) {
        days.clear();
      } else if (complete) {
        if (last == today) {
          result = ClubSave.alreadyToday;
        } else if (days.length == 7) {
          result = ClubSave.full;
        } else {
          days.add(today);
          last = today;
        }
      }
      var extras = record.extras;
      if (scoreDay != null) {
        final oldScores = extras['dailyScores'];
        final scores = <String, dynamic>{
          if (oldScores is Map<String, dynamic>) ...oldScores,
        };
        if (scores[scoreDay] is! int || rounds! > (scores[scoreDay] as int)) {
          scores[scoreDay] = rounds;
        }
        final dates = scores.keys.toList()..sort();
        for (final expired in dates.take(dates.length > 31 ? dates.length - 31 : 0)) {
          scores.remove(expired);
        }
        extras = {...extras, 'dailyScores': scores};
      }
      final next = MentiClubRecord(
        best: rounds != null && rounds > record.best ? rounds : record.best,
        days: List.unmodifiable(days),
        last: last,
        extras: extras,
      );
      final encoded = next.encode();
      if (encoded != _snapshot) {
        if (!await p.setString(key, encoded)) {
          throw StateError('Unconfirmed club write');
        }
        await p.reload();
        if (p.get(key) != encoded) {
          ready = false;
          throw StateError('Club changed during write');
        }
        _snapshot = encoded;
      }
      record = next;
      return result;
    } catch (_) {
      error = 'save';
      return ClubSave.failed;
    } finally {
      saving = false;
      _writing.remove(key);
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
