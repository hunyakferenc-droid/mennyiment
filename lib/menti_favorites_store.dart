import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The existing favorite key and IDs; no migration or second storage.
class MentiFavoritesStore {
  static const key = 'mennyiment_favorites_v1';
  static bool _writing = false;
  List<String>? _snapshot;
  Set<String> get values => Set.unmodifiable(_snapshot ?? const <String>[]);
  bool ready = false, saving = false;

  List<String>? _read(Object? raw) {
    if (raw == null) return null;
    if (raw is! List || raw.any((value) => value is! String)) {
      throw const FormatException('Unknown favorite storage');
    }
    return List<String>.from(raw);
  }

  Future<void> load() async {
    if (saving || _writing) return;
    ready = false;
    try {
      final p = await SharedPreferences.getInstance();
      await p.reload();
      _snapshot = _read(p.get(key));
      ready = true;
    } catch (_) {
      // Unknown/corrupt storage remains untouched.
    }
  }

  Future<bool> toggle(String id) async {
    if (!ready || saving || _writing) return false;
    saving = _writing = true;
    try {
      final p = await SharedPreferences.getInstance();
      await p.reload();
      final raw = _read(p.get(key));
      if (!listEquals(raw, _snapshot)) {
        ready = false;
        return false;
      }
      final next = List<String>.of(_snapshot ?? const []);
      if (next.contains(id)) {
        next.removeWhere((v) => v == id);
      } else {
        next.add(id);
      }
      if (!await p.setStringList(key, next)) {
        await p.reload();
        return false;
      }
      await p.reload();
      if (!listEquals(_read(p.get(key)), next)) {
        ready = false;
        return false;
      }
      _snapshot = next;
      return true;
    } catch (_) {
      ready = false;
      return false;
    } finally {
      saving = _writing = false;
    }
  }
}
