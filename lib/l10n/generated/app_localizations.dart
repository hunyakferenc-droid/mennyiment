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

  /// No description provided for @dailyOpen.
  ///
  /// In hu, this message translates to:
  /// **'Mai tudatos pillanat  •  +10 XP'**
  String get dailyOpen;

  /// No description provided for @dailyOpenSaved.
  ///
  /// In hu, this message translates to:
  /// **'Mai önellenőrzés és esti összegzés ✓'**
  String get dailyOpenSaved;

  /// No description provided for @dailyTitle.
  ///
  /// In hu, this message translates to:
  /// **'Egy pillanat magadra'**
  String get dailyTitle;

  /// No description provided for @dailyMorning.
  ///
  /// In hu, this message translates to:
  /// **'Jó reggelt!'**
  String get dailyMorning;

  /// No description provided for @dailyAfternoon.
  ///
  /// In hu, this message translates to:
  /// **'Szép napot!'**
  String get dailyAfternoon;

  /// No description provided for @dailyEveningGreeting.
  ///
  /// In hu, this message translates to:
  /// **'Szép estét!'**
  String get dailyEveningGreeting;

  /// No description provided for @dailyGreeting.
  ///
  /// In hu, this message translates to:
  /// **'{greeting} {name} veled van.'**
  String dailyGreeting(String greeting, String name);

  /// No description provided for @dailyOptional.
  ///
  /// In hu, this message translates to:
  /// **'Minden válasz opcionális. Italnapló nélkül is menthetsz. A kihagyott napokért nincs büntetés.'**
  String get dailyOptional;

  /// No description provided for @dailyWelcome.
  ///
  /// In hu, this message translates to:
  /// **'Örülök, hogy itt vagy. Ma is a saját tempódban haladhatsz.'**
  String get dailyWelcome;

  /// No description provided for @dailySupportLow.
  ///
  /// In hu, this message translates to:
  /// **'Ma nehezebbnek érzed? Egy kis pihenő vagy beszélgetés is segíthet. Nem kell mindent ma megoldanod.'**
  String get dailySupportLow;

  /// No description provided for @dailySupportMid.
  ///
  /// In hu, this message translates to:
  /// **'Köszönöm, hogy figyelsz magadra. Egy apró, kényelmes lépés is számít.'**
  String get dailySupportMid;

  /// No description provided for @dailySupportHigh.
  ///
  /// In hu, this message translates to:
  /// **'Jó hallani, hogy jól érzed magad! Mi lenne egy kedves apróság ma magadért?'**
  String get dailySupportHigh;

  /// No description provided for @dailyMood.
  ///
  /// In hu, this message translates to:
  /// **'Milyen most a hangulatod?'**
  String get dailyMood;

  /// No description provided for @dailyEnergy.
  ///
  /// In hu, this message translates to:
  /// **'Mennyi energiád van most?'**
  String get dailyEnergy;

  /// No description provided for @dailyScale.
  ///
  /// In hu, this message translates to:
  /// **'1 = nagyon alacsony, 5 = nagyon magas'**
  String get dailyScale;

  /// No description provided for @dailySkip.
  ///
  /// In hu, this message translates to:
  /// **'Kihagyom'**
  String get dailySkip;

  /// No description provided for @dailyGoal.
  ///
  /// In hu, this message translates to:
  /// **'Mai személyes cél (opcionális)'**
  String get dailyGoal;

  /// No description provided for @dailyGoalHint.
  ///
  /// In hu, this message translates to:
  /// **'Például: egy rövid séta vagy pihenő'**
  String get dailyGoalHint;

  /// No description provided for @dailyEvening.
  ///
  /// In hu, this message translates to:
  /// **'Esti összegzés (opcionális)'**
  String get dailyEvening;

  /// No description provided for @dailyEveningHint.
  ///
  /// In hu, this message translates to:
  /// **'Mi esett ma jól? Mit vinnél tovább holnapra?'**
  String get dailyEveningHint;

  /// No description provided for @dailyReward.
  ///
  /// In hu, this message translates to:
  /// **'Az önellenőrzésért naponta egyszer +10 XP jár. A válaszok kihagyhatók.'**
  String get dailyReward;

  /// No description provided for @dailyRewardDone.
  ///
  /// In hu, this message translates to:
  /// **'A mai önellenőrzés XP-jét már megkaptad. Szabadon frissítheted a válaszokat.'**
  String get dailyRewardDone;

  /// No description provided for @dailySave.
  ///
  /// In hu, this message translates to:
  /// **'Önellenőrzés mentése'**
  String get dailySave;

  /// No description provided for @dailySaved.
  ///
  /// In hu, this message translates to:
  /// **'Önellenőrzés mentve. A napi jutalmat csak egyszer számoljuk el.'**
  String get dailySaved;

  /// No description provided for @dailyLater.
  ///
  /// In hu, this message translates to:
  /// **'Most kihagyom'**
  String get dailyLater;

  /// No description provided for @dailyLoadError.
  ///
  /// In hu, this message translates to:
  /// **'Nem sikerült biztonságosan betölteni a napi adatokat. Nem írtuk felül őket.'**
  String get dailyLoadError;

  /// No description provided for @dailySaveError.
  ///
  /// In hu, this message translates to:
  /// **'A mentés nem fejeződött be. Próbáld újra; a napi XP nem duplázódik.'**
  String get dailySaveError;

  /// No description provided for @dailyRetry.
  ///
  /// In hu, this message translates to:
  /// **'Újrapróbálás'**
  String get dailyRetry;

  /// No description provided for @evolutionTitle.
  ///
  /// In hu, this message translates to:
  /// **'Menti fejlődése'**
  String get evolutionTitle;

  /// No description provided for @evolutionLevel.
  ///
  /// In hu, this message translates to:
  /// **'{level}. szint'**
  String evolutionLevel(int level);

  /// No description provided for @evolutionRemaining.
  ///
  /// In hu, this message translates to:
  /// **'Még {xp} XP a következő szintig'**
  String evolutionRemaining(int xp);

  /// No description provided for @evolutionTotal.
  ///
  /// In hu, this message translates to:
  /// **'Összesen {xp} XP'**
  String evolutionTotal(int xp);

  /// No description provided for @evolutionNext.
  ///
  /// In hu, this message translates to:
  /// **'Következő jutalom'**
  String get evolutionNext;

  /// No description provided for @evolutionAll.
  ///
  /// In hu, this message translates to:
  /// **'Minden jelenlegi ruhajutalom megszerezve. Haladj a saját tempódban!'**
  String get evolutionAll;

  /// No description provided for @evolutionUnlock.
  ///
  /// In hu, this message translates to:
  /// **'{level}. szint • még {xp} XP'**
  String evolutionUnlock(int level, int xp);

  /// No description provided for @evolutionDaily.
  ///
  /// In hu, this message translates to:
  /// **'Napi tudatos önellenőrzés'**
  String get evolutionDaily;

  /// No description provided for @evolutionDailyHint.
  ///
  /// In hu, this message translates to:
  /// **'Gondold át a napodat. Naponta egyszer +10 XP, a kezdőlappal közösen.'**
  String get evolutionDailyHint;

  /// No description provided for @evolutionChecked.
  ///
  /// In hu, this message translates to:
  /// **'Mai önellenőrzés kész'**
  String get evolutionChecked;

  /// No description provided for @evolutionCheck.
  ///
  /// In hu, this message translates to:
  /// **'Átgondoltam a napomat'**
  String get evolutionCheck;

  /// No description provided for @evolutionWeekly.
  ///
  /// In hu, this message translates to:
  /// **'Heti tudatos lépések'**
  String get evolutionWeekly;

  /// No description provided for @evolutionWeeklyHint.
  ///
  /// In hu, this message translates to:
  /// **'Önjelölés alapján, hetente egyszer. A lehetőségek hétfőn újulnak meg.'**
  String get evolutionWeeklyHint;

  /// No description provided for @evolutionReview.
  ///
  /// In hu, this message translates to:
  /// **'Átnéztem a naplómat'**
  String get evolutionReview;

  /// No description provided for @evolutionCost.
  ///
  /// In hu, this message translates to:
  /// **'Átgondoltam a költéseimet'**
  String get evolutionCost;

  /// No description provided for @evolutionGoal.
  ///
  /// In hu, this message translates to:
  /// **'Kijelöltem egy személyes célt'**
  String get evolutionGoal;

  /// No description provided for @evolutionDone.
  ///
  /// In hu, this message translates to:
  /// **'Kész'**
  String get evolutionDone;

  /// No description provided for @evolutionPoints.
  ///
  /// In hu, this message translates to:
  /// **'+{xp} XP • hetente egyszer'**
  String evolutionPoints(int xp);

  /// No description provided for @evolutionBadges.
  ///
  /// In hu, this message translates to:
  /// **'Teljesítményjelvények'**
  String get evolutionBadges;

  /// No description provided for @evolutionReflectionBadge.
  ///
  /// In hu, this message translates to:
  /// **'Tudatos önellenőrzés • 1 külön nap'**
  String get evolutionReflectionBadge;

  /// No description provided for @evolutionGoalBadge.
  ///
  /// In hu, this message translates to:
  /// **'Személyes cél • 1 heti cél kijelölése'**
  String get evolutionGoalBadge;

  /// No description provided for @evolutionConsistencyBadge.
  ///
  /// In hu, this message translates to:
  /// **'Következetesség • 7 külön nap, megszakítás megengedett'**
  String get evolutionConsistencyBadge;

  /// No description provided for @evolutionEarned.
  ///
  /// In hu, this message translates to:
  /// **'Megszerzett'**
  String get evolutionEarned;

  /// No description provided for @evolutionLocked.
  ///
  /// In hu, this message translates to:
  /// **'Még elérhető'**
  String get evolutionLocked;

  /// No description provided for @evolutionWeek.
  ///
  /// In hu, this message translates to:
  /// **'Ezen a héten: {days} önellenőrzés • {tasks} tudatos lépés'**
  String evolutionWeek(int days, int tasks);

  /// No description provided for @evolutionPolicy.
  ///
  /// In hu, this message translates to:
  /// **'Az alkoholmennyiség és a költés összege nem ad XP-t. Nincs negatív XP vagy büntetés kihagyott napért. A jelvényekért nem jár külön XP; nem mérnek egészségi állapotot vagy alkoholmentességet.'**
  String get evolutionPolicy;

  /// No description provided for @evolutionError.
  ///
  /// In hu, this message translates to:
  /// **'A fejlődés nem tölthető be vagy menthető. Próbáld újra.'**
  String get evolutionError;

  /// No description provided for @evolutionRetry.
  ///
  /// In hu, this message translates to:
  /// **'Újrapróbálás'**
  String get evolutionRetry;

  /// No description provided for @evolutionSaved.
  ///
  /// In hu, this message translates to:
  /// **'Mentve • +{xp} XP'**
  String evolutionSaved(int xp);

  /// No description provided for @evolutionWardrobe.
  ///
  /// In hu, this message translates to:
  /// **'Gardrób megnyitása'**
  String get evolutionWardrobe;

  /// No description provided for @evolutionBasic.
  ///
  /// In hu, this message translates to:
  /// **'Alap szett'**
  String get evolutionBasic;

  /// No description provided for @evolutionParty.
  ///
  /// In hu, this message translates to:
  /// **'Buli szett'**
  String get evolutionParty;

  /// No description provided for @evolutionSport.
  ///
  /// In hu, this message translates to:
  /// **'Sport szett'**
  String get evolutionSport;

  /// No description provided for @evolutionBusiness.
  ///
  /// In hu, this message translates to:
  /// **'Üzleti szett'**
  String get evolutionBusiness;

  /// No description provided for @evolutionFestival.
  ///
  /// In hu, this message translates to:
  /// **'Fesztivál szett'**
  String get evolutionFestival;

  /// No description provided for @evolutionLegendary.
  ///
  /// In hu, this message translates to:
  /// **'Legendás szett'**
  String get evolutionLegendary;

  /// No description provided for @evolutionImage.
  ///
  /// In hu, this message translates to:
  /// **'Az előnézet jelenleg nem érhető el'**
  String get evolutionImage;

  /// No description provided for @evolutionRules.
  ///
  /// In hu, this message translates to:
  /// **'Feloldás: Alap, Buli és Sport az 1., Üzleti a 2., Fesztivál a 3., Legendás az 5. szinten. A megszerzett ruhák megmaradnak.'**
  String get evolutionRules;

  /// No description provided for @challengeSaveError.
  ///
  /// In hu, this message translates to:
  /// **'A mentés nem sikerült. Próbáld újra.'**
  String get challengeSaveError;

  /// No description provided for @challengeCustom.
  ///
  /// In hu, this message translates to:
  /// **'Saját heti cél'**
  String get challengeCustom;

  /// No description provided for @challengeDaysPerWeek.
  ///
  /// In hu, this message translates to:
  /// **'Heti napok száma'**
  String get challengeDaysPerWeek;

  /// No description provided for @challengeCancel.
  ///
  /// In hu, this message translates to:
  /// **'Mégse'**
  String get challengeCancel;

  /// No description provided for @challengeSave.
  ///
  /// In hu, this message translates to:
  /// **'Mentés'**
  String get challengeSave;

  /// No description provided for @challengeReflection.
  ///
  /// In hu, this message translates to:
  /// **'Tudatos önellenőrzés'**
  String get challengeReflection;

  /// No description provided for @challengeJournal.
  ///
  /// In hu, this message translates to:
  /// **'Következetes közérzetnapló'**
  String get challengeJournal;

  /// No description provided for @challengeHabit.
  ///
  /// In hu, this message translates to:
  /// **'Tudatos szokás: rövid napi szünet'**
  String get challengeHabit;

  /// No description provided for @challengeTitle.
  ///
  /// In hu, this message translates to:
  /// **'Heti személyes kihívások'**
  String get challengeTitle;

  /// No description provided for @challengeOptional.
  ///
  /// In hu, this message translates to:
  /// **'A saját tempódban. Minden kihívás választható, kihagyható vagy megszakítható büntetés nélkül. Nincs XP-jutalom vagy levonás.'**
  String get challengeOptional;

  /// No description provided for @challengePrevious.
  ///
  /// In hu, this message translates to:
  /// **'Előző hét'**
  String get challengePrevious;

  /// No description provided for @challengeNext.
  ///
  /// In hu, this message translates to:
  /// **'Következő hét'**
  String get challengeNext;

  /// No description provided for @challengeLoadError.
  ///
  /// In hu, this message translates to:
  /// **'Az adatok nem olvashatók. Nem írjuk felül őket.'**
  String get challengeLoadError;

  /// No description provided for @challengeRetry.
  ///
  /// In hu, this message translates to:
  /// **'Újrapróbálás'**
  String get challengeRetry;

  /// No description provided for @challengeDays.
  ///
  /// In hu, this message translates to:
  /// **'nap'**
  String get challengeDays;

  /// No description provided for @challengeSkipped.
  ///
  /// In hu, this message translates to:
  /// **'Kihagyva – nincs büntetés.'**
  String get challengeSkipped;

  /// No description provided for @challengeStopped.
  ///
  /// In hu, this message translates to:
  /// **'Megszakítva – nincs büntetés.'**
  String get challengeStopped;

  /// No description provided for @challengeJournalHint.
  ///
  /// In hu, this message translates to:
  /// **'A mentett közérzetnapló napjai számítanak. Ital rögzítése nem szükséges.'**
  String get challengeJournalHint;

  /// No description provided for @challengeChoose.
  ///
  /// In hu, this message translates to:
  /// **'Kiválasztás'**
  String get challengeChoose;

  /// No description provided for @challengeEdit.
  ///
  /// In hu, this message translates to:
  /// **'Cél módosítása'**
  String get challengeEdit;

  /// No description provided for @challengeDoneToday.
  ///
  /// In hu, this message translates to:
  /// **'Ma megtettem'**
  String get challengeDoneToday;

  /// No description provided for @challengeSkip.
  ///
  /// In hu, this message translates to:
  /// **'Ezen a héten kihagyom'**
  String get challengeSkip;

  /// No description provided for @challengeStop.
  ///
  /// In hu, this message translates to:
  /// **'Megszakítás'**
  String get challengeStop;

  /// No description provided for @challengeSummary.
  ///
  /// In hu, this message translates to:
  /// **'Heti fejlődési összefoglaló'**
  String get challengeSummary;

  /// No description provided for @challengeJournalDays.
  ///
  /// In hu, this message translates to:
  /// **'Közérzetnaplóval kitöltött napok'**
  String get challengeJournalDays;

  /// No description provided for @challengeCaution.
  ///
  /// In hu, this message translates to:
  /// **'A hiányzó bejegyzés ismeretlen adat, nem alkoholmentes nap. Ezek a kihívások nem jelölnek alkoholmentességet. A cél módosítása csak a kiválasztott hetet érinti; a korábbi napok megmaradnak.'**
  String get challengeCaution;

  /// No description provided for @challengeRefresh.
  ///
  /// In hu, this message translates to:
  /// **'Összefoglaló frissítése'**
  String get challengeRefresh;

  /// No description provided for @backupTitle.
  ///
  /// In hu, this message translates to:
  /// **'Adatmentés és visszaállítás'**
  String get backupTitle;

  /// No description provided for @backupContents.
  ///
  /// In hu, this message translates to:
  /// **'A mentés tartalmazza az összes helyi naplót, a Reggeli Menti válaszait, az XP-t és előzményeit, a tartós ruhafeloldásokat, heti kihívásokat, karaktereket, célokat és beállításokat, az újabb alkalmazáskulcsokkal együtt.'**
  String get backupContents;

  /// No description provided for @backupPrivacy.
  ///
  /// In hu, this message translates to:
  /// **'A fájl nincs titkosítva, személyes adatokat tartalmaz. Csak biztonságos helyre mentsd. Az alkalmazás nem küldi automatikusan hálózatra; a fájl helyéről és megosztásáról te döntesz.'**
  String get backupPrivacy;

  /// No description provided for @backupRestoreDeferred.
  ///
  /// In hu, this message translates to:
  /// **'Visszaállítás előtt válassz mentést az ellenőrzött előnézethez. Csak kifejezett megerősítésed után módosítunk adatokat.'**
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

  /// No description provided for @restorePick.
  ///
  /// In hu, this message translates to:
  /// **'Mentés kiválasztása visszaállításhoz'**
  String get restorePick;

  /// No description provided for @restoreHint.
  ///
  /// In hu, this message translates to:
  /// **'A visszaállítás csak a fájlban szereplő kulcsokat adja hozzá vagy írja felül. A többi helyi adat megmarad. A tartós ruhafeloldásokat egyesítjük. Megerősítés előtt nézd át az alábbi kulcsokat.'**
  String get restoreHint;

  /// No description provided for @restorePreview.
  ///
  /// In hu, this message translates to:
  /// **'Visszaállítási előnézet'**
  String get restorePreview;

  /// No description provided for @restoreCounts.
  ///
  /// In hu, this message translates to:
  /// **'{added} új, {replaced} felülírt, {unchanged} változatlan kulcs'**
  String restoreCounts(int added, int replaced, int unchanged);

  /// No description provided for @restoreConfirm.
  ///
  /// In hu, this message translates to:
  /// **'Ezeknek az adatoknak a visszaállítása'**
  String get restoreConfirm;

  /// No description provided for @restoreQuestion.
  ///
  /// In hu, this message translates to:
  /// **'Visszaállítod az átnézett mentést?'**
  String get restoreQuestion;

  /// No description provided for @restoreWarning.
  ///
  /// In hu, this message translates to:
  /// **'A felsorolt adatokat erre az eszközre írjuk. Az érintett kulcsok meglévő értékeit felülírjuk. Folytatod?'**
  String get restoreWarning;

  /// No description provided for @restoreCancel.
  ///
  /// In hu, this message translates to:
  /// **'Mégse'**
  String get restoreCancel;

  /// No description provided for @restoreInvalid.
  ///
  /// In hu, this message translates to:
  /// **'A mentés hibás, nem támogatott, túl nagy vagy nem olvasható. Nem írtunk felhasználói adatot.'**
  String get restoreInvalid;

  /// No description provided for @restoreFailed.
  ///
  /// In hu, this message translates to:
  /// **'A visszaállítás nem sikerült. Az eredeti adatokat helyreállítottuk. Újrapróbálás előtt készíts új előnézetet.'**
  String get restoreFailed;

  /// No description provided for @restoreRecovery.
  ///
  /// In hu, this message translates to:
  /// **'A helyreállítás még nem teljes. Az eredeti adatok helyreállításáig a szerkesztést letiltottuk. Őrizd meg az alkalmazás helyi adatait, és próbáld újra.'**
  String get restoreRecovery;

  /// No description provided for @restoreRetry.
  ///
  /// In hu, this message translates to:
  /// **'Helyreállítás újrapróbálása'**
  String get restoreRetry;

  /// No description provided for @restoreSuccess.
  ///
  /// In hu, this message translates to:
  /// **'Az adatokat visszaállítottuk.'**
  String get restoreSuccess;

  /// No description provided for @restoreStale.
  ///
  /// In hu, this message translates to:
  /// **'A helyi adatok megváltoztak vagy a tároló nem elérhető. Nem történt sikeres visszaállítás. Válaszd ki újra a fájlt.'**
  String get restoreStale;

  /// No description provided for @homeEyebrow.
  ///
  /// In hu, this message translates to:
  /// **'MENNYIMENT? • A TE MENTID'**
  String get homeEyebrow;

  /// No description provided for @homeGreeting.
  ///
  /// In hu, this message translates to:
  /// **'Szia! Hogy vagy ma?'**
  String get homeGreeting;

  /// No description provided for @homeIntro.
  ///
  /// In hu, this message translates to:
  /// **'A mai tudatos döntéseid számítanak.'**
  String get homeIntro;

  /// No description provided for @homeMentiHint.
  ///
  /// In hu, this message translates to:
  /// **'Apró, tudatos lépésekből épül a fejlődés.'**
  String get homeMentiHint;

  /// No description provided for @homeTotalXp.
  ///
  /// In hu, this message translates to:
  /// **'{xp} XP összesen'**
  String homeTotalXp(int xp);

  /// No description provided for @homeLevelProgress.
  ///
  /// In hu, this message translates to:
  /// **'Haladás a következő Menti-szintig'**
  String get homeLevelProgress;

  /// No description provided for @homeXpHint.
  ///
  /// In hu, this message translates to:
  /// **'Az XP önellenőrzésért és tudatos heti kihívásokért jár, nem az elfogyasztott italokért.'**
  String get homeXpHint;

  /// No description provided for @homeTodayDrinks.
  ///
  /// In hu, this message translates to:
  /// **'Ma rögzített ital'**
  String get homeTodayDrinks;

  /// No description provided for @homeTodaySpending.
  ///
  /// In hu, this message translates to:
  /// **'Mai ismert költés'**
  String get homeTodaySpending;

  /// No description provided for @homeMonthSpending.
  ///
  /// In hu, this message translates to:
  /// **'Havi ismert költés'**
  String get homeMonthSpending;

  /// No description provided for @homeWeekDays.
  ///
  /// In hu, this message translates to:
  /// **'Heti naplózott nap'**
  String get homeWeekDays;

  /// No description provided for @homeMissingPrices.
  ///
  /// In hu, this message translates to:
  /// **'Hiányzó italárak: ma {today}, ebben a hónapban {month}. A költések részösszegek.'**
  String homeMissingPrices(int today, int month);

  /// No description provided for @homeEmptyJournal.
  ///
  /// In hu, this message translates to:
  /// **'Még nincs bejegyzés. Az első italodat a hozzáadás gombbal rögzítheted.'**
  String get homeEmptyJournal;

  /// No description provided for @homeUnknownPrice.
  ///
  /// In hu, this message translates to:
  /// **'Ismeretlen ár'**
  String get homeUnknownPrice;

  /// No description provided for @homeJournalUnavailable.
  ///
  /// In hu, this message translates to:
  /// **'A napló adatai most nem érhetők el. Az eredeti adatokat megőriztük.'**
  String get homeJournalUnavailable;

  /// No description provided for @homeJournalRetry.
  ///
  /// In hu, this message translates to:
  /// **'Napló újratöltése'**
  String get homeJournalRetry;

  /// No description provided for @homeLoading.
  ///
  /// In hu, this message translates to:
  /// **'Napló betöltése…'**
  String get homeLoading;

  /// No description provided for @homeRecordActions.
  ///
  /// In hu, this message translates to:
  /// **'Bejegyzés műveletei'**
  String get homeRecordActions;

  /// No description provided for @homeEnterPrice.
  ///
  /// In hu, this message translates to:
  /// **'Ár megadása'**
  String get homeEnterPrice;

  /// No description provided for @homeEditPrice.
  ///
  /// In hu, this message translates to:
  /// **'Ár: {price} – szerkesztés'**
  String homeEditPrice(String price);

  /// No description provided for @homeDeleteEntry.
  ///
  /// In hu, this message translates to:
  /// **'Bejegyzés törlése'**
  String get homeDeleteEntry;

  /// No description provided for @homeCheckInUnavailable.
  ///
  /// In hu, this message translates to:
  /// **'A Menti-előrehaladás most nem tölthető be. Próbáld újra.'**
  String get homeCheckInUnavailable;

  /// No description provided for @homeRetryProgress.
  ///
  /// In hu, this message translates to:
  /// **'Menti újratöltése'**
  String get homeRetryProgress;

  /// No description provided for @homeJournalSaveError.
  ///
  /// In hu, this message translates to:
  /// **'A napló mentése nem sikerült. A módosítást nem alkalmaztuk. Próbáld újra vagy töltsd be újra a naplót.'**
  String get homeJournalSaveError;

  /// No description provided for @homeJournalLoadError.
  ///
  /// In hu, this message translates to:
  /// **'A napló nem tölthető be biztonságosan. Az eredeti adatokat megőriztük; a módosításokat letiltottuk.'**
  String get homeJournalLoadError;

  /// No description provided for @goalPageTitle.
  ///
  /// In hu, this message translates to:
  /// **'Személyes céljaim'**
  String get goalPageTitle;

  /// No description provided for @goalOwnPace.
  ///
  /// In hu, this message translates to:
  /// **'A saját tempódban'**
  String get goalOwnPace;

  /// No description provided for @goalIntro.
  ///
  /// In hu, this message translates to:
  /// **'Itt te döntöd el, mit szeretnél követni. A tudatos átgondolás számít, nem az elfogyasztott italok száma.'**
  String get goalIntro;

  /// No description provided for @goalBudgetTitle.
  ///
  /// In hu, this message translates to:
  /// **'Heti ital-költségkeret'**
  String get goalBudgetTitle;

  /// No description provided for @goalRecordedSpending.
  ///
  /// In hu, this message translates to:
  /// **'Rögzített költés: {amount}'**
  String goalRecordedSpending(String amount);

  /// No description provided for @goalNoBudget.
  ///
  /// In hu, this message translates to:
  /// **'Még nincs keret beállítva.'**
  String get goalNoBudget;

  /// No description provided for @goalBudgetValue.
  ///
  /// In hu, this message translates to:
  /// **'Saját heti keret: {amount}'**
  String goalBudgetValue(String amount);

  /// No description provided for @goalMissingPrices.
  ///
  /// In hu, this message translates to:
  /// **'{count} ital ára hiányzik. A költés csak részösszeg, így a keret teljesítése nem igazolható.'**
  String goalMissingPrices(int count);

  /// No description provided for @goalOverBudget.
  ///
  /// In hu, this message translates to:
  /// **'A rögzített költés meghaladja a keretet.'**
  String get goalOverBudget;

  /// No description provided for @goalWithinBudget.
  ///
  /// In hu, this message translates to:
  /// **'A rögzített költés a kereten belül van. Ez nem igazolja a teljes heti költést.'**
  String get goalWithinBudget;

  /// No description provided for @goalEditBudget.
  ///
  /// In hu, this message translates to:
  /// **'Keret szerkesztése'**
  String get goalEditBudget;

  /// No description provided for @goalReflectionTitle.
  ///
  /// In hu, this message translates to:
  /// **'Heti tudatos önellenőrzés'**
  String get goalReflectionTitle;

  /// No description provided for @goalProgress.
  ///
  /// In hu, this message translates to:
  /// **'{count} / {target} alkalom'**
  String goalProgress(int count, int target);

  /// No description provided for @goalCheckDone.
  ///
  /// In hu, this message translates to:
  /// **'Mai önellenőrzés kész'**
  String get goalCheckDone;

  /// No description provided for @goalCheckAction.
  ///
  /// In hu, this message translates to:
  /// **'Ma átgondoltam a napomat'**
  String get goalCheckAction;

  /// No description provided for @goalCurrentWeekOnly.
  ///
  /// In hu, this message translates to:
  /// **'Csak az aktuális héten rögzíthető'**
  String get goalCurrentWeekOnly;

  /// No description provided for @goalEditTarget.
  ///
  /// In hu, this message translates to:
  /// **'Heti cél módosítása'**
  String get goalEditTarget;

  /// No description provided for @goalMentiThought.
  ///
  /// In hu, this message translates to:
  /// **'Menti gondolata'**
  String get goalMentiThought;

  /// No description provided for @goalThoughtComplete.
  ///
  /// In hu, this message translates to:
  /// **'A rögzített önellenőrzéseid alapján teljesítetted a heti célodat.'**
  String get goalThoughtComplete;

  /// No description provided for @goalThoughtStart.
  ///
  /// In hu, this message translates to:
  /// **'Nem kell tökéletes nap. Egy rövid átgondolás is jó kezdet.'**
  String get goalThoughtStart;

  /// No description provided for @goalThoughtProgress.
  ///
  /// In hu, this message translates to:
  /// **'Már {count} alkalommal megálltál átgondolni a napodat. Haladj a saját tempódban!'**
  String goalThoughtProgress(int count);

  /// No description provided for @goalCaution.
  ///
  /// In hu, this message translates to:
  /// **'A hiányzó naplóbejegyzés nem bizonyít alkoholmentes napot. A költések önbevalláson alapulnak. Ez az önellenőrzés nem ad külön XP-t.'**
  String get goalCaution;

  /// No description provided for @goalBudgetDialog.
  ///
  /// In hu, this message translates to:
  /// **'Heti ital-költségkeret (Ft)'**
  String get goalBudgetDialog;

  /// No description provided for @goalTargetDialog.
  ///
  /// In hu, this message translates to:
  /// **'Heti önellenőrzések célja'**
  String get goalTargetDialog;

  /// No description provided for @goalBudgetHint.
  ///
  /// In hu, this message translates to:
  /// **'Például 10000'**
  String get goalBudgetHint;

  /// No description provided for @goalTargetHint.
  ///
  /// In hu, this message translates to:
  /// **'1–7 nap'**
  String get goalTargetHint;

  /// No description provided for @goalBudgetHelp.
  ///
  /// In hu, this message translates to:
  /// **'A nullás keret is megengedett.'**
  String get goalBudgetHelp;

  /// No description provided for @goalTargetHelp.
  ///
  /// In hu, this message translates to:
  /// **'Naponta legfeljebb egy önellenőrzés.'**
  String get goalTargetHelp;

  /// No description provided for @goalInvalidValue.
  ///
  /// In hu, this message translates to:
  /// **'Érvénytelen célérték.'**
  String get goalInvalidValue;

  /// No description provided for @goalLoadError.
  ///
  /// In hu, this message translates to:
  /// **'A célok nem tölthetők be biztonságosan. Az eredeti adatok megmaradtak, a módosítások letiltva.'**
  String get goalLoadError;

  /// No description provided for @goalSaveError.
  ///
  /// In hu, this message translates to:
  /// **'A célok mentése nem sikerült. A felület nem jelöli teljesítettnek a módosítást. Töltsd újra az adatokat, majd próbáld újra.'**
  String get goalSaveError;

  /// No description provided for @goalReload.
  ///
  /// In hu, this message translates to:
  /// **'Célok újratöltése'**
  String get goalReload;

  /// No description provided for @hubTitle.
  ///
  /// In hu, this message translates to:
  /// **'Saját Menti • Áttekintés'**
  String get hubTitle;

  /// No description provided for @hubIntro.
  ///
  /// In hu, this message translates to:
  /// **'A rögzített adataid egy helyen. A hiányzó bejegyzés nem jelent alkoholmentes napot.'**
  String get hubIntro;

  /// No description provided for @hubProfile.
  ///
  /// In hu, this message translates to:
  /// **'Karakter és ruha'**
  String get hubProfile;

  /// No description provided for @hubXp.
  ///
  /// In hu, this message translates to:
  /// **'Menti-előrehaladás'**
  String get hubXp;

  /// No description provided for @hubDaily.
  ///
  /// In hu, this message translates to:
  /// **'Mai önellenőrzés'**
  String get hubDaily;

  /// No description provided for @hubGoals.
  ///
  /// In hu, this message translates to:
  /// **'Személyes heti cél'**
  String get hubGoals;

  /// No description provided for @hubChallenges.
  ///
  /// In hu, this message translates to:
  /// **'Külön heti kihívások'**
  String get hubChallenges;

  /// No description provided for @hubJournal.
  ///
  /// In hu, this message translates to:
  /// **'Heti italnapló és költés'**
  String get hubJournal;

  /// No description provided for @hubMissing.
  ///
  /// In hu, this message translates to:
  /// **'Menti itt még nem lát mentett adatot.'**
  String get hubMissing;

  /// No description provided for @hubReadError.
  ///
  /// In hu, this message translates to:
  /// **'Ez az adat nem olvasható megbízhatóan. Nem helyettesítettük alapértékkel.'**
  String get hubReadError;

  /// No description provided for @hubGlobalError.
  ///
  /// In hu, this message translates to:
  /// **'Az áttekintő nem tölthető be. Az eredeti adatokat nem módosítottuk.'**
  String get hubGlobalError;

  /// No description provided for @hubRefresh.
  ///
  /// In hu, this message translates to:
  /// **'Áttekintő frissítése'**
  String get hubRefresh;

  /// No description provided for @hubUpdated.
  ///
  /// In hu, this message translates to:
  /// **'Pillanatkép: {date}'**
  String hubUpdated(String date);

  /// No description provided for @hubWeek.
  ///
  /// In hu, this message translates to:
  /// **'Aktuális hét: {start} – {end}'**
  String hubWeek(String start, String end);

  /// No description provided for @hubDailyAnswers.
  ///
  /// In hu, this message translates to:
  /// **'A mai napi válaszok rögzítve.'**
  String get hubDailyAnswers;

  /// No description provided for @hubNoDailyAnswers.
  ///
  /// In hu, this message translates to:
  /// **'Nincs rögzített mai válasz a napi bejegyzésben.'**
  String get hubNoDailyAnswers;

  /// No description provided for @hubXpToday.
  ///
  /// In hu, this message translates to:
  /// **'A mai XP-önellenőrzés rögzítve.'**
  String get hubXpToday;

  /// No description provided for @hubNoXpToday.
  ///
  /// In hu, this message translates to:
  /// **'Ebben az XP-naplóban nincs mai önellenőrzés.'**
  String get hubNoXpToday;

  /// No description provided for @hubWeekChecks.
  ///
  /// In hu, this message translates to:
  /// **'Naplózott napi XP-önellenőrzés: {count}'**
  String hubWeekChecks(int count);

  /// No description provided for @hubNoTarget.
  ///
  /// In hu, this message translates to:
  /// **'Nincs mentett személyes célszám.'**
  String get hubNoTarget;

  /// No description provided for @hubNoCheckDays.
  ///
  /// In hu, this message translates to:
  /// **'Nincs mentett önellenőrzési naplista.'**
  String get hubNoCheckDays;

  /// No description provided for @hubGoalConfirmed.
  ///
  /// In hu, this message translates to:
  /// **'A rögzített önellenőrzések alapján a cél teljesült.'**
  String get hubGoalConfirmed;

  /// No description provided for @hubGoalOngoing.
  ///
  /// In hu, this message translates to:
  /// **'A rögzített önellenőrzések alapján a cél még nincs teljesítve.'**
  String get hubGoalOngoing;

  /// No description provided for @hubNoChallenges.
  ///
  /// In hu, this message translates to:
  /// **'Erre a hétre nincs választott kihívás.'**
  String get hubNoChallenges;

  /// No description provided for @hubEvidenceMissing.
  ///
  /// In hu, this message translates to:
  /// **'A teljesítéshez szükséges naplóadat hiányzik vagy nem olvasható.'**
  String get hubEvidenceMissing;

  /// No description provided for @hubRecordedEmpty.
  ///
  /// In hu, this message translates to:
  /// **'A mentett naplóban ezen a héten 0 bejegyzés van. Ez nem igazol alkoholmentes napokat.'**
  String get hubRecordedEmpty;

  /// No description provided for @hubKnownZero.
  ///
  /// In hu, this message translates to:
  /// **'Az ismert árak rögzített összege 0. Az ismeretlen árak nem számítanak nullának.'**
  String get hubKnownZero;

  /// No description provided for @hubOutfitBasic.
  ///
  /// In hu, this message translates to:
  /// **'Alap szett'**
  String get hubOutfitBasic;

  /// No description provided for @hubOutfitParty.
  ///
  /// In hu, this message translates to:
  /// **'Buli szett'**
  String get hubOutfitParty;

  /// No description provided for @hubOutfitSport.
  ///
  /// In hu, this message translates to:
  /// **'Sport szett'**
  String get hubOutfitSport;

  /// No description provided for @hubOutfitBusiness.
  ///
  /// In hu, this message translates to:
  /// **'Üzleti szett'**
  String get hubOutfitBusiness;

  /// No description provided for @hubOutfitFestival.
  ///
  /// In hu, this message translates to:
  /// **'Fesztivál szett'**
  String get hubOutfitFestival;

  /// No description provided for @hubOutfitLegendary.
  ///
  /// In hu, this message translates to:
  /// **'Legendás szett'**
  String get hubOutfitLegendary;

  /// No description provided for @hubFamilyBoy.
  ///
  /// In hu, this message translates to:
  /// **'Fiú Menti'**
  String get hubFamilyBoy;

  /// No description provided for @hubFamilyGirl.
  ///
  /// In hu, this message translates to:
  /// **'Lány Menti'**
  String get hubFamilyGirl;

  /// No description provided for @hubFamilyNeutral.
  ///
  /// In hu, this message translates to:
  /// **'Semleges Menti'**
  String get hubFamilyNeutral;

  /// No description provided for @hubImageError.
  ///
  /// In hu, this message translates to:
  /// **'A kiválasztott karakter képe nem jeleníthető meg.'**
  String get hubImageError;

  /// No description provided for @reactionTitle.
  ///
  /// In hu, this message translates to:
  /// **'Menti üzenete'**
  String get reactionTitle;

  /// No description provided for @hubOverview.
  ///
  /// In hu, this message translates to:
  /// **'Áttekintés'**
  String get hubOverview;

  /// No description provided for @experienceSettings.
  ///
  /// In hu, this message translates to:
  /// **'Beállítások és súgó'**
  String get experienceSettings;

  /// No description provided for @experienceIntroTitle.
  ///
  /// In hu, this message translates to:
  /// **'Ismerd meg Mentit'**
  String get experienceIntroTitle;

  /// No description provided for @experienceIntroInvite.
  ///
  /// In hu, this message translates to:
  /// **'Új társ a naplód mellé. Megismered Mentit?'**
  String get experienceIntroInvite;

  /// No description provided for @experienceIntroOpen.
  ///
  /// In hu, this message translates to:
  /// **'Menti bemutatkozása'**
  String get experienceIntroOpen;

  /// No description provided for @experienceIntroSkip.
  ///
  /// In hu, this message translates to:
  /// **'Átugrás'**
  String get experienceIntroSkip;

  /// No description provided for @experienceIntroNext.
  ///
  /// In hu, this message translates to:
  /// **'Tovább'**
  String get experienceIntroNext;

  /// No description provided for @experienceIntroBack.
  ///
  /// In hu, this message translates to:
  /// **'Előző'**
  String get experienceIntroBack;

  /// No description provided for @experienceIntroDone.
  ///
  /// In hu, this message translates to:
  /// **'Nézzük a naplómat'**
  String get experienceIntroDone;

  /// No description provided for @experienceIntroStep.
  ///
  /// In hu, this message translates to:
  /// **'{step} / {total} lépés'**
  String experienceIntroStep(int step, int total);

  /// No description provided for @experienceIntro1Title.
  ///
  /// In hu, this message translates to:
  /// **'Szia, Menti vagyok!'**
  String get experienceIntro1Title;

  /// No description provided for @experienceIntro1Body.
  ///
  /// In hu, this message translates to:
  /// **'Narancssárga társad az önmegfigyelésben. Te döntesz a tempóról, a karakterről és a ruháról. Nincs kötelező regisztráció.'**
  String get experienceIntro1Body;

  /// No description provided for @experienceIntro2Title.
  ///
  /// In hu, this message translates to:
  /// **'A napló a tiéd'**
  String get experienceIntro2Title;

  /// No description provided for @experienceIntro2Body.
  ///
  /// In hu, this message translates to:
  /// **'Rögzíthetsz italokat és ismert árakat, majd megnézheted az összesítéseket. A hiányzó bejegyzés nem bizonyít alkoholmentes napot, az ismeretlen ár pedig nem nulla.'**
  String get experienceIntro2Body;

  /// No description provided for @experienceIntro3Title.
  ///
  /// In hu, this message translates to:
  /// **'Egy perc magadra'**
  String get experienceIntro3Title;

  /// No description provided for @experienceIntro3Body.
  ///
  /// In hu, this message translates to:
  /// **'A napi Menti és a saját céljaid a tudatos átgondolásról szólnak. Az XP a meglévő önellenőrzésekhez és feladatokhoz kapcsolódik, nem az italok mennyiségéhez.'**
  String get experienceIntro3Body;

  /// No description provided for @experienceIntro4Title.
  ///
  /// In hu, this message translates to:
  /// **'Adataid és mentéseid'**
  String get experienceIntro4Title;

  /// No description provided for @experienceIntro4Body.
  ///
  /// In hu, this message translates to:
  /// **'A napló helyi tárhelyet használ. A mentést és visszaállítást te indítod. Az exportált fájl személyes adatokat tartalmazhat és nem titkosított; kezeld bizalmasan. Ez az app nem állapítja meg a józanságot vagy a vezetési képességet.'**
  String get experienceIntro4Body;

  /// No description provided for @experienceReactions.
  ///
  /// In hu, this message translates to:
  /// **'Menti-üzenetek és reakciók'**
  String get experienceReactions;

  /// No description provided for @experienceReactionsHint.
  ///
  /// In hu, this message translates to:
  /// **'A kikapcsolás csak a megjelenítést érinti. Az XP és a céljaid változatlanok.'**
  String get experienceReactionsHint;

  /// No description provided for @experienceLoadError.
  ///
  /// In hu, this message translates to:
  /// **'A megjelenítési beállítás nem olvasható biztonságosan. Az eredeti értéket megőriztük.'**
  String get experienceLoadError;

  /// No description provided for @experienceSaveError.
  ///
  /// In hu, this message translates to:
  /// **'A beállítás mentését nem sikerült igazolni. Az előző állapot maradt érvényben; töltsd újra, majd próbáld ismét.'**
  String get experienceSaveError;

  /// No description provided for @experienceReload.
  ///
  /// In hu, this message translates to:
  /// **'Beállítások újratöltése'**
  String get experienceReload;

  /// No description provided for @experienceMotionTitle.
  ///
  /// In hu, this message translates to:
  /// **'Menti mozgásának csökkentése'**
  String get experienceMotionTitle;

  /// No description provided for @experienceMotionHint.
  ///
  /// In hu, this message translates to:
  /// **'Állókép a lebegés, billegés és reakcióanimáció helyett.'**
  String get experienceMotionHint;

  /// No description provided for @experienceMotionSystem.
  ///
  /// In hu, this message translates to:
  /// **'A rendszer mozgáscsökkentése aktív. Ezt a kapcsoló nem írja felül.'**
  String get experienceMotionSystem;

  /// No description provided for @experienceMotionLoadError.
  ///
  /// In hu, this message translates to:
  /// **'A mozgásbeállítás nem tölthető be.'**
  String get experienceMotionLoadError;

  /// No description provided for @experienceMotionSaveError.
  ///
  /// In hu, this message translates to:
  /// **'A mozgásbeállítás nem menthető. Próbáld újra.'**
  String get experienceMotionSaveError;

  /// No description provided for @experienceToday.
  ///
  /// In hu, this message translates to:
  /// **'Ma Mentivel'**
  String get experienceToday;

  /// No description provided for @experienceTodayStart1.
  ///
  /// In hu, this message translates to:
  /// **'Egy perc magadra? Menti figyel, a napló megvár.'**
  String get experienceTodayStart1;

  /// No description provided for @experienceTodayStart2.
  ///
  /// In hu, this message translates to:
  /// **'A saját tempód jó tempó. Egy rövid önellenőrzés is elég lehet mára.'**
  String get experienceTodayStart2;

  /// No description provided for @experienceTodayAnswers.
  ///
  /// In hu, this message translates to:
  /// **'A mai válaszaid elmentve. Menti füzetében ez már megvan.'**
  String get experienceTodayAnswers;

  /// No description provided for @experienceTodayChecked.
  ///
  /// In hu, this message translates to:
  /// **'A mai önellenőrzés rögzítve. Menti képzeletben bólint.'**
  String get experienceTodayChecked;

  /// No description provided for @experienceTodayGoal.
  ///
  /// In hu, this message translates to:
  /// **'A rögzített napok szerint a heti önellenőrzési célod teljesült. Szép, tudatos lépések!'**
  String get experienceTodayGoal;

  /// No description provided for @experienceTodayChallenge.
  ///
  /// In hu, this message translates to:
  /// **'A rögzített adatok szerint van teljesített heti kihívásod. Menti megemeli a sapkáját.'**
  String get experienceTodayChallenge;

  /// No description provided for @experienceTodayUnknown.
  ///
  /// In hu, this message translates to:
  /// **'Most nem minden adat olvasható. Menti nem találgat; az áttekintőben újrapróbálhatod.'**
  String get experienceTodayUnknown;

  /// No description provided for @experienceOpenDaily.
  ///
  /// In hu, this message translates to:
  /// **'Napi Menti megnyitása'**
  String get experienceOpenDaily;

  /// No description provided for @experienceOpenHub.
  ///
  /// In hu, this message translates to:
  /// **'Áttekintés megnyitása'**
  String get experienceOpenHub;

  /// No description provided for @experienceEmptyJournal.
  ///
  /// In hu, this message translates to:
  /// **'Menti füzetében még nincs bejegyzés. Akkor naplózz, amikor neked hasznos.'**
  String get experienceEmptyJournal;

  /// No description provided for @experienceAddEntry.
  ///
  /// In hu, this message translates to:
  /// **'Bejegyzés rögzítése'**
  String get experienceAddEntry;

  /// No description provided for @experienceTodayLoading.
  ///
  /// In hu, this message translates to:
  /// **'Menti megnézi a mai rögzítéseket…'**
  String get experienceTodayLoading;

  /// No description provided for @avatarFamilyBoy.
  ///
  /// In hu, this message translates to:
  /// **'Fiú'**
  String get avatarFamilyBoy;

  /// No description provided for @avatarFamilyGirl.
  ///
  /// In hu, this message translates to:
  /// **'Lány'**
  String get avatarFamilyGirl;

  /// No description provided for @avatarFamilyNeutral.
  ///
  /// In hu, this message translates to:
  /// **'Semleges'**
  String get avatarFamilyNeutral;

  /// No description provided for @avatarAgeYoung.
  ///
  /// In hu, this message translates to:
  /// **'Fiatalos'**
  String get avatarAgeYoung;

  /// No description provided for @avatarAgeAdult.
  ///
  /// In hu, this message translates to:
  /// **'Felnőttes'**
  String get avatarAgeAdult;

  /// No description provided for @avatarAgeVeteran.
  ///
  /// In hu, this message translates to:
  /// **'Veterán'**
  String get avatarAgeVeteran;

  /// No description provided for @avatarFaceCheerful.
  ///
  /// In hu, this message translates to:
  /// **'Vidám'**
  String get avatarFaceCheerful;

  /// No description provided for @avatarFaceCalm.
  ///
  /// In hu, this message translates to:
  /// **'Nyugodt'**
  String get avatarFaceCalm;

  /// No description provided for @avatarFacePlayful.
  ///
  /// In hu, this message translates to:
  /// **'Játékos'**
  String get avatarFacePlayful;

  /// No description provided for @avatarFaceConfident.
  ///
  /// In hu, this message translates to:
  /// **'Magabiztos'**
  String get avatarFaceConfident;

  /// No description provided for @avatarFaceSleepy.
  ///
  /// In hu, this message translates to:
  /// **'Álmos'**
  String get avatarFaceSleepy;

  /// No description provided for @avatarFaceDetermined.
  ///
  /// In hu, this message translates to:
  /// **'Elszánt'**
  String get avatarFaceDetermined;

  /// No description provided for @avatarEyesRound.
  ///
  /// In hu, this message translates to:
  /// **'Kerek'**
  String get avatarEyesRound;

  /// No description provided for @avatarEyesWide.
  ///
  /// In hu, this message translates to:
  /// **'Tágra nyílt'**
  String get avatarEyesWide;

  /// No description provided for @avatarEyesRelaxed.
  ///
  /// In hu, this message translates to:
  /// **'Laza'**
  String get avatarEyesRelaxed;

  /// No description provided for @avatarEyesSharp.
  ///
  /// In hu, this message translates to:
  /// **'Éles tekintet'**
  String get avatarEyesSharp;

  /// No description provided for @avatarHairBoyCrop.
  ///
  /// In hu, this message translates to:
  /// **'Rövid'**
  String get avatarHairBoyCrop;

  /// No description provided for @avatarHairBoyWaves.
  ///
  /// In hu, this message translates to:
  /// **'Hullámos'**
  String get avatarHairBoyWaves;

  /// No description provided for @avatarHairBoyCurls.
  ///
  /// In hu, this message translates to:
  /// **'Göndör'**
  String get avatarHairBoyCurls;

  /// No description provided for @avatarHairBoyBraid.
  ///
  /// In hu, this message translates to:
  /// **'Fonott'**
  String get avatarHairBoyBraid;

  /// No description provided for @avatarHairBoyBob.
  ///
  /// In hu, this message translates to:
  /// **'Bob'**
  String get avatarHairBoyBob;

  /// No description provided for @avatarHairBoyCrest.
  ///
  /// In hu, this message translates to:
  /// **'Taréj'**
  String get avatarHairBoyCrest;

  /// No description provided for @avatarHairGirlCrop.
  ///
  /// In hu, this message translates to:
  /// **'Rövid'**
  String get avatarHairGirlCrop;

  /// No description provided for @avatarHairGirlWaves.
  ///
  /// In hu, this message translates to:
  /// **'Hullámos'**
  String get avatarHairGirlWaves;

  /// No description provided for @avatarHairGirlCurls.
  ///
  /// In hu, this message translates to:
  /// **'Göndör'**
  String get avatarHairGirlCurls;

  /// No description provided for @avatarHairGirlBraid.
  ///
  /// In hu, this message translates to:
  /// **'Fonott'**
  String get avatarHairGirlBraid;

  /// No description provided for @avatarHairGirlBob.
  ///
  /// In hu, this message translates to:
  /// **'Bob'**
  String get avatarHairGirlBob;

  /// No description provided for @avatarHairGirlCrest.
  ///
  /// In hu, this message translates to:
  /// **'Taréj'**
  String get avatarHairGirlCrest;

  /// No description provided for @avatarHairNeutralCrop.
  ///
  /// In hu, this message translates to:
  /// **'Rövid'**
  String get avatarHairNeutralCrop;

  /// No description provided for @avatarHairNeutralWaves.
  ///
  /// In hu, this message translates to:
  /// **'Hullámos'**
  String get avatarHairNeutralWaves;

  /// No description provided for @avatarHairNeutralCurls.
  ///
  /// In hu, this message translates to:
  /// **'Göndör'**
  String get avatarHairNeutralCurls;

  /// No description provided for @avatarHairNeutralBraid.
  ///
  /// In hu, this message translates to:
  /// **'Fonott'**
  String get avatarHairNeutralBraid;

  /// No description provided for @avatarHairNeutralBob.
  ///
  /// In hu, this message translates to:
  /// **'Bob'**
  String get avatarHairNeutralBob;

  /// No description provided for @avatarHairNeutralCrest.
  ///
  /// In hu, this message translates to:
  /// **'Taréj'**
  String get avatarHairNeutralCrest;

  /// No description provided for @avatarHeadwearCrownCap.
  ///
  /// In hu, this message translates to:
  /// **'Koronás sapka'**
  String get avatarHeadwearCrownCap;

  /// No description provided for @avatarHeadwearSportCap.
  ///
  /// In hu, this message translates to:
  /// **'Sportsapka'**
  String get avatarHeadwearSportCap;

  /// No description provided for @avatarHeadwearBeanie.
  ///
  /// In hu, this message translates to:
  /// **'Kötött sapka'**
  String get avatarHeadwearBeanie;

  /// No description provided for @avatarHeadwearHeadphones.
  ///
  /// In hu, this message translates to:
  /// **'Fejhallgató'**
  String get avatarHeadwearHeadphones;

  /// No description provided for @avatarHeadwearPartyCrown.
  ///
  /// In hu, this message translates to:
  /// **'Ünnepi korona'**
  String get avatarHeadwearPartyCrown;

  /// No description provided for @avatarHeadwearHood.
  ///
  /// In hu, this message translates to:
  /// **'Kapucni'**
  String get avatarHeadwearHood;

  /// No description provided for @avatarHeadwearNone.
  ///
  /// In hu, this message translates to:
  /// **'Fejfedő nélkül'**
  String get avatarHeadwearNone;

  /// No description provided for @avatarHeadwearPartyHat.
  ///
  /// In hu, this message translates to:
  /// **'Csúcsos kalap'**
  String get avatarHeadwearPartyHat;

  /// No description provided for @avatarHeadwearBeret.
  ///
  /// In hu, this message translates to:
  /// **'Barett'**
  String get avatarHeadwearBeret;

  /// No description provided for @avatarOutfitBasic.
  ///
  /// In hu, this message translates to:
  /// **'Alap szett'**
  String get avatarOutfitBasic;

  /// No description provided for @avatarOutfitBasicAlt.
  ///
  /// In hu, this message translates to:
  /// **'Alap szett · extra'**
  String get avatarOutfitBasicAlt;

  /// No description provided for @avatarOutfitParty.
  ///
  /// In hu, this message translates to:
  /// **'Buli'**
  String get avatarOutfitParty;

  /// No description provided for @avatarOutfitPartyAlt.
  ///
  /// In hu, this message translates to:
  /// **'Buli · extra'**
  String get avatarOutfitPartyAlt;

  /// No description provided for @avatarOutfitSport.
  ///
  /// In hu, this message translates to:
  /// **'Sport'**
  String get avatarOutfitSport;

  /// No description provided for @avatarOutfitSportAlt.
  ///
  /// In hu, this message translates to:
  /// **'Sport · extra'**
  String get avatarOutfitSportAlt;

  /// No description provided for @avatarOutfitBusiness.
  ///
  /// In hu, this message translates to:
  /// **'Üzleti'**
  String get avatarOutfitBusiness;

  /// No description provided for @avatarOutfitBusinessAlt.
  ///
  /// In hu, this message translates to:
  /// **'Üzleti · extra'**
  String get avatarOutfitBusinessAlt;

  /// No description provided for @avatarOutfitFestival.
  ///
  /// In hu, this message translates to:
  /// **'Fesztivál'**
  String get avatarOutfitFestival;

  /// No description provided for @avatarOutfitFestivalAlt.
  ///
  /// In hu, this message translates to:
  /// **'Fesztivál · extra'**
  String get avatarOutfitFestivalAlt;

  /// No description provided for @avatarOutfitLegendary.
  ///
  /// In hu, this message translates to:
  /// **'Legendás'**
  String get avatarOutfitLegendary;

  /// No description provided for @avatarOutfitLegendaryAlt.
  ///
  /// In hu, this message translates to:
  /// **'Legendás · extra'**
  String get avatarOutfitLegendaryAlt;

  /// No description provided for @avatarOutfitStreet.
  ///
  /// In hu, this message translates to:
  /// **'Utcai'**
  String get avatarOutfitStreet;

  /// No description provided for @avatarOutfitStreetAlt.
  ///
  /// In hu, this message translates to:
  /// **'Utcai · extra'**
  String get avatarOutfitStreetAlt;

  /// No description provided for @avatarOutfitCozy.
  ///
  /// In hu, this message translates to:
  /// **'Kuckózós'**
  String get avatarOutfitCozy;

  /// No description provided for @avatarOutfitCozyAlt.
  ///
  /// In hu, this message translates to:
  /// **'Kuckózós · extra'**
  String get avatarOutfitCozyAlt;

  /// No description provided for @avatarOutfitExplorer.
  ///
  /// In hu, this message translates to:
  /// **'Felfedező'**
  String get avatarOutfitExplorer;

  /// No description provided for @avatarOutfitExplorerAlt.
  ///
  /// In hu, this message translates to:
  /// **'Felfedező · extra'**
  String get avatarOutfitExplorerAlt;

  /// No description provided for @avatarOutfitCreative.
  ///
  /// In hu, this message translates to:
  /// **'Alkotó'**
  String get avatarOutfitCreative;

  /// No description provided for @avatarOutfitCreativeAlt.
  ///
  /// In hu, this message translates to:
  /// **'Alkotó · extra'**
  String get avatarOutfitCreativeAlt;

  /// No description provided for @avatarStyleClassic.
  ///
  /// In hu, this message translates to:
  /// **'Klasszikus'**
  String get avatarStyleClassic;

  /// No description provided for @avatarStyleStreet.
  ///
  /// In hu, this message translates to:
  /// **'Utcai'**
  String get avatarStyleStreet;

  /// No description provided for @avatarStyleSporty.
  ///
  /// In hu, this message translates to:
  /// **'Sportos'**
  String get avatarStyleSporty;

  /// No description provided for @avatarStyleBusiness.
  ///
  /// In hu, this message translates to:
  /// **'Elegáns'**
  String get avatarStyleBusiness;

  /// No description provided for @avatarStyleParty.
  ///
  /// In hu, this message translates to:
  /// **'Bulis'**
  String get avatarStyleParty;

  /// No description provided for @avatarStyleFestival.
  ///
  /// In hu, this message translates to:
  /// **'Fesztivál'**
  String get avatarStyleFestival;

  /// No description provided for @avatarStyleCozy.
  ///
  /// In hu, this message translates to:
  /// **'Meghitt'**
  String get avatarStyleCozy;

  /// No description provided for @avatarStyleLegendary.
  ///
  /// In hu, this message translates to:
  /// **'Legendás'**
  String get avatarStyleLegendary;

  /// No description provided for @avatarGlassesNone.
  ///
  /// In hu, this message translates to:
  /// **'Szemüveg nélkül'**
  String get avatarGlassesNone;

  /// No description provided for @avatarGlassesRoundGlasses.
  ///
  /// In hu, this message translates to:
  /// **'Kerek szemüveg'**
  String get avatarGlassesRoundGlasses;

  /// No description provided for @avatarGlassesSunglasses.
  ///
  /// In hu, this message translates to:
  /// **'Napszemüveg'**
  String get avatarGlassesSunglasses;

  /// No description provided for @avatarNeckNone.
  ///
  /// In hu, this message translates to:
  /// **'Nyakdísz nélkül'**
  String get avatarNeckNone;

  /// No description provided for @avatarNeckChain.
  ///
  /// In hu, this message translates to:
  /// **'Aranylánc'**
  String get avatarNeckChain;

  /// No description provided for @avatarNeckScarf.
  ///
  /// In hu, this message translates to:
  /// **'Sál'**
  String get avatarNeckScarf;

  /// No description provided for @avatarNeckBow.
  ///
  /// In hu, this message translates to:
  /// **'Csokornyakkendő'**
  String get avatarNeckBow;

  /// No description provided for @avatarHeldNone.
  ///
  /// In hu, this message translates to:
  /// **'Szabad kéz'**
  String get avatarHeldNone;

  /// No description provided for @avatarHeldNotebook.
  ///
  /// In hu, this message translates to:
  /// **'Jegyzetfüzet'**
  String get avatarHeldNotebook;

  /// No description provided for @avatarHeldFlower.
  ///
  /// In hu, this message translates to:
  /// **'Virág'**
  String get avatarHeldFlower;

  /// No description provided for @avatarHeldSparkWand.
  ///
  /// In hu, this message translates to:
  /// **'Csillagpálca'**
  String get avatarHeldSparkWand;

  /// No description provided for @avatarDetailNone.
  ///
  /// In hu, this message translates to:
  /// **'Arcdísz nélkül'**
  String get avatarDetailNone;

  /// No description provided for @avatarDetailFreckles.
  ///
  /// In hu, this message translates to:
  /// **'Szeplők'**
  String get avatarDetailFreckles;

  /// No description provided for @avatarDetailStar.
  ///
  /// In hu, this message translates to:
  /// **'Csillagjel'**
  String get avatarDetailStar;

  /// No description provided for @avatarDetailMoon.
  ///
  /// In hu, this message translates to:
  /// **'Holdjel'**
  String get avatarDetailMoon;

  /// No description provided for @avatarBackNone.
  ///
  /// In hu, this message translates to:
  /// **'Hátidísz nélkül'**
  String get avatarBackNone;

  /// No description provided for @avatarBackBackpack.
  ///
  /// In hu, this message translates to:
  /// **'Hátizsák'**
  String get avatarBackBackpack;

  /// No description provided for @avatarBackCape.
  ///
  /// In hu, this message translates to:
  /// **'Köpeny'**
  String get avatarBackCape;

  /// No description provided for @avatarAccentGold.
  ///
  /// In hu, this message translates to:
  /// **'Arany'**
  String get avatarAccentGold;

  /// No description provided for @avatarAccentViolet.
  ///
  /// In hu, this message translates to:
  /// **'Lila'**
  String get avatarAccentViolet;

  /// No description provided for @avatarAccentBlue.
  ///
  /// In hu, this message translates to:
  /// **'Kék'**
  String get avatarAccentBlue;

  /// No description provided for @avatarAccentMint.
  ///
  /// In hu, this message translates to:
  /// **'Menta'**
  String get avatarAccentMint;

  /// No description provided for @avatarAccentRose.
  ///
  /// In hu, this message translates to:
  /// **'Rózsa'**
  String get avatarAccentRose;

  /// No description provided for @avatarAccentOrange.
  ///
  /// In hu, this message translates to:
  /// **'Narancs'**
  String get avatarAccentOrange;

  /// No description provided for @avatarBackgroundAmber.
  ///
  /// In hu, this message translates to:
  /// **'Borostyán'**
  String get avatarBackgroundAmber;

  /// No description provided for @avatarBackgroundViolet.
  ///
  /// In hu, this message translates to:
  /// **'Lila alkony'**
  String get avatarBackgroundViolet;

  /// No description provided for @avatarBackgroundOcean.
  ///
  /// In hu, this message translates to:
  /// **'Óceán'**
  String get avatarBackgroundOcean;

  /// No description provided for @avatarBackgroundForest.
  ///
  /// In hu, this message translates to:
  /// **'Erdő'**
  String get avatarBackgroundForest;

  /// No description provided for @avatarBackgroundRose.
  ///
  /// In hu, this message translates to:
  /// **'Rózsakert'**
  String get avatarBackgroundRose;

  /// No description provided for @avatarBackgroundMidnight.
  ///
  /// In hu, this message translates to:
  /// **'Éjfél'**
  String get avatarBackgroundMidnight;

  /// No description provided for @avatarAuraSunrise.
  ///
  /// In hu, this message translates to:
  /// **'Napfény'**
  String get avatarAuraSunrise;

  /// No description provided for @avatarAuraViolet.
  ///
  /// In hu, this message translates to:
  /// **'Lila fény'**
  String get avatarAuraViolet;

  /// No description provided for @avatarAuraOcean.
  ///
  /// In hu, this message translates to:
  /// **'Hullám'**
  String get avatarAuraOcean;

  /// No description provided for @avatarAuraForest.
  ///
  /// In hu, this message translates to:
  /// **'Lombok'**
  String get avatarAuraForest;

  /// No description provided for @avatarAuraStarlight.
  ///
  /// In hu, this message translates to:
  /// **'Csillagfény'**
  String get avatarAuraStarlight;

  /// No description provided for @avatarAuraRose.
  ///
  /// In hu, this message translates to:
  /// **'Rózsafény'**
  String get avatarAuraRose;

  /// No description provided for @avatarReactionProud.
  ///
  /// In hu, this message translates to:
  /// **'Büszke'**
  String get avatarReactionProud;

  /// No description provided for @avatarReactionMotivating.
  ///
  /// In hu, this message translates to:
  /// **'Bátorító'**
  String get avatarReactionMotivating;

  /// No description provided for @avatarReactionFunny.
  ///
  /// In hu, this message translates to:
  /// **'Vicces'**
  String get avatarReactionFunny;

  /// No description provided for @avatarReactionSleepy.
  ///
  /// In hu, this message translates to:
  /// **'Álmos'**
  String get avatarReactionSleepy;

  /// No description provided for @avatarReactionCalming.
  ///
  /// In hu, this message translates to:
  /// **'Megnyugtató'**
  String get avatarReactionCalming;

  /// No description provided for @avatarReactionCelebrating.
  ///
  /// In hu, this message translates to:
  /// **'Ünneplő'**
  String get avatarReactionCelebrating;

  /// No description provided for @avatarReactionFocused.
  ///
  /// In hu, this message translates to:
  /// **'Fókuszált'**
  String get avatarReactionFocused;

  /// No description provided for @avatarStudio.
  ///
  /// In hu, this message translates to:
  /// **'Menti Studio 2.2'**
  String get avatarStudio;

  /// No description provided for @avatarSave.
  ///
  /// In hu, this message translates to:
  /// **'Mentés'**
  String get avatarSave;

  /// No description provided for @avatarSaving.
  ///
  /// In hu, this message translates to:
  /// **'Mentés…'**
  String get avatarSaving;

  /// No description provided for @avatarSaved.
  ///
  /// In hu, this message translates to:
  /// **'Az összeállítás elmentve.'**
  String get avatarSaved;

  /// No description provided for @avatarSaveError.
  ///
  /// In hu, this message translates to:
  /// **'A mentést nem sikerült visszaigazolni. Töltsd újra az adatokat.'**
  String get avatarSaveError;

  /// No description provided for @avatarReadError.
  ///
  /// In hu, this message translates to:
  /// **'A profil betöltése vagy mentése nem sikerült. Töltsd újra az adatokat.'**
  String get avatarReadError;

  /// No description provided for @avatarRetry.
  ///
  /// In hu, this message translates to:
  /// **'Újratöltés'**
  String get avatarRetry;

  /// No description provided for @avatarXpUnavailable.
  ///
  /// In hu, this message translates to:
  /// **'Az XP-adatok nem olvashatók. Csak az alap és a korábban feloldott elemek érhetők el.'**
  String get avatarXpUnavailable;

  /// No description provided for @avatarRandom.
  ///
  /// In hu, this message translates to:
  /// **'Véletlen Menti'**
  String get avatarRandom;

  /// No description provided for @avatarRevert.
  ///
  /// In hu, this message translates to:
  /// **'Visszaállítás'**
  String get avatarRevert;

  /// No description provided for @avatarReset.
  ///
  /// In hu, this message translates to:
  /// **'Alap Menti'**
  String get avatarReset;

  /// No description provided for @avatarCancel.
  ///
  /// In hu, this message translates to:
  /// **'Mégse'**
  String get avatarCancel;

  /// No description provided for @avatarPresetName.
  ///
  /// In hu, this message translates to:
  /// **'Összeállítás neve'**
  String get avatarPresetName;

  /// No description provided for @avatarAddPreset.
  ///
  /// In hu, this message translates to:
  /// **'Saját preset mentése'**
  String get avatarAddPreset;

  /// No description provided for @avatarFavorite.
  ///
  /// In hu, this message translates to:
  /// **'Kedvenc összeállítás'**
  String get avatarFavorite;

  /// No description provided for @avatarDuplicate.
  ///
  /// In hu, this message translates to:
  /// **'Másolat készítése'**
  String get avatarDuplicate;

  /// No description provided for @avatarApply.
  ///
  /// In hu, this message translates to:
  /// **'Alkalmazás'**
  String get avatarApply;

  /// No description provided for @avatarNoPresets.
  ///
  /// In hu, this message translates to:
  /// **'Még nincs saját összeállításod.'**
  String get avatarNoPresets;

  /// No description provided for @avatarPresetHint.
  ///
  /// In hu, this message translates to:
  /// **'A kedvencjelölést és a másolatot a Mentés gomb rögzíti.'**
  String get avatarPresetHint;

  /// No description provided for @avatarUnsaved.
  ///
  /// In hu, this message translates to:
  /// **'Nem mentett változtatások'**
  String get avatarUnsaved;

  /// No description provided for @avatarUnsavedBody.
  ///
  /// In hu, this message translates to:
  /// **'A Mentés gombbal megtarthatod az új összeállítást. Elveted most a változtatásokat?'**
  String get avatarUnsavedBody;

  /// No description provided for @avatarDiscard.
  ///
  /// In hu, this message translates to:
  /// **'Változtatások elvetése'**
  String get avatarDiscard;

  /// No description provided for @avatarDefault.
  ///
  /// In hu, this message translates to:
  /// **'Alapból elérhető'**
  String get avatarDefault;

  /// No description provided for @avatarUnlocked.
  ///
  /// In hu, this message translates to:
  /// **'Feloldva'**
  String get avatarUnlocked;

  /// No description provided for @avatarNew.
  ///
  /// In hu, this message translates to:
  /// **'Újonnan megszerzett'**
  String get avatarNew;

  /// No description provided for @avatarTabBasics.
  ///
  /// In hu, this message translates to:
  /// **'Alapok'**
  String get avatarTabBasics;

  /// No description provided for @avatarTabFace.
  ///
  /// In hu, this message translates to:
  /// **'Arc és fej'**
  String get avatarTabFace;

  /// No description provided for @avatarTabOutfit.
  ///
  /// In hu, this message translates to:
  /// **'Ruházat'**
  String get avatarTabOutfit;

  /// No description provided for @avatarTabAccessories.
  ///
  /// In hu, this message translates to:
  /// **'Kiegészítők'**
  String get avatarTabAccessories;

  /// No description provided for @avatarTabAtmosphere.
  ///
  /// In hu, this message translates to:
  /// **'Hangulat'**
  String get avatarTabAtmosphere;

  /// No description provided for @avatarTabPresets.
  ///
  /// In hu, this message translates to:
  /// **'Presetek'**
  String get avatarTabPresets;

  /// No description provided for @avatarFieldFamily.
  ///
  /// In hu, this message translates to:
  /// **'Karaktertípus'**
  String get avatarFieldFamily;

  /// No description provided for @avatarFieldAge.
  ///
  /// In hu, this message translates to:
  /// **'Korosztály'**
  String get avatarFieldAge;

  /// No description provided for @avatarFieldStyle.
  ///
  /// In hu, this message translates to:
  /// **'Stílus'**
  String get avatarFieldStyle;

  /// No description provided for @avatarFieldFace.
  ///
  /// In hu, this message translates to:
  /// **'Arckifejezés'**
  String get avatarFieldFace;

  /// No description provided for @avatarFieldEyes.
  ///
  /// In hu, this message translates to:
  /// **'Szemek'**
  String get avatarFieldEyes;

  /// No description provided for @avatarFieldHair.
  ///
  /// In hu, this message translates to:
  /// **'Haj és fejforma'**
  String get avatarFieldHair;

  /// No description provided for @avatarFieldHeadwear.
  ///
  /// In hu, this message translates to:
  /// **'Fejfedő'**
  String get avatarFieldHeadwear;

  /// No description provided for @avatarFieldOutfit.
  ///
  /// In hu, this message translates to:
  /// **'Ruhaszett'**
  String get avatarFieldOutfit;

  /// No description provided for @avatarFieldAccent.
  ///
  /// In hu, this message translates to:
  /// **'Színkiemelés'**
  String get avatarFieldAccent;

  /// No description provided for @avatarFieldGlasses.
  ///
  /// In hu, this message translates to:
  /// **'Szemüveg'**
  String get avatarFieldGlasses;

  /// No description provided for @avatarFieldNeck.
  ///
  /// In hu, this message translates to:
  /// **'Nyakdísz'**
  String get avatarFieldNeck;

  /// No description provided for @avatarFieldHeld.
  ///
  /// In hu, this message translates to:
  /// **'Kézi kiegészítő'**
  String get avatarFieldHeld;

  /// No description provided for @avatarFieldDetail.
  ///
  /// In hu, this message translates to:
  /// **'Arcdísz'**
  String get avatarFieldDetail;

  /// No description provided for @avatarFieldBack.
  ///
  /// In hu, this message translates to:
  /// **'Hátidísz'**
  String get avatarFieldBack;

  /// No description provided for @avatarFieldBackground.
  ///
  /// In hu, this message translates to:
  /// **'Háttér'**
  String get avatarFieldBackground;

  /// No description provided for @avatarFieldAura.
  ///
  /// In hu, this message translates to:
  /// **'Aura'**
  String get avatarFieldAura;

  /// No description provided for @avatarFieldReaction.
  ///
  /// In hu, this message translates to:
  /// **'Vizuális személyiség'**
  String get avatarFieldReaction;

  /// No description provided for @avatarPreview.
  ///
  /// In hu, this message translates to:
  /// **'Menti-előnézet: {name}'**
  String avatarPreview(String name);

  /// No description provided for @avatarLocked.
  ///
  /// In hu, this message translates to:
  /// **'{level}. szinten nyílik meg'**
  String avatarLocked(int level);

  /// No description provided for @avatarHeadwearCowboy.
  ///
  /// In hu, this message translates to:
  /// **'Cowboykalap'**
  String get avatarHeadwearCowboy;

  /// No description provided for @startLanguage.
  ///
  /// In hu, this message translates to:
  /// **'Szia! Milyen nyelven mentizzünk?'**
  String get startLanguage;

  /// No description provided for @startWelcome.
  ///
  /// In hu, this message translates to:
  /// **'Én vagyok Menti. Kis lépések, saját tempó – és egy kabala, aki veled tart.'**
  String get startWelcome;

  /// No description provided for @startAgeTitle.
  ///
  /// In hu, this message translates to:
  /// **'Előbb egy fontos kérdés'**
  String get startAgeTitle;

  /// No description provided for @startAgeBody.
  ///
  /// In hu, this message translates to:
  /// **'Elmúltál 18 éves? A Menti megjelenésének korosztálya ettől független. 18 év alatt csak az életmód- és karakterfunkciók érhetők el.'**
  String get startAgeBody;

  /// No description provided for @startAdult.
  ///
  /// In hu, this message translates to:
  /// **'Betöltöttem a 18. életévemet'**
  String get startAdult;

  /// No description provided for @startMinor.
  ///
  /// In hu, this message translates to:
  /// **'Még nem vagyok 18 éves'**
  String get startMinor;

  /// No description provided for @startLocalOnly.
  ///
  /// In hu, this message translates to:
  /// **'Ez helyi életkori nyilatkozat, nem személyazonosítás. A profil ezen az eszközön tárolódik; nincs fiókregisztráció.'**
  String get startLocalOnly;

  /// No description provided for @startCharacter.
  ///
  /// In hu, this message translates to:
  /// **'Jöhet a saját Mentid!'**
  String get startCharacter;

  /// No description provided for @startName.
  ///
  /// In hu, this message translates to:
  /// **'Becenév'**
  String get startName;

  /// No description provided for @startNameBody.
  ///
  /// In hu, this message translates to:
  /// **'Hogy szólíthatlak? A Mentidet később is átöltöztetheted a Studióban.'**
  String get startNameBody;

  /// No description provided for @startFinish.
  ///
  /// In hu, this message translates to:
  /// **'Mentés és indulás'**
  String get startFinish;

  /// No description provided for @startSaveError.
  ///
  /// In hu, this message translates to:
  /// **'Nem sikerült biztonságosan befejezni. Az adataid megmaradtak; próbáld újra. Sérült profil esetén állítsd helyre a mentést.'**
  String get startSaveError;
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
