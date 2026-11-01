import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'menti_identity.dart';
import '../menti_character_catalog.dart';

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

  static Map<String, Object?> _legacyValues(SharedPreferences prefs) {
    const keys = {
      'mennyiment_menti_style_v1', 'mennyiment_character_style_v2',
      'mennyiment_outfit_v2', 'mennyiment_studio_background_v2',
      'mennyiment_age_group_v1', 'mennyiment_character_name_v1',
      'mennyiment_menti_age_style_v1', 'mennyiment_menti_accessory_v1',
      'mennyiment_menti_aura_v1', 'mennyiment_mood_v2',
      'mennyiment_character_color_v2', 'mennyiment_nickname_v1',
      'mennyiment_hat_v1', 'mennyiment_accessory_v1', 'mennyiment_avatar_v1',
      'mennyiment_menti_rewards_v1',
    };
    return {for (final k in prefs.getKeys())
      if (keys.contains(k) || k.startsWith('mennyiment_character_')) k: prefs.get(k)};
  }

  Future<void> load() => _serial(() async {
    writable = false;
    error = null;
    final prefs = await open();
    await prefs.reload();
    _raw = prefs.get(key);
    final legacy = _legacyValues(prefs);
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
        final latestLegacy = _legacyValues(prefs);
        final legacyChanged = _raw == null &&
          jsonEncode(MentiIdentityDocument.fromLegacy(latestLegacy).profile.toJson()) !=
          jsonEncode(document.profile.toJson());
        if (prefs.get(key) != _raw || legacyChanged) {
          writable = false;
          error = 'conflict';
          return false;
        }
        final savedLegacyRewards = latestLegacy['mennyiment_menti_rewards_v1'];
        final equippedLegacyOutfit = MentiOutfit.resolve(latestLegacy['mennyiment_outfit_v2']);
        final legacyUnlocks = <String>{
          if (savedLegacyRewards is List && savedLegacyRewards.every((v) => v is String))
            ...savedLegacyRewards.cast<String>(),
          if (equippedLegacyOutfit != null) 'outfit:${equippedLegacyOutfit.id}',
        };
        final preservedUnlocks = MentiUnlockState(
          unlocked: {...document.unlocks.unlocked, ...next.unlocks.unlocked,
            ...legacyUnlocks},
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
