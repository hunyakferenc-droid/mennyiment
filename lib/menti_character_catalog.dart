/// Stable identifiers and existing artwork for the Menti character families.
/// Enum order matches the existing selector and wardrobe order.
enum MentiCharacterFamily {
  boy('boy', 'Fiú Menti', 'fiu', 'assets/images/menti_outfits'),
  girl('girl', 'Lány Menti', 'lany', 'assets/images/menti_outfits_642/lany'),
  neutral(
    'neutral',
    'Semleges Menti',
    'semleges',
    'assets/images/menti_outfits_642/semleges',
  );

  const MentiCharacterFamily(
    this.id,
    this.label,
    this.file,
    this.outfitDirectory,
  );
  final String id;
  final String label;
  final String file;
  final String outfitDirectory;

  String get selectorAsset => 'assets/images/menti_characters/$file.png';
  String assetFor(MentiOutfit outfit) => '$outfitDirectory/${outfit.file}';

  /// Unknown values are not guessed or written back to storage.
  static MentiCharacterFamily? resolve(Object? value) {
    for (final family in values) {
      if (value == family.id || value == family.label) return family;
    }
    return null;
  }
}

enum MentiOutfit {
  basic('basic', 'Alap szett', 'Kezdő stílus', 'alap.png', 1),
  party('party', 'Buli szett', 'Vidám hangulat', 'buli.png', 1),
  sport('sport', 'Sport szett', 'Aktív napok', 'sport.png', 1),
  business('business', 'Üzleti szett', 'Elegáns', 'uzleti.png', 2),
  festival('festival', 'Fesztivál szett', 'Színes stílus', 'fesztival.png', 3),
  legendary('legendary', 'Legendás szett', 'Prémium stílus', 'legendas.png', 5);

  const MentiOutfit(
    this.id,
    this.label,
    this.subtitle,
    this.file,
    this.requiredLevel,
  );
  final String id;
  final String label;
  final String subtitle;
  final String file;
  final int requiredLevel;

  static MentiOutfit? resolve(Object? value) {
    for (final outfit in values) {
      if (value == outfit.id || value == outfit.label) return outfit;
    }
    return null;
  }
}
