import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local age declaration, not verified identity or authentication. Unknown,
/// unreadable or incomplete declarations never authorize adult features.
class MentiAccessSettings extends ChangeNotifier {
  MentiAccessSettings({Future<SharedPreferences> Function()? open})
    : open = open ?? SharedPreferences.getInstance;
  static const key = 'mennyiment_access_v1';
  final Future<SharedPreferences> Function() open;
  bool ready = false, saving = false, failed = false, existing = false;
  bool complete = false, adult = false, writable = true;
  Object? _loaded;
  bool _disposed = false;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  static Map<String, dynamic> decode(Object value) {
    if (value is! String) {
      throw const FormatException('Invalid access declaration');
    }
    final data = jsonDecode(value);
    if (data is! Map<String, dynamic> ||
        data['version'] != 1 ||
        !['adult', 'minor'].contains(data['audience']) ||
        data['complete'] is! bool) {
      throw const FormatException('Invalid access declaration');
    }
    return data;
  }

  Future<void> load() async {
    ready = false;
    adult = false;
    complete = false;
    writable = true;
    _notify();
    try {
      final p = await open();
      await p.reload();
      _loaded = p.get(key);
      existing = p.getKeys().any(
        (k) =>
            k.startsWith('mennyiment_') &&
            !const {
              key,
              'mennyiment_locale_v1',
              'mennyiment_reduce_motion_v1',
              'mennyiment_reactions_enabled_v1',
              'mennyiment_intro_seen_v1',
            }.contains(k),
      );
      if (_loaded != null) {
        final d = decode(_loaded!);
        complete = d['complete'] as bool;
        adult = complete && d['audience'] == 'adult';
      }
      failed = false;
      ready = true;
    } catch (_) {
      adult = false;
      complete = false;
      failed = true;
      // Preserve malformed and future declarations; do not silently replace them.
      writable = _loaded == null;
      ready = true;
    }
    _notify();
  }

  Future<bool> finish({required bool isAdult}) async {
    if (!ready || saving || !writable || _disposed) return false;
    saving = true;
    failed = false;
    _notify();
    try {
      final p = await open();
      await p.reload();
      if (p.get(key) != _loaded) throw StateError('Concurrent access change');
      final data = <String, dynamic>{
        if (_loaded != null) ...decode(_loaded!),
        'version': 1,
        'audience': isAdult ? 'adult' : 'minor',
        'complete': true,
      };
      final encoded = jsonEncode(data);
      if (!await p.setString(key, encoded)) {
        throw StateError('Access write failed');
      }
      _loaded = encoded;
      complete = true;
      adult = isAdult;
      return true;
    } catch (_) {
      try {
        await (await open()).reload();
      } catch (_) {
        writable = false;
      }
      failed = true;
      return false;
    } finally {
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

class MentiAccessScope extends InheritedNotifier<MentiAccessSettings> {
  const MentiAccessScope({
    super.key,
    required MentiAccessSettings settings,
    required super.child,
  }) : super(notifier: settings);
  static MentiAccessSettings? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MentiAccessScope>()?.notifier;
  // Standalone legacy widgets retain their API; the production root always mounts
  // this scope before any routes or journal mutations become accessible.
  static bool adultOf(BuildContext context) {
    final settings = of(context);
    return settings == null ||
        (settings.ready && settings.complete && settings.adult);
  }
}
