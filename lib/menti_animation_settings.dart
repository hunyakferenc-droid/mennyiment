import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data_backup.dart';
import 'menti_reaction_engine.dart';

class MentiAnimationPreference {
  const MentiAnimationPreference({
    this.enabled = true,
    this.frequency = MentiAnimationFrequency.normal,
    this.extras = const {},
  });
  final bool enabled;
  final MentiAnimationFrequency frequency;
  final Map<String, dynamic> extras;
  factory MentiAnimationPreference.decode(Object? raw) {
    if (raw == null) return const MentiAnimationPreference();
    if (raw is! String) {
      throw const FormatException('Invalid animation settings');
    }
    final j = decodeBackupJson(raw);
    if (j is! Map<String, dynamic> ||
        j['version'] != 1 ||
        j['enabled'] is! bool ||
        !MentiAnimationFrequency.values.any((f) => f.name == j['frequency'])) {
      throw const FormatException('Unknown animation settings');
    }
    return MentiAnimationPreference(
      enabled: j['enabled'],
      frequency: MentiAnimationFrequency.values.byName(j['frequency']),
      extras: Map.unmodifiable({
        for (final e in j.entries)
          if (!['version', 'enabled', 'frequency'].contains(e.key))
            e.key: e.value,
      }),
    );
  }
  String encode() => jsonEncode({
    ...extras,
    'version': 1,
    'enabled': enabled,
    'frequency': frequency.name,
  });
}

class MentiAnimationSettings extends ChangeNotifier {
  MentiAnimationSettings({Future<SharedPreferences> Function()? open})
    : open = open ?? SharedPreferences.getInstance;
  static bool _writing = false;
  static const key = 'mennyiment_life_settings_v1';
  final Future<SharedPreferences> Function() open;
  MentiAnimationPreference value = const MentiAnimationPreference();
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
      value = MentiAnimationPreference.decode(raw);
      _snapshot = raw;
      ready = true;
      error = null;
    } catch (_) {
      ready = false;
      error = 'load';
    }
    _notify();
  }

  Future<bool> save({
    required bool enabled,
    required MentiAnimationFrequency frequency,
  }) async {
    if (!ready || saving || _writing || _disposed) return false;
    _writing = true;
    saving = true;
    error = null;
    _notify();
    try {
      final p = await open();
      await p.reload();
      if (p.containsKey('__mennyiment_restore_rollback_v1') ||
          p.get(key) != _snapshot) {
        ready = false;
        throw StateError('Stale settings');
      }
      final next = MentiAnimationPreference(
            enabled: enabled,
            frequency: frequency,
            extras: value.extras,
          ),
          raw = next.encode();
      if (!await p.setString(key, raw)) {
        throw StateError('Unconfirmed settings');
      }
      await p.reload();
      if (p.get(key) != raw) {
        ready = false;
        throw StateError('Settings changed');
      }
      _snapshot = raw;
      value = next;
      return true;
    } catch (_) {
      error = 'save';
      try {
        await (await open()).reload();
      } catch (_) {
        ready = false;
      }
      return false;
    } finally {
      _writing = false;
      saving = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
