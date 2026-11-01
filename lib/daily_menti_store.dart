import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'menti_xp_store.dart';

/// Additive, per-local-calendar-day storage. Never writes journal/profile keys.
class DailyMentiStore {
  static const prefix = 'mennyiment_daily_menti_v1_';

  static String key(DateTime date) =>
      '$prefix${MentiXpStore.dayKey(date.toLocal())}';

  static Future<Map<String, dynamic>> load(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.get(key(date));
    if (raw == null) return {};
    return decodeDocument(raw);
  }

  /// Pure decoder; unlike load/save, this needs no preferences instance.
  static Map<String, dynamic> decodeDocument(Object raw) {
    if (raw is! String) throw const FormatException('Invalid daily record');
    final data = jsonDecode(raw);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid daily record');
    }
    for (final field in ['mood', 'energy']) {
      final value = data[field];
      if (value != null && (value is! int || value < 1 || value > 5)) {
        throw const FormatException('Invalid rating');
      }
    }
    for (final field in ['goal', 'evening']) {
      if (data[field] != null && data[field] is! String) {
        throw const FormatException('Invalid text');
      }
    }
    return data;
  }

  /// Save answers first. If XP persistence fails, retrying is idempotent and
  /// the answers survive. Unknown fields in this document remain intact.
  static Future<MentiXpState> save({
    required DateTime date,
    required int? mood,
    required int? energy,
    required String goal,
    required String evening,
  }) async {
    for (final rating in [mood, energy]) {
      if (rating != null && (rating < 1 || rating > 5)) {
        throw ArgumentError.value(rating, 'rating');
      }
    }
    final data = await load(date);
    data.addAll({
      'mood': mood,
      'energy': energy,
      'goal': goal.trim(),
      'evening': evening.trim(),
    });
    final prefs = await SharedPreferences.getInstance();
    try {
      if (!await prefs.setString(key(date), jsonEncode(data))) {
        throw StateError('Daily answers were not saved');
      }
    } catch (_) {
      await prefs.reload();
      rethrow;
    }
    return MentiXpStore.checkInToday(now: date);
  }
}
