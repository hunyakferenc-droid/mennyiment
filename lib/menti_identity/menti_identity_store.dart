import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import 'menti_identity.dart';

/// Mount only after backup recovery. Loading/migration never writes preferences.
/// A corrupt or future document remains untouched and blocks all writes.
class MentiIdentityStore {
  MentiIdentityStore({Future<SharedPreferences> Function()? open})
      : open = open ?? SharedPreferences.getInstance;
  static const key = 'mennyiment_identity_v22';
  final Future<SharedPreferences> Function() open;
  MentiIdentityDocument document = MentiIdentityDocument(profile: MentiIdentityProfile());
  Object? _raw;
  bool writable = false;
  bool busy = false;
  bool migrated = false;
  String? error;
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
    error = null;
    final prefs = await open();
    await prefs.reload();
    _raw = prefs.get(key);
    final legacy = <String, Object?>{
      for (final k in prefs.getKeys())
        if (k.startsWith('mennyiment_') && k != key &&
            (k.contains('menti_') || k.contains('character_') ||
             k == 'mennyiment_outfit_v2' || k == 'mennyiment_age_group_v1' ||
             k == 'mennyiment_mood_v2' || k == 'mennyiment_nickname_v1' ||
             k == 'mennyiment_hat_v1' || k == 'mennyiment_accessory_v1' ||
             k == 'mennyiment_avatar_v1')) k: prefs.get(k),
    };
    migrated = _raw == null;
    try {
      document = _raw == null ? MentiIdentityDocument.fromLegacy(legacy)
          : MentiIdentityDocument.decode(_raw);
      writable = true;
    } on FormatException {
      // Display a safe fallback, never replace the unreadable source.
      document = MentiIdentityDocument.fromLegacy(legacy);
      error = 'unreadable';
    }
  });

  /// Atomic snapshot write with optimistic conflict detection across store instances.
  /// Unlocks are union-only, even when applying a preset or resetting appearance.
  Future<bool> save(MentiIdentityDocument next) async {
    if (!writable || busy) return false;
    busy = true;
    return _serial(() async {
      SharedPreferences? prefs;
      try {
        prefs = await open();
        await prefs.reload();
        final original = document.toJson()['migration'];
        final legacy = original is Map ? original['original'] : null;
        final legacyChanged = _raw == null && legacy is Map && legacy.entries.any((e) =>
          prefs.get(e.key as String).toString() != e.value.toString());
        if (prefs.get(key) != _raw || legacyChanged) {
          writable = false;
          error = 'conflict';
          return false;
        }
        final preservedUnlocks = MentiUnlockState(
          unlocked: {...document.unlocks.unlocked, ...next.unlocks.unlocked},
          seen: {...document.unlocks.seen, ...next.unlocks.seen},
          extras: {...document.unlocks.toJson(), ...next.unlocks.toJson()});
        // Merge top-level extension fields from the loaded document as well.
        final mergedProfile = <String, dynamic>{
          ...document.profile.toJson(), ...next.profile.toJson(),
          'visual': {...document.profile.visual.toJson(), ...next.profile.visual.toJson()},
          'reaction': {...document.profile.reaction.toJson(), ...next.profile.reaction.toJson()},
        };
        final candidate = MentiIdentityDocument(
          profile: MentiIdentityProfile.fromJson(mergedProfile), presets: next.presets, unlocks: preservedUnlocks,
          extras: {...document.toJson(), ...next.toJson()});
        final encoded = candidate.encode();
        final validated = MentiIdentityDocument.decode(encoded);
        if (_raw == encoded) return true;
        if (!await prefs.setString(key, encoded)) {
          throw StateError('Identity write not confirmed');
        }
        document = validated;
        _raw = encoded;
        migrated = false;
        error = null;
        return true;
      } catch (_) {
        error = 'save';
        try { await prefs?.reload(); } catch (_) { writable = false; }
        return false;
      } finally {
        busy = false;
      }
    });
  }
}
