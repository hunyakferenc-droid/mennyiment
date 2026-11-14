import 'dart:convert';

import 'package:flutter/material.dart';

import 'app_language.dart';
import 'data_backup.dart';

part 'menti_collection_catalog.dart';

class CompleteLook {
  const CompleteLook(
    this.id,
    this.family,
    this.asset,
    this.sourceSize,
    this.bounds, {
    this.style = 'base',
    this.minXp = 0,
    this.reference = '',
    this.thumbnail,
  });
  final String id, family, asset, style, reference;
  final Size sourceSize;
  final Rect bounds;
  final int minXp;
  final String? thumbnail;
  String get unlock => minXp == 0 ? 'free' : 'xp:$minXp';
  String name(BuildContext context) {
    final s = appStrings(context);
    if (style == 'base') {
      return switch (family) {
        'boy' => s.completeBoy,
        'girl' => s.completeGirl,
        _ => s.completeNeutral,
      };
    }
    final familyName = switch (family) {
      'boy' => s.collectionBoy,
      'girl' => s.collectionGirl,
      _ => s.collectionNeutral,
    };
    final styleName = switch (style) {
      'party' => s.collectionParty,
      'festival' => s.collectionFestival,
      'sport' => s.collectionSport,
      'business' => s.collectionBusiness,
      _ => s.collectionLegendary,
    };
    return s.collectionLookName(familyName, styleName);
  }

  static const all = collectionLooks;
  static CompleteLook? find(String? id, {List<CompleteLook> catalog = all}) {
    for (final look in catalog) {
      if (look.id == id) return look;
    }
    return null;
  }
}

/// Same preference key, schema 2. V1 reads never write or convert a profile.
/// Unknown fields/owned IDs survive edits; unknown versions/selections are locked.
class CompleteLookSelection {
  const CompleteLookSelection({
    this.active = false,
    this.lookId = 'boy-base-v1',
    this.acquired = const {},
    this.announced = const {},
    this.extras = const {},
    this.sourceVersion = 2,
  });
  final bool active;
  final String lookId;
  final Set<String> acquired, announced;
  final Map<String, dynamic> extras;
  final int sourceVersion;
  CompleteLookSelection copyWith({
    bool? active,
    String? lookId,
    Set<String>? acquired,
    Set<String>? announced,
    Map<String, dynamic>? extras,
  }) => CompleteLookSelection(
    active: active ?? this.active,
    lookId: lookId ?? this.lookId,
    acquired: Set.unmodifiable(acquired ?? this.acquired),
    announced: Set.unmodifiable(announced ?? this.announced),
    extras: Map.unmodifiable(extras ?? this.extras),
  );
  String encode() => jsonEncode({
    ...extras,
    'version': 2,
    'active': active,
    'look': lookId,
    'acquired': acquired.toList()..sort(),
    'announced': announced.toList()..sort(),
  });
  bool owns(CompleteLook look) => look.minXp == 0 || acquired.contains(look.id);
  static CompleteLookSelection decode(
    Object? raw, {
    List<CompleteLook> catalog = CompleteLook.all,
  }) {
    if (raw == null) return const CompleteLookSelection();
    if (raw is! String) {
      throw const FormatException('Invalid complete look type');
    }
    final data = decodeBackupJson(raw);
    if (data is! Map<String, dynamic> ||
        data['version'] is! int ||
        ![1, 2].contains(data['version']) ||
        data['active'] is! bool ||
        data['look'] is! String) {
      throw const FormatException('Unsupported complete look');
    }
    if (data['version'] == 1 &&
        (data.containsKey('acquired') || data.containsKey('announced'))) {
      throw const FormatException('Ambiguous v1 extension fields');
    }
    final look = CompleteLook.find(data['look'] as String, catalog: catalog);
    if (look == null) throw const FormatException('Unknown selected look');
    Set<String> ids(String field) {
      final value = data[field];
      if (value == null && data['version'] == 1) return {};
      if (value is! List ||
          value.length > 2500 ||
          value.any((id) => id is! String || id.isEmpty || id.length > 120)) {
        throw const FormatException('Invalid acquired looks');
      }
      return Set<String>.unmodifiable(value.cast<String>());
    }

    final acquired = data['version'] == 1 ? <String>{} : ids('acquired');
    final announced = data['version'] == 1 ? <String>{} : ids('announced');
    if (data['active'] == true &&
        look.minXp > 0 &&
        !acquired.contains(look.id)) {
      throw const FormatException('Locked selected look');
    }
    return CompleteLookSelection(
      active: data['active'] as bool,
      lookId: look.id,
      acquired: acquired,
      announced: announced,
      sourceVersion: data['version'] as int,
      extras: Map.unmodifiable({
        for (final e in data.entries)
          if (!const {
            'version',
            'active',
            'look',
            'acquired',
            'announced',
          }.contains(e.key))
            e.key: e.value,
      }),
    );
  }

  /// Restore follows the existing permanent-reward union rule. Appearance comes
  /// from the incoming backup; current durable unlocks and unknown fields survive.
  static CompleteLookSelection restored(
    CompleteLookSelection current,
    CompleteLookSelection incoming,
  ) => incoming.copyWith(
    acquired: {...current.acquired, ...incoming.acquired},
    announced: {...current.announced, ...incoming.announced},
    extras: {...current.extras, ...incoming.extras},
  );
}
