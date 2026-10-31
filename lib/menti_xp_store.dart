import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// MennyiMent? 7.2 – egyetlen XP-forrás a kezdőlap és a fejlődési oldal számára.
/// A migráció konzervatív: a két régi számláló maximumát őrzi meg,
/// így nem ad kétszer XP-t a korábban mindkét helyen jelölt napokért.
class MentiXpState {
  const MentiXpState({
    required this.xp,
    required this.days,
    required this.completed,
  });

  final int xp;
  final Set<String> days;
  final Set<String> completed;

  int get level => 1 + xp ~/ 50;
  int get levelXp => xp % 50;
  double get progress => levelXp / 50;
  bool checkedOn(DateTime date) => days.contains(MentiXpStore.dayKey(date));
  bool completedThisWeek(String id, DateTime date) =>
      completed.contains('${MentiXpStore.weekKey(date)}:$id');
}

class MentiXpStore {
  static const _key = 'mennyiment_menti_xp_v2';
  static const _reflectionKey = 'mennyiment_reflection_days_v1';
  static const _legacyProgressKey = 'mennyiment_menti_progress_v1';
  static const Map<String, int> weeklyPoints = {
    'review': 15,
    'cost': 15,
    'goal': 20,
  };

  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String weekKey(DateTime d) => dayKey(
      DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1)));

  static Map<String, dynamic> _decode(String? raw) {
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      // Hibás régi érték ne állítsa le a teljes appot.
    }
    return {};
  }

  static Set<String> _strings(dynamic value) => value is List
      ? value.whereType<String>().toSet()
      : <String>{};

  static MentiXpState _fromData(Map<String, dynamic> data) => MentiXpState(
        xp: ((data['xp'] as num?)?.toInt() ?? 0).clamp(0, 10000000),
        days: _strings(data['days']),
        completed: _strings(data['completed']),
      );

  // Serialize every read/mutation in this isolate, including legacy migration.
  // A failed write must not block later retries.
  static Future<void> _pending = Future<void>.value();
  static Future<T> _serial<T>(Future<T> Function() action) {
    final result = _pending.then((_) => action());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  static Future<MentiXpState> load() => _serial(_load);

  static Future<MentiXpState> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final current = _decode(prefs.getString(_key));
    if (current.containsKey('xp')) return _fromData(current);

    final reflectionDays = (prefs.getStringList(_reflectionKey) ?? <String>[]).toSet();
    final old = _decode(prefs.getString(_legacyProgressKey));
    final oldLastCheckin = old['lastCheckin'];
    if (oldLastCheckin is String && oldLastCheckin.isNotEmpty) {
      reflectionDays.add(oldLastCheckin);
    }
    final legacyXp = ((old['xp'] as num?)?.toInt() ?? 0).clamp(0, 10000000);
    final state = MentiXpState(
      xp: legacyXp > reflectionDays.length * 10
          ? legacyXp
          : reflectionDays.length * 10,
      days: reflectionDays,
      completed: _strings(old['completed']),
    );
    await _save(state);
    return state;
  }

  static Future<void> _save(MentiXpState state) async {
    final prefs = await SharedPreferences.getInstance();
    late final bool result;
    try {
      result = await prefs.setString(_key, jsonEncode({
      'xp': state.xp,
      'days': state.days.toList()..sort(),
      'completed': state.completed.toList()..sort(),
      }));
    } catch (_) {
      await prefs.reload();
      rethrow;
    }
    if (!result) {
      // SharedPreferences updates its cache even when persistence returns false.
      await prefs.reload();
      throw StateError('A Menti XP mentése sikertelen.');
    }
    // Megtartjuk a korábbi napi önellenőrzés kulcsát is az átmenethez.
    await prefs.setStringList(_reflectionKey, state.days.toList()..sort());
  }

  /// Mindkét képernyő ugyanazt a napi eseményt használja.
  static Future<MentiXpState> checkInToday({DateTime? now}) {
    // Capture the local calendar day before waiting for another storage operation.
    final today = dayKey((now ?? DateTime.now()).toLocal());
    return _serial(() async {
      final current = await _load();
      if (current.days.contains(today)) return current;
      final updated = MentiXpState(
        xp: current.xp + 10,
        days: {...current.days, today},
        completed: current.completed,
      );
      await _save(updated);
      return updated;
    });
  }

  static Future<MentiXpState> completeWeekly(String id) => _serial(() async {
    final points = weeklyPoints[id];
    if (points == null) throw ArgumentError.value(id, 'id', 'Ismeretlen kihívás');
    final current = await _load();
    final event = '${weekKey(DateTime.now())}:$id';
    if (current.completed.contains(event)) return current;
    final updated = MentiXpState(
      xp: current.xp + points,
      days: current.days,
      completed: {...current.completed, event},
    );
    await _save(updated);
    return updated;
  });
}

