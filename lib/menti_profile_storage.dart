import 'package:shared_preferences/shared_preferences.dart';

import 'menti_character_catalog.dart';

/// Keeps character families and Studio backgrounds independent.
/// The legacy value is retained, including unknown or invalid data.
class MentiProfileStorage {
  static const legacyStyleKey = 'mennyiment_menti_style_v1';
  static const characterStyleKey = 'mennyiment_character_style_v2';
  static const outfitKey = 'mennyiment_outfit_v2';
  static const studioBackgroundKey = 'mennyiment_studio_background_v2';

  static final characterStyles = List<String>.unmodifiable(
    MentiCharacterFamily.values.map((family) => family.label),
  );

  static bool _validBackground(Object? value) =>
      value is int && value >= 0 && value < 4;

  static bool _validCharacter(Object? value) =>
      MentiCharacterFamily.resolve(value) != null;

  static Future<void> migrate(SharedPreferences prefs) async {
    final legacy = prefs.get(legacyStyleKey);
    bool saved = true;
    if (_validBackground(legacy) && !prefs.containsKey(studioBackgroundKey)) {
      saved = await prefs.setInt(studioBackgroundKey, legacy as int);
    } else if (_validCharacter(legacy) &&
        !prefs.containsKey(characterStyleKey)) {
      saved = await prefs.setString(characterStyleKey, legacy as String);
    }
    if (!saved) {
      throw StateError('A Menti-profil migrációja nem sikerült.');
    }
  }

  static int studioBackground(SharedPreferences prefs) {
    final value = prefs.get(studioBackgroundKey);
    return _validBackground(value) ? value as int : 0;
  }

  static MentiCharacterFamily family(SharedPreferences prefs) =>
      MentiCharacterFamily.resolve(prefs.get(characterStyleKey)) ??
      MentiCharacterFamily.boy;

  static MentiOutfit outfit(SharedPreferences prefs) =>
      MentiOutfit.resolve(prefs.get(outfitKey)) ?? MentiOutfit.basic;

  static String assetPath(SharedPreferences prefs) =>
      family(prefs).assetFor(outfit(prefs));

  static String characterStyle(SharedPreferences prefs) {
    final value = prefs.get(characterStyleKey);
    return (MentiCharacterFamily.resolve(value) ?? MentiCharacterFamily.boy)
        .label;
  }
}
