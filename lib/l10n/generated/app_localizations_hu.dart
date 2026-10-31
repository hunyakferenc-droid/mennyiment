// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AppLocalizationsHu extends AppLocalizations {
  AppLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get appTitle => 'MennyiMent?';

  @override
  String get home => 'Kezdőlap';

  @override
  String get journal => 'Napló';

  @override
  String get insights => 'Elemzés';

  @override
  String get menti => 'Menti';

  @override
  String get profile => 'Menti és profil';

  @override
  String get language => 'Nyelv / Language';

  @override
  String get automatic => 'Automatikus';

  @override
  String get hungarian => 'Magyar';

  @override
  String get english => 'English';

  @override
  String get languageError => 'A nyelvbeállítás mentése nem sikerült.';

  @override
  String get statistics => '📊 Statisztikák';

  @override
  String get week => 'Hét';

  @override
  String get month => 'Hónap';

  @override
  String get year => 'Év';

  @override
  String get previousPeriod => 'Előző időszak';

  @override
  String get nextPeriod => 'Következő időszak';

  @override
  String get drinks => 'Italok';

  @override
  String get pureAlcohol => 'Tiszta alkohol';

  @override
  String get drinkVolume => 'Italmennyiség';

  @override
  String get unloggedDays => 'Rögzítés nélküli napok';

  @override
  String get knownSpending => 'Ismert költés';

  @override
  String get noSpendingData =>
      'Nincs rögzített ital: költésadat még nem áll rendelkezésre.';

  @override
  String get completePrices =>
      'Minden rögzített italhoz tartozik ár az időszakban.';

  @override
  String partialPrices(int count) {
    return 'Részösszeg: $count ital ára hiányzik vagy érvénytelen. A hiányzó ár nem 0 Ft.';
  }

  @override
  String get alcoholByPeriod => 'Alkoholmennyiség időszakonként (g)';

  @override
  String get frequentDrinks => 'Leggyakoribb italok';

  @override
  String get noDrinks => 'Ebben az időszakban nincs rögzített ital.';

  @override
  String get drinkingTimes => 'Fogyasztási időpontok';

  @override
  String get noPeriodData => 'Nincs adat az időszakban.';

  @override
  String peakTime(String start, String end, int count) {
    return 'Legtöbb rögzítés: $start–$end között ($count db).';
  }

  @override
  String get statisticsCaution =>
      'Az összesítések kizárólag a rögzített italokból készülnek. A „rögzítés nélküli nap” nem bizonyítottan alkoholmentes nap. Az adatok nem használhatók józanság vagy vezetési alkalmasság megállapítására.';

  @override
  String drinkCount(int count) {
    return '$count db';
  }

  @override
  String dayCount(int count) {
    return '$count nap';
  }

  @override
  String grams(String value) {
    return '$value g';
  }

  @override
  String litres(String value) {
    return '$value l';
  }

  @override
  String get chooseMenti => 'Saját Menti kiválasztása';

  @override
  String get mentiProgress => 'Menti fejlődése';

  @override
  String get addDrink => 'ITAL NAPLÓZÁSA';

  @override
  String get explore => 'Felfedezés';

  @override
  String get financeCenter => 'Pénzügyi központ – részletes kimutatás';

  @override
  String get wellbeing => 'Közérzet';

  @override
  String get wellbeingHint => 'Hangulat, alvás és másnap';

  @override
  String get savings => 'Megtakarítás';

  @override
  String get savingsHint => 'Autó, nyaralás, saját cél';

  @override
  String get weeklyInsights => 'Heti elemzés';

  @override
  String get weeklyInsightsHint => 'Összefüggések és trendek';

  @override
  String get mentiProgressHint => 'Szintek és kihívások';

  @override
  String get goals => 'Célok';

  @override
  String get goalsHint => 'Keret és naptár';

  @override
  String get statisticsHint => 'Naplózott fogyasztás';

  @override
  String get personalGoals => 'Személyes heti céljaim • önellenőrzés';

  @override
  String get weeklyReport => 'Heti Menti-jelentés • közérzet és költés';

  @override
  String get allEntries => 'Összes';

  @override
  String get statisticsNav => 'Statisztikák';

  @override
  String get recentEntries => 'Legutóbbi bejegyzések';
}
