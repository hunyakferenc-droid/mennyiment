import 'dart:convert';

import '../data_backup.dart';
import '../menti_character_catalog.dart';
import '../menti_profile_storage.dart';

/// Stable identifiers. Unknown future identifiers survive every round trip.
class MentiVisualProfile {
  MentiVisualProfile([Map<String, dynamic> values = const {}])
      : _json = _immutable(values);
  final Map<String, dynamic> _json;
  static const defaults = <String, String>{
    'family': 'boy', 'age': 'young', 'style': 'classic',
    'face': 'cheerful', 'eyes': 'round', 'hair': 'boy-crop',
    'headwear': 'crown-cap', 'outfit': 'basic', 'glasses': 'none',
    'neck': 'none', 'held': 'none', 'detail': 'none', 'back': 'none',
    'aura': 'sunrise', 'accent': 'gold', 'background': 'amber',
  };
  String value(String field) => _json[field] as String? ?? defaults[field]!;
  Map<String, dynamic> toJson() => _copy(_json);
  MentiVisualProfile withValues(Map<String, String> values) {
    if (!values.keys.every(defaults.containsKey)) {
      throw ArgumentError('Unknown visual field');
    }
    return MentiVisualProfile({...toJson(), ...values});
  }
  factory MentiVisualProfile.fromJson(Object? value) {
    final data = _object(value, 'visual');
    for (final key in defaults.keys) {
      if (data.containsKey(key) && (data[key] is! String ||
          (data[key] as String).isEmpty || (data[key] as String).length > 128)) {
        throw FormatException('Invalid visual $key');
      }
    }
    return MentiVisualProfile(data);
  }
}

class MentiReactionProfile {
  MentiReactionProfile([Map<String, dynamic> values = const {}])
      : _json = _immutable(values);
  final Map<String, dynamic> _json;
  String get style => _json['style'] as String? ?? 'motivating';
  Map<String, dynamic> toJson() => _copy(_json);
  factory MentiReactionProfile.fromJson(Object? value) {
    final data = _object(value, 'reaction');
    if (data.containsKey('style') && (data['style'] is! String ||
        (data['style'] as String).isEmpty || (data['style'] as String).length > 128)) {
      throw const FormatException('Invalid reaction style');
    }
    return MentiReactionProfile(data);
  }
}

class MentiIdentityProfile {
  MentiIdentityProfile({String name = 'Menti', MentiVisualProfile? visual,
    MentiReactionProfile? reaction, Map<String, dynamic> extras = const {}})
      : _json = _immutable({...extras, 'name': name,
          'visual': (visual ?? MentiVisualProfile()).toJson(),
          'reaction': (reaction ?? MentiReactionProfile()).toJson()});
  MentiIdentityProfile._(this._json);
  final Map<String, dynamic> _json;
  String get name => _json['name'] as String? ?? 'Menti';
  MentiVisualProfile get visual => MentiVisualProfile.fromJson(_json['visual']);
  MentiReactionProfile get reaction => MentiReactionProfile.fromJson(_json['reaction']);
  Map<String, dynamic> toJson() => _copy(_json);
  MentiIdentityProfile copyWith({String? name, MentiVisualProfile? visual,
      MentiReactionProfile? reaction}) => MentiIdentityProfile(
    name: name ?? this.name, visual: visual ?? this.visual,
    reaction: reaction ?? this.reaction, extras: toJson());
  factory MentiIdentityProfile.fromJson(Object? value) {
    final data = _object(value, 'profile');
    if (data.containsKey('name') && (data['name'] is! String ||
        (data['name'] as String).trim().isEmpty || (data['name'] as String).length > 80)) {
      throw const FormatException('Invalid identity name');
    }
    MentiVisualProfile.fromJson(data['visual']);
    MentiReactionProfile.fromJson(data['reaction']);
    return MentiIdentityProfile._(_immutable(data));
  }
}

/// Permanent cosmetics only. No XP is awarded or removed by this model.
class MentiUnlockState {
  MentiUnlockState({Iterable<String> unlocked = const [],
    Iterable<String> seen = const [], Map<String, dynamic> extras = const {}})
      : _json = _immutable({...extras, 'unlocked': unlocked.toSet().toList()..sort(),
          'seen': seen.toSet().toList()..sort()});
  final Map<String, dynamic> _json;
  Set<String> get unlocked => Set.unmodifiable((_json['unlocked'] as List).cast<String>());
  Set<String> get seen => Set.unmodifiable((_json['seen'] as List).cast<String>());
  Set<String> get newlyAcquired => Set.unmodifiable(unlocked.difference(seen));
  MentiUnlockState grant(Iterable<String> ids) => MentiUnlockState(
    unlocked: {...unlocked, ...ids}, seen: seen, extras: toJson());
  MentiUnlockState acknowledge(Iterable<String> ids) => MentiUnlockState(
    unlocked: unlocked, seen: {...seen, ...ids.where(unlocked.contains)}, extras: toJson());
  Map<String, dynamic> toJson() => _copy(_json);
  factory MentiUnlockState.fromJson(Object? value) {
    final data = _object(value, 'unlocks');
    return MentiUnlockState(unlocked: _strings(data['unlocked']),
      seen: _strings(data['seen']), extras: data);
  }
}

class MentiPreset {
  MentiPreset({required this.id, required this.name, required this.profile,
      this.favorite = false, Map<String, dynamic> extras = const {}})
      : _extras = _immutable(extras);
  final String id;
  final String name;
  final MentiIdentityProfile profile;
  final bool favorite;
  final Map<String, dynamic> _extras;
  Map<String, dynamic> toJson() => {..._copy(_extras), 'id': id, 'name': name,
    'profile': profile.toJson(), 'favorite': favorite};
  MentiPreset copyWith({String? id, String? name, bool? favorite}) => MentiPreset(
    id: id ?? this.id, name: name ?? this.name, profile: profile,
    favorite: favorite ?? this.favorite, extras: _extras);
  factory MentiPreset.fromJson(Object? value) {
    final data = _object(value, 'preset');
    for (final key in ['id', 'name']) {
      if (data[key] is! String || (data[key] as String).trim().isEmpty ||
          (data[key] as String).length > 80) {
        throw const FormatException('Invalid preset identity');
      }
    }
    if (data['profile'] is! Map || (data['favorite'] != null && data['favorite'] is! bool)) {
      throw const FormatException('Invalid preset favorite');
    }
    return MentiPreset(id: data['id'] as String, name: data['name'] as String,
      profile: MentiIdentityProfile.fromJson(data['profile']),
      favorite: data['favorite'] as bool? ?? false, extras: data);
  }
}

/// One atomic preference value: profile, presets and permanent unlocks together.
class MentiIdentityDocument {
  MentiIdentityDocument({required this.profile, MentiUnlockState? unlocks,
      List<MentiPreset> presets = const [], Map<String, dynamic> extras = const {}})
      : unlocks = unlocks ?? MentiUnlockState(),
        presets = List.unmodifiable(presets), _extras = _immutable(extras);
  final MentiIdentityProfile profile;
  final MentiUnlockState unlocks;
  final List<MentiPreset> presets;
  final Map<String, dynamic> _extras;
  Map<String, dynamic> toJson() => {..._copy(_extras), 'version': 1,
    'profile': profile.toJson(), 'unlocks': unlocks.toJson(),
    'presets': presets.map((p) => p.toJson()).toList()};
  String encode() => jsonEncode(toJson());
  MentiIdentityDocument copyWith({MentiIdentityProfile? profile,
      MentiUnlockState? unlocks, List<MentiPreset>? presets}) => MentiIdentityDocument(
    profile: profile ?? this.profile, unlocks: unlocks ?? this.unlocks,
    presets: presets ?? this.presets, extras: _extras);
  factory MentiIdentityDocument.decode(Object? raw) {
    if (raw is! String || raw.length > 1024 * 1024) {
      throw const FormatException('Invalid identity document type/size');
    }
    final data = _object(decodeBackupJson(raw), 'identity');
    if (data['version'] is! int || data['version'] != 1 || data['profile'] is! Map) {
      throw const FormatException('Unsupported identity schema');
    }
    final items = data['presets'] ?? [];
    if (items is! List || items.length > 100) {
      throw const FormatException('Invalid presets');
    }
    final presets = items.map(MentiPreset.fromJson).toList();
    if (presets.map((p) => p.id).toSet().length != presets.length) {
      throw const FormatException('Duplicate preset ID');
    }
    return MentiIdentityDocument(profile: MentiIdentityProfile.fromJson(data['profile']),
      unlocks: MentiUnlockState.fromJson(data['unlocks']), presets: presets, extras: data);
  }

  /// Read-only conversion. Retains the exact original values, including unknowns.
  /// New documents always take precedence; callers must not migrate over them.
  factory MentiIdentityDocument.fromLegacy(Map<String, Object?> values) {
    final family = MentiCharacterFamily.resolve(values[MentiProfileStorage.characterStyleKey]) ??
      MentiCharacterFamily.resolve(values[MentiProfileStorage.legacyStyleKey]) ?? MentiCharacterFamily.boy;
    final outfit = MentiOutfit.resolve(values[MentiProfileStorage.outfitKey]) ?? MentiOutfit.basic;
    final appearance = values['mennyiment_menti_age_style_v1'];
    final age = switch (appearance) {
      'Fiatalos' => 'young', 'Felnőttes' => 'adult', 'Veterán' => 'veteran',
      _ => switch (values['mennyiment_age_group_v1']) {
        '35–44' => 'adult', '45+' => 'veteran', _ => 'young',
      },
    };
    final aura = switch (values['mennyiment_menti_aura_v1']) {
      'Lila' => 'violet', 'Kék' => 'ocean', 'Zöld' => 'forest',
      'Arany' => 'starlight', 'Rózsaszín' => 'rose', _ => 'sunrise',
    };
    final bg = values[MentiProfileStorage.studioBackgroundKey] ?? values[MentiProfileStorage.legacyStyleKey];
    final background = switch (bg) { 1 => 'violet', 2 => 'ocean', 3 => 'forest', _ => 'amber' };
    final tint = switch (values['mennyiment_character_color_v2']) {
      'Lila' => 'violet', 'Kék' => 'blue', 'Zöld' => 'mint',
      'Rózsaszín' => 'rose', 'Narancs' => 'orange', _ => 'gold',
    };
    final accessory = values['mennyiment_menti_accessory_v1'];
    final rawName = values['mennyiment_character_name_v1'];
    final name = rawName is String && rawName.trim().isNotEmpty && rawName.length <= 80 ? rawName : 'Menti';
    final savedRewards = values['mennyiment_menti_rewards_v1'];
    final rewards = savedRewards is List && savedRewards.every((v) => v is String)
      ? savedRewards.cast<String>() : <String>[];
    return MentiIdentityDocument(profile: MentiIdentityProfile(name: name,
      visual: MentiVisualProfile({
        'family': family.id, 'age': age, 'hair': '${family.id}-crop',
        'outfit': outfit.id, 'style': switch (outfit) {
          MentiOutfit.sport => 'sporty', MentiOutfit.basic => 'classic', _ => outfit.id,
        },
        'aura': aura, 'background': background, 'accent': tint,
        if (accessory == 'Napszemüveg') 'glasses': 'sunglasses',
        if (accessory == 'Korona') 'headwear': 'party-crown',
        if (accessory == 'Bulikalap') 'headwear': 'party-hat',
        if (accessory == 'Csillag') 'detail': 'star',
      })), unlocks: MentiUnlockState(unlocked: {...rewards, 'outfit:${outfit.id}'}),
      extras: {'migration': {'source': 'legacy', 'original': values}});
  }
}

Map<String, dynamic> _object(Object? value, String label) {
  if (value == null) return {};
  if (value is! Map<String, dynamic>) { throw FormatException('Invalid $label'); }
  return value;
}
List<String> _strings(Object? value) {
  if (value == null) return [];
  if (value is! List || !value.every((v) => v is String)) {
    throw const FormatException('Invalid identity string list');
  }
  return value.cast<String>();
}
Map<String, dynamic> _copy(Map<String, dynamic> value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
Map<String, dynamic> _immutable(Map<String, dynamic> value) => Map.unmodifiable(_copy(value));
