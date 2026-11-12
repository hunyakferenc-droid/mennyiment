import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'data_backup.dart';
import 'menti_access.dart';
import 'menti_completion.dart';

/// Stable local identifiers. Every activity concerns wellbeing, never drinking.
enum AdventureTask { wellbeing, movement, rest, decision, goal }

const adventureTargets = [3, 6, 10, 15, 21];
const adventureBadges = ['first', 'variety', 'station'];

String adventureDay(DateTime date) => mentiDateKey(date.toLocal());

bool _hasWellbeing(Object? raw, DateTime now) {
  if (raw is! String) return false;
  try {
    final value = decodeBackupJson(raw);
    if (value is! List) return false;
    for (final item in value) {
      if (item is! Map || item['day'] is! String) return false;
      for (final field in ['mood', 'sleep', 'hangover']) {
        final rating = item[field];
        if (rating is! int ||
            rating < (field == 'hangover' ? 0 : 1) ||
            rating > (field == 'hangover' ? 4 : 5)) {
          return false;
        }
      }
      if (item['note'] != null && item['note'] is! String) return false;
    }
    return recordedWellbeingDays(raw, now).contains(adventureDay(now));
  } catch (_) {
    return false;
  }
}

class AdventureDocument {
  AdventureDocument._(this._data);
  final Map<String, dynamic> _data;

  static AdventureDocument decode(Object? raw) {
    if (raw == null) {
      return AdventureDocument._({'version': 1, 'days': {}, 'badges': {}});
    }
    if (raw is! String || raw.length > BackupDocument.maxBytes) {
      throw const FormatException('Invalid adventure document');
    }
    final value = decodeBackupJson(raw);
    void require(bool valid) {
      if (!valid) throw const FormatException('Unsupported adventure state');
    }

    require(value is Map<String, dynamic>);
    final data = value as Map<String, dynamic>;
    require(data['version'] is int && data['version'] == 1);
    require(data['days'] is Map && data['badges'] is Map);
    for (final entry in (data['days'] as Map).entries) {
      final day = DateTime.tryParse(entry.key.toString());
      require(day != null && mentiDateKey(day) == entry.key);
      require(entry.value is Map);
      final tasks = entry.value as Map;
      var occupied = 0;
      for (final item in tasks.entries) {
        require(AdventureTask.values.any((t) => t.name == item.key));
        require(item.value is Map);
        final task = item.value as Map;
        require(['active', 'completed', 'cancelled'].contains(task['status']));
        require(_timestamp(task['selectedAt']));
        if (task['status'] != 'cancelled') occupied++;
        if (task['status'] == 'completed') {
          require(_timestamp(task['completedAt']));
          require(
            !DateTime.parse(task['completedAt'])
                .isBefore(DateTime.parse(task['selectedAt'])),
          );
          require(task['reactionConsumed'] == true);
          if (item.key == AdventureTask.decision.name) {
            require(
              task['note'] is String &&
                  (task['note'] as String).trim().isNotEmpty,
            );
          }
        } else {
          require(!task.containsKey('completedAt'));
        }
        require(
          task['note'] == null ||
              (task['note'] is String &&
                  (task['note'] as String).length <= 500),
        );
      }
      require(occupied <= 3);
    }
    final doc = AdventureDocument._(data);
    for (final badge in (data['badges'] as Map).entries) {
      require(adventureBadges.contains(badge.key) && _timestamp(badge.value));
      // A badge never substitutes for actual completed activity records.
      require(doc._qualifies(badge.key));
    }
    return doc;
  }

  static bool _timestamp(Object? value) {
    if (value is! String) return false;
    final date = DateTime.tryParse(value);
    return date != null && date.isUtc && date.toIso8601String() == value;
  }

  Map<String, dynamic> toJson() =>
      jsonDecode(jsonEncode(_data)) as Map<String, dynamic>;
  String encode() => jsonEncode(_data);
  Map<String, dynamic> tasks(DateTime day) => Map<String, dynamic>.unmodifiable(
    (toJson()['days'] as Map)[adventureDay(day)] as Map? ?? {},
  );
  String? status(DateTime day, AdventureTask task) =>
      (tasks(day)[task.name] as Map?)?['status'] as String?;
  int occupied(DateTime day) =>
      tasks(day).values
          .where((t) => (t as Map)['status'] != 'cancelled')
          .length;

  Iterable<(String, String, Map)> get _completed sync* {
    for (final day in (_data['days'] as Map).entries) {
      for (final task in (day.value as Map).entries) {
        if ((task.value as Map)['status'] == 'completed') {
          yield (day.key as String, task.key as String, task.value as Map);
        }
      }
    }
  }

  int completedCount(DateTime asOf) =>
      _completed.where((t) => t.$1.compareTo(adventureDay(asOf)) <= 0).length;
  int completedStations(DateTime asOf) =>
      adventureTargets.where((target) => completedCount(asOf) >= target).length;
  Map<String, DateTime> get badges => Map.unmodifiable({
    for (final e in (_data['badges'] as Map).entries)
      e.key as String: DateTime.parse(e.value as String),
  });

  bool _qualifies(String badge) => switch (badge) {
    'first' => _completed.isNotEmpty,
    'variety' => _completed.map((t) => t.$2).toSet().length >= 3,
    'station' => _completed.length >= adventureTargets.first,
    _ => false,
  };
}

enum AdventureFailure {
  load,
  save,
  stale,
  dayChanged,
  capacity,
  evidence,
  access,
}

class AdventureResult {
  const AdventureResult({this.completed = false, this.station = false});
  final bool completed, station;
}

/// One versioned document; no XP, journal or profile writes. Publish only after
/// a confirmed write AND a re-read. Snapshot checks also protect stale screens.
class AdventureStore {
  AdventureStore({
    Future<SharedPreferences> Function()? open,
    DateTime Function()? clock,
  }) : open = open ?? SharedPreferences.getInstance,
       clock = clock ?? DateTime.now;
  static const key = 'mennyiment_adventures_v1';
  final Future<SharedPreferences> Function() open;
  final DateTime Function() clock;
  AdventureDocument document = AdventureDocument.decode(null);
  bool writable = false, busy = false;
  AdventureFailure? failure;
  Object? _raw;
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
    failure = null;
    try {
      final prefs = await open();
      await prefs.reload();
      final raw = prefs.get(key);
      final next = AdventureDocument.decode(raw);
      _raw = raw;
      document = next;
      writable = true;
    } catch (_) {
      failure = AdventureFailure.load;
      rethrow;
    }
  });

  Future<AdventureResult?> select(DateTime day, AdventureTask task) =>
      _change(day, task, 'active');
  Future<AdventureResult?> cancel(DateTime day, AdventureTask task) =>
      _change(day, task, 'cancelled');
  Future<AdventureResult?> complete(
    DateTime day,
    AdventureTask task, {
    String? note,
  }) => _change(day, task, 'completed', note: note);

  Future<AdventureResult?> _change(
    DateTime day,
    AdventureTask task,
    String status, {
    String? note,
  }) async {
    if (busy || !writable) return null;
    busy = true;
    failure = null;
    return _serial(() async {
      SharedPreferences? prefs;
      try {
        final now = clock().toLocal();
        if (adventureDay(day) != adventureDay(now)) {
          failure = AdventureFailure.dayChanged;
          return null;
        }
        prefs = await open();
        await prefs.reload();
        if (prefs.get(key) != _raw ||
            prefs.containsKey('__mennyiment_restore_rollback_v1')) {
          writable = false;
          failure = AdventureFailure.stale;
          return null;
        }
        if (task == AdventureTask.goal) {
          var adult = false;
          try {
            final access = MentiAccessSettings.decode(
              prefs.get(MentiAccessSettings.key)!,
            );
            adult = access['complete'] == true && access['audience'] == 'adult';
          } catch (_) {
            /* Unknown age never authorizes adult goal screens. */
          }
          if (!adult) {
            failure = AdventureFailure.access;
            return null;
          }
        }
        final old = document.status(day, task);
        // Repeated activation is a no-op, including after an app restart.
        if (old == 'completed' || old == status) return const AdventureResult();
        if (status != 'active' && old != 'active') {
          return const AdventureResult();
        }
        if (status == 'active' && document.occupied(day) >= 3) {
          failure = AdventureFailure.capacity;
          return null;
        }
        if (status == 'completed' && task == AdventureTask.wellbeing) {
          final raw = prefs.get('mennyiment_wellbeing_v1');
          if (!_hasWellbeing(raw, now)) {
            failure = AdventureFailure.evidence;
            return null;
          }
        }
        if (status == 'completed' &&
            task == AdventureTask.decision &&
            (note == null || note.trim().isEmpty || note.length > 500)) {
          failure = AdventureFailure.evidence;
          return null;
        }
        final next = document.toJson();
        final days = next['days'] as Map;
        final tasks = Map<String, dynamic>.from(
          days[adventureDay(day)] as Map? ?? {},
        );
        final item = Map<String, dynamic>.from(tasks[task.name] as Map? ?? {});
        final timestamp = now.toUtc().toIso8601String();
        item['status'] = status;
        if (status == 'active') item['selectedAt'] = timestamp;
        if (status == 'completed') {
          item['completedAt'] = timestamp;
          // At-most-once presentation: interruption cannot queue an endless replay.
          item['reactionConsumed'] = true;
          if (task == AdventureTask.decision) item['note'] = note!.trim();
        }
        tasks[task.name] = item;
        days[adventureDay(day)] = tasks;
        final candidate = AdventureDocument._(next);
        final badges = next['badges'] as Map;
        for (final id in adventureBadges) {
          if (candidate._qualifies(id)) badges.putIfAbsent(id, () => timestamp);
        }
        final encoded = candidate.encode();
        // Day can change while awaiting platform I/O; never file an action under
        // yesterday merely because the screen was left open across midnight.
        if (adventureDay(clock()) != adventureDay(now)) {
          failure = AdventureFailure.dayChanged;
          return null;
        }
        AdventureDocument.decode(encoded);
        if (!await prefs.setString(key, encoded)) {
          throw StateError('Unconfirmed write');
        }
        await prefs.reload();
        if (prefs.get(key) != encoded) {
          writable = false;
          failure = AdventureFailure.stale;
          return null;
        }
        final station =
            candidate.completedStations(now) > document.completedStations(now);
        document = candidate;
        _raw = encoded;
        return AdventureResult(
          completed: status == 'completed',
          station: station,
        );
      } catch (_) {
        failure ??= AdventureFailure.save;
        try {
          await prefs?.reload();
        } catch (_) {
          writable = false;
        }
        return null;
      } finally {
        busy = false;
      }
    });
  }
}
