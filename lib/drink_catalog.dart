import 'l10n/generated/app_localizations.dart';

class CatalogDrink {
  final String name;
  final String category;
  final String emoji;
  final int ml;
  final double percent;

  const CatalogDrink({
    required this.name,
    required this.category,
    required this.emoji,
    required this.ml,
    required this.percent,
  });
}

const List<CatalogDrink> drinkCatalog = [
  CatalogDrink(
    name: 'Sör (általános)',
    category: 'Sörök',
    emoji: '🍺',
    ml: 500,
    percent: 5,
  ),
  CatalogDrink(
    name: 'Világos sör',
    category: 'Sörök',
    emoji: '🍺',
    ml: 500,
    percent: 4.5,
  ),
  CatalogDrink(
    name: 'Barna sör',
    category: 'Sörök',
    emoji: '🍺',
    ml: 500,
    percent: 5,
  ),
  CatalogDrink(
    name: 'Fehérbor',
    category: 'Borok',
    emoji: '🍷',
    ml: 200,
    percent: 12,
  ),
  CatalogDrink(
    name: 'Vörösbor',
    category: 'Borok',
    emoji: '🍷',
    ml: 200,
    percent: 12,
  ),
  CatalogDrink(
    name: 'Rozé',
    category: 'Borok',
    emoji: '🍷',
    ml: 200,
    percent: 12,
  ),
  CatalogDrink(
    name: 'Kisfröccs',
    category: 'Fröccsök',
    emoji: '🍹',
    ml: 200,
    percent: 6,
  ),
  CatalogDrink(
    name: 'Nagyfröccs',
    category: 'Fröccsök',
    emoji: '🍹',
    ml: 300,
    percent: 8,
  ),
  CatalogDrink(
    name: 'Pálinka',
    category: 'Röviditalok',
    emoji: '🥃',
    ml: 50,
    percent: 50,
  ),
  CatalogDrink(
    name: 'Unicum (általános)',
    category: 'Röviditalok',
    emoji: '🥃',
    ml: 40,
    percent: 40,
  ),
  CatalogDrink(
    name: 'Vodka',
    category: 'Röviditalok',
    emoji: '🥃',
    ml: 40,
    percent: 40,
  ),
  CatalogDrink(
    name: 'Whisky',
    category: 'Röviditalok',
    emoji: '🥃',
    ml: 40,
    percent: 40,
  ),
];
/// Labels only: persisted journal names and favorite IDs never change.
String catalogDrinkLabel(String name, AppLocalizations s) => switch(name) {
  'Sör (általános)' => s.catalogBeer,
  'Világos sör' => s.catalogLager,
  'Barna sör' => s.catalogDarkBeer,
  'Fehérbor' => s.catalogWhiteWine,
  'Vörösbor' => s.catalogRedWine,
  'Rozé' => s.catalogRoseWine,
  'Kisfröccs' => s.catalogSmallSpritzer,
  'Nagyfröccs' => s.catalogLargeSpritzer,
  'Pálinka' => s.catalogPalinka,
  'Unicum (általános)' => s.catalogUnicum,
  _ => name,
};
