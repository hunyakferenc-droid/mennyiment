import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Existing schema/key, confirmed writes only, unknown fields retained.
/// Never reads or grants XP, changes outfits, or infers alcohol-free days.
class PersonalGoalStore {
  PersonalGoalStore({Future<SharedPreferences> Function()? open})
      : open = open ?? SharedPreferences.getInstance;
  static const key = 'mennyiment_personal_goals_v1';
  final Future<SharedPreferences> Function() open;
  Map<String, dynamic> _data = {};
  String? _raw;
  bool writable = false;
  bool busy = false;

  int? get weeklyBudget => (_data['weeklyBudget'] as num?)?.toInt();
  int get reflectionGoal => (_data['reflectionGoal'] as num?)?.toInt() ?? 4;
  List<String> get reflectionDays =>
      List<String>.unmodifiable((_data['reflectionDays'] as List? ?? []).cast<String>());

  static void _validate(Map<String, dynamic> data) {
    final budget = data['weeklyBudget'];
    final goal = data['reflectionGoal'];
    bool whole(dynamic value) => value is num && value.isFinite &&
        value == value.roundToDouble();
    if (budget != null && (!whole(budget) || budget < 0 || budget > 100000000)) {
      throw const FormatException('Invalid personal budget');
    }
    if (goal != null && (!whole(goal) || goal < 1 || goal > 7)) {
      throw const FormatException('Invalid personal goal');
    }
    final days = data['reflectionDays'];
    if (days != null && (days is! List || !days.every((d) => d is String))) {
      throw const FormatException('Invalid personal check-ins');
    }
  }

  /// Pure read adapter shared by the hub and the existing store; no writes.
  static Map<String, dynamic> decodeDocument(Object? value) {
    if (value != null && value is! String) {
      throw const FormatException('Invalid personal goals document type');
    }
    final decoded = value == null ? <String, dynamic>{} : jsonDecode(value as String);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid personal goals document');
    }
    _validate(decoded);
    return decoded;
  }

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
    final prefs = await open();
    await prefs.reload();
    final value = prefs.get(key);
    final decoded = decodeDocument(value);
    _data = decoded;
    _raw = value as String?;
    writable = true;
  });

  Future<bool> update(Map<String, dynamic> changes) async {
    if (!writable || busy) return false;
    if (!changes.keys.every(['weeklyBudget', 'reflectionGoal', 'reflectionDays'].contains)) {
      throw ArgumentError('Only existing personal goal fields may be changed');
    }
    busy = true;
    return _serial(() async {
      SharedPreferences? prefs;
      try {
        prefs = await open();
        await prefs.reload();
        if (prefs.get(key) != _raw) {
          writable = false;
          return false;
        }
        final next = <String, dynamic>{..._data, ...changes};
        _validate(next);
        final encoded = jsonEncode(next);
        if (!await prefs.setString(key, encoded)) {
          debugPrint('Personal goals write was not confirmed');
          await prefs.reload();
          return false;
        }
        _raw = encoded;
        _data = jsonDecode(encoded) as Map<String, dynamic>;
        return true;
      } catch (error, stack) {
        debugPrint('Personal goals write failure: ${error.runtimeType}\n$stack');
        try {
          await prefs?.reload();
        } catch (_) {
          writable = false;
        }
        return false;
      } finally {
        busy = false;
      }
    });
  }
}
