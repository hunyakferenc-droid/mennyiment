import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

/// Export-only: embedded journal JSON is preserved as text, never migrated.
class BackupDocument {
  static const format = 'mennyiment.local-backup';
  static const version = 1;
  static const maxBytes = 16 * 1024 * 1024;
  final String json;
  final DateTime createdAt;
  final int entryCount;
  BackupDocument._(this.json, this.createdAt, this.entryCount);

  Uint8List get bytes => Uint8List.fromList(utf8.encode(json));
  String get fileName =>
      'mennyiment-backup-${createdAt.toIso8601String().replaceAll(RegExp(r'[:.\-]'), '')}.json';

  factory BackupDocument.decode(String text) {
    if (text.length > maxBytes || utf8.encode(text).length > maxBytes) {
      throw const FormatException('Backup too large');
    }
    final root = decodeBackupJson(text);
    if (root is! Map ||
        root.length != 4 ||
        root['format'] != format ||
        root['version'] is! int ||
        root['version'] != version ||
        root['createdAt'] is! String ||
        root['entries'] is! Map) {
      throw const FormatException('Unsupported backup structure');
    }
    final createdAt = DateTime.tryParse(root['createdAt'] as String);
    if (createdAt == null ||
        !createdAt.isUtc ||
        createdAt.toIso8601String() != root['createdAt']) {
      throw const FormatException('Invalid backup timestamp');
    }
    final entries = root['entries'] as Map;
    if (entries.length > 10000) { throw const FormatException('Too many entries'); }
    for (final entry in entries.entries) {
      if (entry.key is! String ||
          !ownedKey(entry.key as String) ||
          entry.value is! Map) {
        throw const FormatException('Invalid backup key');
      }
      final item = entry.value as Map;
      if (item.length != 2 || !item.containsKey('value')) {
        throw const FormatException('Invalid typed entry');
      }
      final value = item['value'];
      final valid = switch (item['type']) {
        'string' => value is String,
        'bool' => value is bool,
        'stringList' => value is List && value.every((v) => v is String),
        // Decimal strings preserve integer precision and double representations.
        'int' => value is String && int.tryParse(value)?.toString() == value,
        'double' =>
          value is String &&
              double.tryParse(value)?.isFinite == true &&
              double.parse(value).toString() == value,
        _ => false,
      };
      if (!valid) { throw const FormatException('Invalid typed value'); }
    }
    return BackupDocument._(text, createdAt, entries.length);
  }

  static bool ownedKey(String key) =>
      key.startsWith('mennyiment_') &&
      key.length > 'mennyiment_'.length &&
      key.length <= 256;
}

class BackupExporter {
  BackupExporter({
    Future<SharedPreferences> Function()? openPreferences,
    DateTime Function()? clock,
  }) : _openPreferences = openPreferences ?? SharedPreferences.getInstance,
       _clock = clock ?? DateTime.now;
  final Future<SharedPreferences> Function() _openPreferences;
  final DateTime Function() _clock;

  Map<String, Object> _snapshot(SharedPreferences prefs) {
    final keys =
        prefs.getKeys().where((k) => k.startsWith('mennyiment_')).toList()
          ..sort();
    final entries = <String, Object>{};
    for (final key in keys) {
      if (!BackupDocument.ownedKey(key)) {
        throw const FormatException('Unsupported key');
      }
      final value = prefs.get(key);
      final type = switch (value) {
        String() => 'string',
        bool() => 'bool',
        int() => 'int',
        double() when value.isFinite => 'double',
        List<String>() => 'stringList',
        _ => throw const FormatException('Unsupported local value'),
      };
      entries[key] = {
        'type': type,
        'value': value is num
            ? value.toString()
            : value is List<String>
            ? List<String>.of(value)
            : value!,
      };
    }
    return entries;
  }

  Future<BackupDocument> capture() async {
    final prefs = await _openPreferences();
    await prefs.reload();
    final first = jsonEncode(_snapshot(prefs));
    await prefs.reload();
    final second = jsonEncode(_snapshot(prefs));
    if (first != second) { throw StateError('Local data changed while exporting'); }
    final result = jsonEncode({
      'format': BackupDocument.format,
      'version': BackupDocument.version,
      'createdAt': _clock().toUtc().toIso8601String(),
      'entries': jsonDecode(second),
    });
    // Validate our own output before it can reach the file picker.
    return BackupDocument.decode(result);
  }
}

/// Reject ambiguous duplicate keys (including escaped equivalents) and excessive
/// nesting before decoding. Used for both the envelope and embedded documents.
Object? decodeBackupJson(String text) {
  final containers = <Set<String>?>[];
  for (var i = 0; i < text.length; i++) {
    final char = text[i];
    if (char == '{' || char == '[') {
      containers.add(char == '{' ? <String>{} : null);
      if (containers.length > 128) { throw const FormatException('JSON too deep'); }
    } else if (char == '}' || char == ']') {
      if (containers.isNotEmpty) { containers.removeLast(); }
    } else if (char == '"') {
      final start = i;
      i++;
      while (i < text.length) {
        if (text.codeUnitAt(i) == 92) { i += 2; continue; }
        if (text[i] == '"') { break; }
        i++;
      }
      if (i >= text.length) { throw const FormatException('Unterminated string'); }
      var next = i + 1;
      while (next < text.length && text.codeUnitAt(next) <= 32) { next++; }
      if (next < text.length && text[next] == ':' && containers.isNotEmpty &&
          containers.last != null) {
        final key = jsonDecode(text.substring(start, i + 1)) as String;
        if (!containers.last!.add(key)) { throw const FormatException('Duplicate JSON key'); }
      }
    }
  }
  return jsonDecode(text);
}
