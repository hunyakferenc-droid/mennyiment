import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hu.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hu'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In hu, this message translates to:
  /// **'MennyiMent?'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In hu, this message translates to:
  /// **'Kezdőlap'**
  String get home;

  /// No description provided for @journal.
  ///
  /// In hu, this message translates to:
  /// **'Napló'**
  String get journal;

  /// No description provided for @insights.
  ///
  /// In hu, this message translates to:
  /// **'Elemzés'**
  String get insights;

  /// No description provided for @menti.
  ///
  /// In hu, this message translates to:
  /// **'Menti'**
  String get menti;

  /// No description provided for @profile.
  ///
  /// In hu, this message translates to:
  /// **'Menti és profil'**
  String get profile;

  /// No description provided for @language.
  ///
  /// In hu, this message translates to:
  /// **'Nyelv / Language'**
  String get language;

  /// No description provided for @automatic.
  ///
  /// In hu, this message translates to:
  /// **'Automatikus'**
  String get automatic;

  /// No description provided for @hungarian.
  ///
  /// In hu, this message translates to:
  /// **'Magyar'**
  String get hungarian;

  /// No description provided for @english.
  ///
  /// In hu, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @languageError.
  ///
  /// In hu, this message translates to:
  /// **'A nyelvbeállítás mentése nem sikerült.'**
  String get languageError;

  /// No description provided for @statistics.
  ///
  /// In hu, this message translates to:
  /// **'📊 Statisztikák'**
  String get statistics;

  /// No description provided for @week.
  ///
  /// In hu, this message translates to:
  /// **'Hét'**
  String get week;

  /// No description provided for @month.
  ///
  /// In hu, this message translates to:
  /// **'Hónap'**
  String get month;

  /// No description provided for @year.
  ///
  /// In hu, this message translates to:
  /// **'Év'**
  String get year;

  /// No description provided for @previousPeriod.
  ///
  /// In hu, this message translates to:
  /// **'Előző időszak'**
  String get previousPeriod;

  /// No description provided for @nextPeriod.
  ///
  /// In hu, this message translates to:
  /// **'Következő időszak'**
  String get nextPeriod;

  /// No description provided for @drinks.
  ///
  /// In hu, this message translates to:
  /// **'Italok'**
  String get drinks;

  /// No description provided for @pureAlcohol.
  ///
  /// In hu, this message translates to:
  /// **'Tiszta alkohol'**
  String get pureAlcohol;

  /// No description provided for @drinkVolume.
  ///
  /// In hu, this message translates to:
  /// **'Italmennyiség'**
  String get drinkVolume;

  /// No description provided for @unloggedDays.
  ///
  /// In hu, this message translates to:
  /// **'Rögzítés nélküli napok'**
  String get unloggedDays;

  /// No description provided for @knownSpending.
  ///
  /// In hu, this message translates to:
  /// **'Ismert költés'**
  String get knownSpending;

  /// No description provided for @noSpendingData.
  ///
  /// In hu, this message translates to:
  /// **'Nincs rögzített ital: költésadat még nem áll rendelkezésre.'**
  String get noSpendingData;

  /// No description provided for @completePrices.
  ///
  /// In hu, this message translates to:
  /// **'Minden rögzített italhoz tartozik ár az időszakban.'**
  String get completePrices;

  /// No description provided for @partialPrices.
  ///
  /// In hu, this message translates to:
  /// **'Részösszeg: {count} ital ára hiányzik vagy érvénytelen. A hiányzó ár nem 0 Ft.'**
  String partialPrices(int count);

  /// No description provided for @alcoholByPeriod.
  ///
  /// In hu, this message translates to:
  /// **'Alkoholmennyiség időszakonként (g)'**
  String get alcoholByPeriod;

  /// No description provided for @frequentDrinks.
  ///
  /// In hu, this message translates to:
  /// **'Leggyakoribb italok'**
  String get frequentDrinks;

  /// No description provided for @noDrinks.
  ///
  /// In hu, this message translates to:
  /// **'Ebben az időszakban nincs rögzített ital.'**
  String get noDrinks;

  /// No description provided for @drinkingTimes.
  ///
  /// In hu, this message translates to:
  /// **'Fogyasztási időpontok'**
  String get drinkingTimes;

  /// No description provided for @noPeriodData.
  ///
  /// In hu, this message translates to:
  /// **'Nincs adat az időszakban.'**
  String get noPeriodData;

  /// No description provided for @peakTime.
  ///
  /// In hu, this message translates to:
  /// **'Legtöbb rögzítés: {start}–{end} között ({count} db).'**
  String peakTime(String start, String end, int count);

  /// No description provided for @statisticsCaution.
  ///
  /// In hu, this message translates to:
  /// **'Az összesítések kizárólag a rögzített italokból készülnek. A „rögzítés nélküli nap” nem bizonyítottan alkoholmentes nap. Az adatok nem használhatók józanság vagy vezetési alkalmasság megállapítására.'**
  String get statisticsCaution;

  /// No description provided for @drinkCount.
  ///
  /// In hu, this message translates to:
  /// **'{count} db'**
  String drinkCount(int count);

  /// No description provided for @dayCount.
  ///
  /// In hu, this message translates to:
  /// **'{count} nap'**
  String dayCount(int count);

  /// No description provided for @grams.
  ///
  /// In hu, this message translates to:
  /// **'{value} g'**
  String grams(String value);

  /// No description provided for @litres.
  ///
  /// In hu, this message translates to:
  /// **'{value} l'**
  String litres(String value);

  /// No description provided for @chooseMenti.
  ///
  /// In hu, this message translates to:
  /// **'Saját Menti kiválasztása'**
  String get chooseMenti;

  /// No description provided for @mentiProgress.
  ///
  /// In hu, this message translates to:
  /// **'Menti fejlődése'**
  String get mentiProgress;

  /// No description provided for @addDrink.
  ///
  /// In hu, this message translates to:
  /// **'ITAL NAPLÓZÁSA'**
  String get addDrink;

  /// No description provided for @explore.
  ///
  /// In hu, this message translates to:
  /// **'Felfedezés'**
  String get explore;

  /// No description provided for @financeCenter.
  ///
  /// In hu, this message translates to:
  /// **'Pénzügyi központ – részletes kimutatás'**
  String get financeCenter;

  /// No description provided for @wellbeing.
  ///
  /// In hu, this message translates to:
  /// **'Közérzet'**
  String get wellbeing;

  /// No description provided for @wellbeingHint.
  ///
  /// In hu, this message translates to:
  /// **'Hangulat, alvás és másnap'**
  String get wellbeingHint;

  /// No description provided for @savings.
  ///
  /// In hu, this message translates to:
  /// **'Megtakarítás'**
  String get savings;

  /// No description provided for @savingsHint.
  ///
  /// In hu, this message translates to:
  /// **'Autó, nyaralás, saját cél'**
  String get savingsHint;

  /// No description provided for @weeklyInsights.
  ///
  /// In hu, this message translates to:
  /// **'Heti elemzés'**
  String get weeklyInsights;

  /// No description provided for @weeklyInsightsHint.
  ///
  /// In hu, this message translates to:
  /// **'Összefüggések és trendek'**
  String get weeklyInsightsHint;

  /// No description provided for @mentiProgressHint.
  ///
  /// In hu, this message translates to:
  /// **'Szintek és kihívások'**
  String get mentiProgressHint;

  /// No description provided for @goals.
  ///
  /// In hu, this message translates to:
  /// **'Célok'**
  String get goals;

  /// No description provided for @goalsHint.
  ///
  /// In hu, this message translates to:
  /// **'Keret és naptár'**
  String get goalsHint;

  /// No description provided for @statisticsHint.
  ///
  /// In hu, this message translates to:
  /// **'Naplózott fogyasztás'**
  String get statisticsHint;

  /// No description provided for @personalGoals.
  ///
  /// In hu, this message translates to:
  /// **'Személyes heti céljaim • önellenőrzés'**
  String get personalGoals;

  /// No description provided for @weeklyReport.
  ///
  /// In hu, this message translates to:
  /// **'Heti Menti-jelentés • közérzet és költés'**
  String get weeklyReport;

  /// No description provided for @allEntries.
  ///
  /// In hu, this message translates to:
  /// **'Összes'**
  String get allEntries;

  /// No description provided for @statisticsNav.
  ///
  /// In hu, this message translates to:
  /// **'Statisztikák'**
  String get statisticsNav;

  /// No description provided for @recentEntries.
  ///
  /// In hu, this message translates to:
  /// **'Legutóbbi bejegyzések'**
  String get recentEntries;

  /// No description provided for @backupTitle.
  ///
  /// In hu, this message translates to:
  /// **'Biztonsági mentés'**
  String get backupTitle;

  /// No description provided for @backupContents.
  ///
  /// In hu, this message translates to:
  /// **'A mentés az alkalmazás helyi naplóit, karakterprofilját, ruhaválasztását, XP-adatait, céljait és beállításait tartalmazza.'**
  String get backupContents;

  /// No description provided for @backupPrivacy.
  ///
  /// In hu, this message translates to:
  /// **'A fájl nincs titkosítva, személyes adatokat tartalmaz. Csak biztonságos helyre mentsd. Az alkalmazás nem küldi automatikusan hálózatra; a fájl helyéről és megosztásáról te döntesz.'**
  String get backupPrivacy;

  /// No description provided for @backupRestoreDeferred.
  ///
  /// In hu, this message translates to:
  /// **'Ez a verzió exportálást támogat. A visszaállítás még nem érhető el; meglévő adatot nem ír felül.'**
  String get backupRestoreDeferred;

  /// No description provided for @backupPrepare.
  ///
  /// In hu, this message translates to:
  /// **'Mentés előkészítése'**
  String get backupPrepare;

  /// No description provided for @backupWorking.
  ///
  /// In hu, this message translates to:
  /// **'Folyamatban…'**
  String get backupWorking;

  /// No description provided for @backupPreview.
  ///
  /// In hu, this message translates to:
  /// **'Előkészített mentés'**
  String get backupPreview;

  /// No description provided for @backupCreated.
  ///
  /// In hu, this message translates to:
  /// **'Készült: {date}'**
  String backupCreated(String date);

  /// No description provided for @backupSize.
  ///
  /// In hu, this message translates to:
  /// **'Méret: {size} bájt'**
  String backupSize(String size);

  /// No description provided for @backupValidated.
  ///
  /// In hu, this message translates to:
  /// **'A fájl szerkezete ellenőrizve. Ez nem igazolja minden régi bejegyzés érvényességét.'**
  String get backupValidated;

  /// No description provided for @backupSave.
  ///
  /// In hu, this message translates to:
  /// **'Mentés fájlba'**
  String get backupSave;

  /// No description provided for @backupSaved.
  ///
  /// In hu, this message translates to:
  /// **'A fájl mentése befejeződött.'**
  String get backupSaved;

  /// No description provided for @backupCancelled.
  ///
  /// In hu, this message translates to:
  /// **'A fájlmentést megszakítottad. Az alkalmazás adatai változatlanok.'**
  String get backupCancelled;

  /// No description provided for @backupDownloadRequested.
  ///
  /// In hu, this message translates to:
  /// **'A letöltési kérést átadtuk a böngészőnek. Ellenőrizd a letöltéseket és a fájl meglétét.'**
  String get backupDownloadRequested;

  /// No description provided for @backupPrepareError.
  ///
  /// In hu, this message translates to:
  /// **'Nem készült mentés. Az adatok változhattak, nem olvashatók, vagy túllépik a támogatott méretet. Próbáld újra; a helyi adatok változatlanok.'**
  String get backupPrepareError;

  /// No description provided for @backupSaveError.
  ///
  /// In hu, this message translates to:
  /// **'A fájlmentés nem sikerült. Ellenőrizd a célhelyet, és próbáld újra. A helyi adatok változatlanok.'**
  String get backupSaveError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hu'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hu':
      return AppLocalizationsHu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
