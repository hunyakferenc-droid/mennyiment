import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'data_backup.dart';
import 'drink_journal.dart';

/// Overlay restore: keys absent from older backups are never deleted.
/// A preview is bound to the exact local snapshot the user reviewed.
class RestorePlan {
  RestorePlan._(this.document, this.before, this.after);
  final BackupDocument document;
  final Map<String, Object> before;
  final Map<String, Object> after;
  List<String> get keys => after.keys.toList()..sort();
  int get added => keys.where((k) => !before.containsKey(k)).length;
  int get replaced => keys.where((k) => before.containsKey(k) &&
      jsonEncode(before[k]) != jsonEncode(after[k])).length;
  int get unchanged => keys.length - added - replaced;
}

class RestoreFailure implements Exception {
  const RestoreFailure({required this.recoveryRequired});
  final bool recoveryRequired;
}

class BackupRestorer {
  BackupRestorer({Future<SharedPreferences> Function()? openPreferences})
      : _open = openPreferences ?? SharedPreferences.getInstance;
  final Future<SharedPreferences> Function() _open;
  // Internal transaction metadata, deliberately outside the exported namespace.
  static const recoveryKey = '__mennyiment_restore_rollback_v1';
  static bool _busy = false;

  static Map<String, Object> _snapshot(SharedPreferences p) => {
    for (final k in (p.getKeys().where(BackupDocument.ownedKey).toList()..sort()))
      k: p.get(k) is List<String> ? List<String>.of(p.getStringList(k)!) : p.get(k)!,
  };
  static bool _same(Object? a, Object? b) => jsonEncode(a) == jsonEncode(b);

  static Map<String, Object> _values(BackupDocument doc) {
    final entries = (jsonDecode(doc.json) as Map)['entries'] as Map;
    return {for (final e in entries.entries) e.key as String: switch (e.value['type']) {
      'int' => int.parse(e.value['value'] as String),
      'double' => double.parse(e.value['value'] as String),
      'stringList' => List<String>.from(e.value['value'] as List),
      _ => e.value['value'] as Object,
    }};
  }

  Future<RestorePlan> prepare(String text) async {
    // No preference write or migration occurs during validation or preview.
    final doc = BackupDocument.decode(text);
    final values = _values(doc);
    for (final e in values.entries) { validateRestoreValue(e.key, e.value); }
    final p = await _open();
    await p.reload();
    if (p.containsKey(recoveryKey)) throw const RestoreFailure(recoveryRequired: true);
    final before = _snapshot(p);
    // Permanent unlocks survive restoring an older, lower-XP backup.
    const rewards = 'mennyiment_menti_rewards_v1';
    if (values.containsKey(rewards) && before[rewards] is List<String>) {
      values[rewards] = <String>{...before[rewards] as List<String>,
        ...values[rewards] as List<String>}.toList()..sort();
    }
    Map<String, Object> freeze(Map<String, Object> data) => Map.unmodifiable({
      for (final e in data.entries) e.key: e.value is List<String>
          ? List<String>.unmodifiable(e.value as List<String>) : e.value,
    });
    return RestorePlan._(doc, freeze(before), freeze(values));
  }

  static Future<void> _write(SharedPreferences p, String k, Object? v) async {
    final ok = switch (v) {
      null => await p.remove(k),
      String() => await p.setString(k, v),
      int() => await p.setInt(k, v),
      double() => await p.setDouble(k, v),
      bool() => await p.setBool(k, v),
      List<String>() => await p.setStringList(k, v),
      _ => throw const FormatException('Invalid stored value'),
    };
    if (!ok) throw StateError('Persistence failed');
  }

  Future<void> restore(RestorePlan plan, {required bool confirmed}) async {
    if (!confirmed) throw StateError('Explicit confirmation required');
    if (_busy) throw StateError('Restore already running');
    _busy = true;
    try {
      final p = await _open();
      await p.reload();
      if (p.containsKey(recoveryKey)) throw const RestoreFailure(recoveryRequired: true);
      if (!_same(_snapshot(p), plan.before)) throw StateError('Preview is stale');
      // Save the entire pre-write image as a validated typed backup. Null keys
      // identify newly introduced values that rollback must remove.
      final previous = await BackupExporter(openPreferences: () async => p).capture();
      if (!_same(_snapshot(p), plan.before)) throw StateError('Preview is stale');
      final journal = jsonEncode({'backup': previous.json, 'keys': plan.keys});
      await _write(p, recoveryKey, journal);
      await p.reload();
      if (p.getString(recoveryKey) != journal) throw StateError('Recovery image not durable');
      try {
        for (final k in plan.keys) { await _write(p, k, plan.after[k]); }
        await p.reload();
        final expected = {...plan.before, ...plan.after};
        // Sort before comparing: a newly added key may precede older keys.
        if (!_same(_snapshot(p), {for (final k in (expected.keys.toList()..sort())) k: expected[k]})) {
          throw StateError('Restore verification failed');
        }
        await _write(p, recoveryKey, null);
        await p.reload();
        if (p.containsKey(recoveryKey)) throw StateError('Transaction not committed');
      } catch (_) {
        try { await _recover(p, image: journal); } catch (_) {
          throw const RestoreFailure(recoveryRequired: true);
        }
        throw const RestoreFailure(recoveryRequired: false);
      }
    } finally { _busy = false; }
  }

  /// Called before any app screen/store is mounted. Interrupted transactions
  /// always roll back. A failed recovery keeps the app closed to further edits.
  Future<void> recover() async {
    final p = await _open();
    await p.reload();
    if (p.containsKey(recoveryKey)) await _recover(p);
  }

  static Future<void> _recover(SharedPreferences p, {String? image}) async {
    // A failed remove may already have persisted. Re-arm the recovery record
    // before rollback so a second interruption still has a durable pre-image.
    if (image != null && p.get(recoveryKey) != image) {
      await _write(p, recoveryKey, image);
      await p.reload();
      if (p.get(recoveryKey) != image) throw StateError('Recovery not durable');
    }
    final raw = image ?? p.get(recoveryKey);
    if (raw is! String) throw StateError('Invalid recovery journal');
    final journal = jsonDecode(raw);
    if (journal is! Map || journal['backup'] is! String || journal['keys'] is! List) {
      throw StateError('Invalid recovery journal');
    }
    final before = _values(BackupDocument.decode(journal['backup'] as String));
    final keys = journal['keys'] as List;
    if (!keys.every((k) => k is String && BackupDocument.ownedKey(k))) {
      throw StateError('Invalid recovery keys');
    }
    // Attempt all keys, even when one rollback write fails.
    var failed = false;
    for (final k in keys.cast<String>()) {
      try { await _write(p, k, before[k]); } catch (_) { failed = true; }
    }
    await p.reload();
    if (failed || keys.any((k) => !_same(p.get(k as String), before[k]))) {
      throw StateError('Recovery incomplete');
    }
    await _write(p, recoveryKey, null);
    await p.reload();
    if (p.containsKey(recoveryKey)) throw StateError('Recovery incomplete');
  }
}

/// Validate embedded documents before writes, retaining their original text and
/// unknown fields. Export remains lossless even for unreadable historical data.
void validateRestoreValue(String key, Object value) {
  void require(bool condition) {
    if (!condition) throw FormatException('Invalid restore value: $key');
  }
  const lists = {'mennyiment_favorites_v1', 'mennyiment_reflection_days_v1',
    'mennyiment_menti_rewards_v1'};
  const bools = {'mennyiment_reduce_motion_v1', 'mennyiment_character_setup_complete_v1'};
  const ints = {'mennyiment_studio_background_v2', 'mennyiment_savings_baseline_v1',
    'mennyiment_finance_baseline_v1', 'mennyiment_budget_v2', 'mennyiment_avatar_v1',
    'mennyiment_hat_v1', 'mennyiment_accessory_v1'};
  const strings = {'mennyiment_locale_v1', 'mennyiment_nickname_v1',
    'mennyiment_character_style_v2', 'mennyiment_outfit_v2',
    'mennyiment_age_group_v1', 'mennyiment_character_name_v1',
    'mennyiment_menti_age_style_v1', 'mennyiment_menti_accessory_v1',
    'mennyiment_menti_aura_v1', 'mennyiment_mood_v2', 'mennyiment_character_color_v2'};
  if (strings.contains(key)) { require(value is String); return; }
  if (lists.contains(key)) { require(value is List<String>); return; }
  if (bools.contains(key)) { require(value is bool); return; }
  if (ints.contains(key)) { require(value is int); return; }
  if (key == 'mennyiment_menti_style_v1') {
    require(value is int || value is String); return;
  }
  const listJson = {'mennyiment_drinks_v1', 'mennyiment_custom_drinks_v1',
    'mennyiment_wellbeing_v1', 'mennyiment_savings_goals_v1'};
  const mapJson = {'mennyiment_menti_xp_v2', 'mennyiment_menti_progress_v1',
    'mennyiment_personal_goals_v1', 'mennyiment_weekly_challenges_v1'};
  final daily = key.startsWith('mennyiment_daily_menti_v1_');
  if (!listJson.contains(key) && !mapJson.contains(key) && !daily) {
    // Unknown future app keys retain their exact supported preference type.
    return;
  }
  require(value is String);
  final data = jsonDecode(value as String);
  require(listJson.contains(key) ? data is List : data is Map<String, dynamic>);
  if (listJson.contains(key)) {
    for (final item in data as List) {
      require(item is Map<String, dynamic>);
      final m = item as Map<String, dynamic>;
      if (key == 'mennyiment_drinks_v1') Drink.fromJson(m);
      if (key == 'mennyiment_custom_drinks_v1') {
        Drink.fromJson({...m, 'time': '2000-01-01T00:00:00.000'});
        require(m['emoji'] is String && (m['category'] == null || m['category'] is String));
      }
      if (key == 'mennyiment_wellbeing_v1') {
        require(m['day'] is String && DateTime.tryParse(m['day'] as String) != null);
        require(m['mood'] is num && m['sleep'] is num && m['hangover'] is num);
        require(m['note'] == null || m['note'] is String);
      }
      if (key == 'mennyiment_savings_goals_v1') {
        require(m['id'] is String && m['title'] is String && m['targetFt'] is num && m['savedFt'] is num);
        require(m['emoji'] == null || m['emoji'] is String);
      }
    }
  }
  if (daily) {
    final date = key.substring('mennyiment_daily_menti_v1_'.length);
    require(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date) &&
        DateTime.tryParse(date)?.toIso8601String().startsWith(date) == true);
    for (final f in ['mood', 'energy']) {
      final v = data[f]; require(v == null || (v is int && v >= 1 && v <= 5));
    }
    for (final f in ['goal', 'evening']) { require(data[f] == null || data[f] is String); }
  }
  if (key == 'mennyiment_menti_xp_v2' || key == 'mennyiment_menti_progress_v1') {
    require(data['xp'] is int && (data['xp'] as int) >= 0);
    for (final f in ['days', 'completed']) {
      require(data[f] == null || (data[f] is List && (data[f] as List).every((v) => v is String)));
    }
  }
  if (key == 'mennyiment_personal_goals_v1') {
    for (final f in ['weeklyBudget', 'reflectionGoal']) { require(data[f] == null || data[f] is num); }
    require(data['reflectionDays'] == null || (data['reflectionDays'] is List &&
        (data['reflectionDays'] as List).every((v) => v is String)));
  }
  if (key == 'mennyiment_weekly_challenges_v1') {
    require(data['version'] == 1 && data['weeks'] is Map);
    for (final week in (data['weeks'] as Map).values) {
      require(week is Map);
      for (final c in (week as Map).values) {
        require(c is Map);
        require(c['goal'] is int && c['goal'] >= 1 && c['goal'] <= 7 &&
            c['days'] is List && (c['days'] as List).every((v) => v is String) &&
            ['active', 'skipped', 'stopped'].contains(c['status']) && c['title'] is String);
      }
    }
  }
}
