import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'menti_collection_model.dart';
import 'menti_xp_store.dart';

/// The existing complete-look preference, extended with durable acquisition.
/// Reads XP through its existing adapter; never awards, migrates or spends XP.
class CompleteLookStore extends ChangeNotifier {
  CompleteLookStore({
    Future<SharedPreferences> Function()? open,
    this.catalog = CompleteLook.all,
  }) : open = open ?? SharedPreferences.getInstance;
  static const key = 'mennyiment_complete_look_v1';
  static bool _writing = false;
  final Future<SharedPreferences> Function() open;
  final List<CompleteLook> catalog;
  CompleteLookSelection selection = const CompleteLookSelection();
  Object? _snapshot, _xpSnapshot;
  int? xp;
  bool ready = false, saving = false, loading = false;
  String? error;
  bool _disposed = false, _refreshAgain = false;
  final List<String> _newUnlocks = [];
  bool owns(CompleteLook look) => selection.owns(look);
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  List<String> takeNewUnlocks() {
    final result = List<String>.of(_newUnlocks);
    _newUnlocks.clear();
    return result;
  }

  Future<void> load() async {
    if (saving || loading || _disposed) {
      _refreshAgain = !_disposed;
      return;
    }
    loading = true;
    try {
      final p = await open();
      await p.reload();
      final raw = p.get(key);
      final decoded = CompleteLookSelection.decode(raw, catalog: catalog);
      _xpSnapshot = p.get(MentiXpStore.currentKey);
      try {
        xp = _xpSnapshot == null
            ? 0
            : MentiXpStore.readCurrent(_xpSnapshot!).xp;
      } catch (_) {
        xp = null;
      }
      selection = decoded;
      _snapshot = raw;
      ready = true;
      error = null;
    } catch (_) {
      ready = false;
      error = 'load';
    } finally {
      loading = false;
      _notify();
    }
    if (ready && xp != null) await _acquire();
    if (_refreshAgain && !_disposed) {
      _refreshAgain = false;
      await load();
    }
  }

  Future<void> _acquire() async {
    final earned = {
      for (final look in catalog)
        if (look.minXp > 0 &&
            xp! >= look.minXp &&
            !selection.acquired.contains(look.id))
          look.id,
    };
    if (earned.isEmpty) return;
    final notices = earned.difference(selection.announced);
    final next = selection.copyWith(
      acquired: {...selection.acquired, ...earned},
      announced: {...selection.announced, ...earned},
    );
    if (await _write(next, guardXp: true)) {
      _newUnlocks.addAll(notices.toList()..sort());
      _notify();
    }
  }

  Future<bool> save(CompleteLookSelection next) async {
    if (!ready || loading || saving || _writing || _disposed) return false;
    // UI selection cannot grant XP looks or drop permanent ownership/unknown data.
    final merged = selection.copyWith(active: next.active, lookId: next.lookId);
    final look = CompleteLook.find(merged.lookId, catalog: catalog);
    if (look == null || (merged.active && !owns(look))) return false;
    final ok = await _write(merged);
    if (_refreshAgain && !_disposed) {
      _refreshAgain = false;
      await load();
    }
    return ok;
  }

  Future<bool> _write(
    CompleteLookSelection next, {
    bool guardXp = false,
  }) async {
    if (!ready || saving || loading || _writing || _disposed) return false;
    try {
      CompleteLookSelection.decode(next.encode(), catalog: catalog);
    } catch (_) {
      return false;
    }
    saving = true;
    _writing = true;
    error = null;
    _notify();
    SharedPreferences? p;
    try {
      p = await open();
      await p.reload();
      if (p.containsKey('__mennyiment_restore_rollback_v1') ||
          p.get(key) != _snapshot ||
          (guardXp && p.get(MentiXpStore.currentKey) != _xpSnapshot)) {
        ready = false;
        error = 'conflict';
        return false;
      }
      final raw = next.encode();
      if (_snapshot != raw && !await p.setString(key, raw)) {
        throw StateError('Unconfirmed collection write');
      }
      await p.reload();
      if (p.get(key) != raw) {
        ready = false;
        error = 'conflict';
        return false;
      }
      _snapshot = raw;
      selection = next;
      return true;
    } catch (_) {
      error = 'save';
      try {
        await p?.reload();
      } catch (_) {
        ready = false;
      }
      return false;
    } finally {
      saving = false;
      _writing = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
