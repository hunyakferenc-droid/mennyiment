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

  @override
  String get dailyOpen => 'Mai tudatos pillanat  •  +10 XP';

  @override
  String get dailyOpenSaved => 'Mai önellenőrzés és esti összegzés ✓';

  @override
  String get dailyTitle => 'Egy pillanat magadra';

  @override
  String get dailyMorning => 'Jó reggelt!';

  @override
  String get dailyAfternoon => 'Szép napot!';

  @override
  String get dailyEveningGreeting => 'Szép estét!';

  @override
  String dailyGreeting(String greeting, String name) {
    return '$greeting $name veled van.';
  }

  @override
  String get dailyOptional =>
      'Minden válasz opcionális. Italnapló nélkül is menthetsz. A kihagyott napokért nincs büntetés.';

  @override
  String get dailyWelcome =>
      'Örülök, hogy itt vagy. Ma is a saját tempódban haladhatsz.';

  @override
  String get dailySupportLow =>
      'Ma nehezebbnek érzed? Egy kis pihenő vagy beszélgetés is segíthet. Nem kell mindent ma megoldanod.';

  @override
  String get dailySupportMid =>
      'Köszönöm, hogy figyelsz magadra. Egy apró, kényelmes lépés is számít.';

  @override
  String get dailySupportHigh =>
      'Jó hallani, hogy jól érzed magad! Mi lenne egy kedves apróság ma magadért?';

  @override
  String get dailyMood => 'Milyen most a hangulatod?';

  @override
  String get dailyEnergy => 'Mennyi energiád van most?';

  @override
  String get dailyScale => '1 = nagyon alacsony, 5 = nagyon magas';

  @override
  String get dailySkip => 'Kihagyom';

  @override
  String get dailyGoal => 'Mai személyes cél (opcionális)';

  @override
  String get dailyGoalHint => 'Például: egy rövid séta vagy pihenő';

  @override
  String get dailyEvening => 'Esti összegzés (opcionális)';

  @override
  String get dailyEveningHint => 'Mi esett ma jól? Mit vinnél tovább holnapra?';

  @override
  String get dailyReward =>
      'Az önellenőrzésért naponta egyszer +10 XP jár. A válaszok kihagyhatók.';

  @override
  String get dailyRewardDone =>
      'A mai önellenőrzés XP-jét már megkaptad. Szabadon frissítheted a válaszokat.';

  @override
  String get dailySave => 'Önellenőrzés mentése';

  @override
  String get dailySaved =>
      'Önellenőrzés mentve. A napi jutalmat csak egyszer számoljuk el.';

  @override
  String get dailyLater => 'Most kihagyom';

  @override
  String get dailyLoadError =>
      'Nem sikerült biztonságosan betölteni a napi adatokat. Nem írtuk felül őket.';

  @override
  String get dailySaveError =>
      'A mentés nem fejeződött be. Próbáld újra; a napi XP nem duplázódik.';

  @override
  String get dailyRetry => 'Újrapróbálás';

  @override
  String get evolutionTitle => 'Menti fejlődése';

  @override
  String evolutionLevel(int level) {
    return '$level. szint';
  }

  @override
  String evolutionRemaining(int xp) {
    return 'Még $xp XP a következő szintig';
  }

  @override
  String evolutionTotal(int xp) {
    return 'Összesen $xp XP';
  }

  @override
  String get evolutionNext => 'Következő jutalom';

  @override
  String get evolutionAll =>
      'Minden jelenlegi ruhajutalom megszerezve. Haladj a saját tempódban!';

  @override
  String evolutionUnlock(int level, int xp) {
    return '$level. szint • még $xp XP';
  }

  @override
  String get evolutionDaily => 'Napi tudatos önellenőrzés';

  @override
  String get evolutionDailyHint =>
      'Gondold át a napodat. Naponta egyszer +10 XP, a kezdőlappal közösen.';

  @override
  String get evolutionChecked => 'Mai önellenőrzés kész';

  @override
  String get evolutionCheck => 'Átgondoltam a napomat';

  @override
  String get evolutionWeekly => 'Heti tudatos lépések';

  @override
  String get evolutionWeeklyHint =>
      'Önjelölés alapján, hetente egyszer. A lehetőségek hétfőn újulnak meg.';

  @override
  String get evolutionReview => 'Átnéztem a naplómat';

  @override
  String get evolutionCost => 'Átgondoltam a költéseimet';

  @override
  String get evolutionGoal => 'Kijelöltem egy személyes célt';

  @override
  String get evolutionDone => 'Kész';

  @override
  String evolutionPoints(int xp) {
    return '+$xp XP • hetente egyszer';
  }

  @override
  String get evolutionBadges => 'Teljesítményjelvények';

  @override
  String get evolutionReflectionBadge => 'Tudatos önellenőrzés • 1 külön nap';

  @override
  String get evolutionGoalBadge => 'Személyes cél • 1 heti cél kijelölése';

  @override
  String get evolutionConsistencyBadge =>
      'Következetesség • 7 külön nap, megszakítás megengedett';

  @override
  String get evolutionEarned => 'Megszerzett';

  @override
  String get evolutionLocked => 'Még elérhető';

  @override
  String evolutionWeek(int days, int tasks) {
    return 'Ezen a héten: $days önellenőrzés • $tasks tudatos lépés';
  }

  @override
  String get evolutionPolicy =>
      'Az alkoholmennyiség és a költés összege nem ad XP-t. Nincs negatív XP vagy büntetés kihagyott napért. A jelvényekért nem jár külön XP; nem mérnek egészségi állapotot vagy alkoholmentességet.';

  @override
  String get evolutionError =>
      'A fejlődés nem tölthető be vagy menthető. Próbáld újra.';

  @override
  String get evolutionRetry => 'Újrapróbálás';

  @override
  String evolutionSaved(int xp) {
    return 'Mentve • +$xp XP';
  }

  @override
  String get evolutionWardrobe => 'Gardrób megnyitása';

  @override
  String get evolutionBasic => 'Alap szett';

  @override
  String get evolutionParty => 'Buli szett';

  @override
  String get evolutionSport => 'Sport szett';

  @override
  String get evolutionBusiness => 'Üzleti szett';

  @override
  String get evolutionFestival => 'Fesztivál szett';

  @override
  String get evolutionLegendary => 'Legendás szett';

  @override
  String get evolutionImage => 'Az előnézet jelenleg nem érhető el';

  @override
  String get evolutionRules =>
      'Feloldás: Alap, Buli és Sport az 1., Üzleti a 2., Fesztivál a 3., Legendás az 5. szinten. A megszerzett ruhák megmaradnak.';

  @override
  String get challengeSaveError => 'A mentés nem sikerült. Próbáld újra.';

  @override
  String get challengeCustom => 'Saját heti cél';

  @override
  String get challengeDaysPerWeek => 'Heti napok száma';

  @override
  String get challengeCancel => 'Mégse';

  @override
  String get challengeSave => 'Mentés';

  @override
  String get challengeReflection => 'Tudatos önellenőrzés';

  @override
  String get challengeJournal => 'Következetes közérzetnapló';

  @override
  String get challengeHabit => 'Tudatos szokás: rövid napi szünet';

  @override
  String get challengeTitle => 'Heti személyes kihívások';

  @override
  String get challengeOptional =>
      'A saját tempódban. Minden kihívás választható, kihagyható vagy megszakítható büntetés nélkül. Nincs XP-jutalom vagy levonás.';

  @override
  String get challengePrevious => 'Előző hét';

  @override
  String get challengeNext => 'Következő hét';

  @override
  String get challengeLoadError =>
      'Az adatok nem olvashatók. Nem írjuk felül őket.';

  @override
  String get challengeRetry => 'Újrapróbálás';

  @override
  String get challengeDays => 'nap';

  @override
  String get challengeSkipped => 'Kihagyva – nincs büntetés.';

  @override
  String get challengeStopped => 'Megszakítva – nincs büntetés.';

  @override
  String get challengeJournalHint =>
      'A mentett közérzetnapló napjai számítanak. Ital rögzítése nem szükséges.';

  @override
  String get challengeChoose => 'Kiválasztás';

  @override
  String get challengeEdit => 'Cél módosítása';

  @override
  String get challengeDoneToday => 'Ma megtettem';

  @override
  String get challengeSkip => 'Ezen a héten kihagyom';

  @override
  String get challengeStop => 'Megszakítás';

  @override
  String get challengeSummary => 'Heti fejlődési összefoglaló';

  @override
  String get challengeJournalDays => 'Közérzetnaplóval kitöltött napok';

  @override
  String get challengeCaution =>
      'A hiányzó bejegyzés ismeretlen adat, nem alkoholmentes nap. Ezek a kihívások nem jelölnek alkoholmentességet. A cél módosítása csak a kiválasztott hetet érinti; a korábbi napok megmaradnak.';

  @override
  String get challengeRefresh => 'Összefoglaló frissítése';

  @override
  String get backupTitle => 'Adatmentés és visszaállítás';

  @override
  String get backupContents =>
      'A mentés tartalmazza az összes helyi naplót, a Reggeli Menti válaszait, az XP-t és előzményeit, a tartós ruhafeloldásokat, heti kihívásokat, karaktereket, célokat és beállításokat, az újabb alkalmazáskulcsokkal együtt.';

  @override
  String get backupPrivacy =>
      'A fájl nincs titkosítva, személyes adatokat tartalmaz. Csak biztonságos helyre mentsd. Az alkalmazás nem küldi automatikusan hálózatra; a fájl helyéről és megosztásáról te döntesz.';

  @override
  String get backupRestoreDeferred =>
      'Visszaállítás előtt válassz mentést az ellenőrzött előnézethez. Csak kifejezett megerősítésed után módosítunk adatokat.';

  @override
  String get backupPrepare => 'Mentés előkészítése';

  @override
  String get backupWorking => 'Folyamatban…';

  @override
  String get backupPreview => 'Előkészített mentés';

  @override
  String backupCreated(String date) {
    return 'Készült: $date';
  }

  @override
  String backupSize(String size) {
    return 'Méret: $size bájt';
  }

  @override
  String get backupValidated =>
      'A fájl szerkezete ellenőrizve. Ez nem igazolja minden régi bejegyzés érvényességét.';

  @override
  String get backupSave => 'Mentés fájlba';

  @override
  String get backupSaved => 'A fájl mentése befejeződött.';

  @override
  String get backupCancelled =>
      'A fájlmentést megszakítottad. Az alkalmazás adatai változatlanok.';

  @override
  String get backupDownloadRequested =>
      'A letöltési kérést átadtuk a böngészőnek. Ellenőrizd a letöltéseket és a fájl meglétét.';

  @override
  String get backupPrepareError =>
      'Nem készült mentés. Az adatok változhattak, nem olvashatók, vagy túllépik a támogatott méretet. Próbáld újra; a helyi adatok változatlanok.';

  @override
  String get backupSaveError =>
      'A fájlmentés nem sikerült. Ellenőrizd a célhelyet, és próbáld újra. A helyi adatok változatlanok.';

  @override
  String get restorePick => 'Mentés kiválasztása visszaállításhoz';

  @override
  String get restoreHint =>
      'A visszaállítás csak a fájlban szereplő kulcsokat adja hozzá vagy írja felül. A többi helyi adat megmarad. A tartós ruhafeloldásokat egyesítjük. Megerősítés előtt nézd át az alábbi kulcsokat.';

  @override
  String get restorePreview => 'Visszaállítási előnézet';

  @override
  String restoreCounts(int added, int replaced, int unchanged) {
    return '$added új, $replaced felülírt, $unchanged változatlan kulcs';
  }

  @override
  String get restoreConfirm => 'Ezeknek az adatoknak a visszaállítása';

  @override
  String get restoreQuestion => 'Visszaállítod az átnézett mentést?';

  @override
  String get restoreWarning =>
      'A felsorolt adatokat erre az eszközre írjuk. Az érintett kulcsok meglévő értékeit felülírjuk. Folytatod?';

  @override
  String get restoreCancel => 'Mégse';

  @override
  String get restoreInvalid =>
      'A mentés hibás, nem támogatott, túl nagy vagy nem olvasható. Nem írtunk felhasználói adatot.';

  @override
  String get restoreFailed =>
      'A visszaállítás nem sikerült. Az eredeti adatokat helyreállítottuk. Újrapróbálás előtt készíts új előnézetet.';

  @override
  String get restoreRecovery =>
      'A helyreállítás még nem teljes. Az eredeti adatok helyreállításáig a szerkesztést letiltottuk. Őrizd meg az alkalmazás helyi adatait, és próbáld újra.';

  @override
  String get restoreRetry => 'Helyreállítás újrapróbálása';

  @override
  String get restoreSuccess => 'Az adatokat visszaállítottuk.';

  @override
  String get restoreStale =>
      'A helyi adatok megváltoztak vagy a tároló nem elérhető. Nem történt sikeres visszaállítás. Válaszd ki újra a fájlt.';

  @override
  String get homeEyebrow => 'MENNYIMENT? • A TE MENTID';

  @override
  String get homeGreeting => 'Szia! Hogy vagy ma?';

  @override
  String get homeIntro => 'A mai tudatos döntéseid számítanak.';

  @override
  String get homeMentiHint => 'Apró, tudatos lépésekből épül a fejlődés.';

  @override
  String homeTotalXp(int xp) {
    return '$xp XP összesen';
  }

  @override
  String get homeLevelProgress => 'Haladás a következő Menti-szintig';

  @override
  String get homeXpHint =>
      'Az XP önellenőrzésért és tudatos heti kihívásokért jár, nem az elfogyasztott italokért.';

  @override
  String get homeTodayDrinks => 'Ma rögzített ital';

  @override
  String get homeTodaySpending => 'Mai ismert költés';

  @override
  String get homeMonthSpending => 'Havi ismert költés';

  @override
  String get homeWeekDays => 'Heti naplózott nap';

  @override
  String homeMissingPrices(int today, int month) {
    return 'Hiányzó italárak: ma $today, ebben a hónapban $month. A költések részösszegek.';
  }

  @override
  String get homeEmptyJournal =>
      'Még nincs bejegyzés. Az első italodat a hozzáadás gombbal rögzítheted.';

  @override
  String get homeUnknownPrice => 'Ismeretlen ár';

  @override
  String get homeJournalUnavailable =>
      'A napló adatai most nem érhetők el. Az eredeti adatokat megőriztük.';

  @override
  String get homeJournalRetry => 'Napló újratöltése';

  @override
  String get homeLoading => 'Napló betöltése…';

  @override
  String get homeRecordActions => 'Bejegyzés műveletei';

  @override
  String get homeEnterPrice => 'Ár megadása';

  @override
  String homeEditPrice(String price) {
    return 'Ár: $price – szerkesztés';
  }

  @override
  String get homeDeleteEntry => 'Bejegyzés törlése';

  @override
  String get homeCheckInUnavailable =>
      'A Menti-előrehaladás most nem tölthető be. Próbáld újra.';

  @override
  String get homeRetryProgress => 'Menti újratöltése';

  @override
  String get homeJournalSaveError =>
      'A napló mentése nem sikerült. A módosítást nem alkalmaztuk. Próbáld újra vagy töltsd be újra a naplót.';

  @override
  String get homeJournalLoadError =>
      'A napló nem tölthető be biztonságosan. Az eredeti adatokat megőriztük; a módosításokat letiltottuk.';

  @override
  String get goalPageTitle => 'Személyes céljaim';

  @override
  String get goalOwnPace => 'A saját tempódban';

  @override
  String get goalIntro =>
      'Itt te döntöd el, mit szeretnél követni. A tudatos átgondolás számít, nem az elfogyasztott italok száma.';

  @override
  String get goalBudgetTitle => 'Heti ital-költségkeret';

  @override
  String goalRecordedSpending(String amount) {
    return 'Rögzített költés: $amount';
  }

  @override
  String get goalNoBudget => 'Még nincs keret beállítva.';

  @override
  String goalBudgetValue(String amount) {
    return 'Saját heti keret: $amount';
  }

  @override
  String goalMissingPrices(int count) {
    return '$count ital ára hiányzik. A költés csak részösszeg, így a keret teljesítése nem igazolható.';
  }

  @override
  String get goalOverBudget => 'A rögzített költés meghaladja a keretet.';

  @override
  String get goalWithinBudget =>
      'A rögzített költés a kereten belül van. Ez nem igazolja a teljes heti költést.';

  @override
  String get goalEditBudget => 'Keret szerkesztése';

  @override
  String get goalReflectionTitle => 'Heti tudatos önellenőrzés';

  @override
  String goalProgress(int count, int target) {
    return '$count / $target alkalom';
  }

  @override
  String get goalCheckDone => 'Mai önellenőrzés kész';

  @override
  String get goalCheckAction => 'Ma átgondoltam a napomat';

  @override
  String get goalCurrentWeekOnly => 'Csak az aktuális héten rögzíthető';

  @override
  String get goalEditTarget => 'Heti cél módosítása';

  @override
  String get goalMentiThought => 'Menti gondolata';

  @override
  String get goalThoughtComplete =>
      'A rögzített önellenőrzéseid alapján teljesítetted a heti célodat.';

  @override
  String get goalThoughtStart =>
      'Nem kell tökéletes nap. Egy rövid átgondolás is jó kezdet.';

  @override
  String goalThoughtProgress(int count) {
    return 'Már $count alkalommal megálltál átgondolni a napodat. Haladj a saját tempódban!';
  }

  @override
  String get goalCaution =>
      'A hiányzó naplóbejegyzés nem bizonyít alkoholmentes napot. A költések önbevalláson alapulnak. Ez az önellenőrzés nem ad külön XP-t.';

  @override
  String get goalBudgetDialog => 'Heti ital-költségkeret (Ft)';

  @override
  String get goalTargetDialog => 'Heti önellenőrzések célja';

  @override
  String get goalBudgetHint => 'Például 10000';

  @override
  String get goalTargetHint => '1–7 nap';

  @override
  String get goalBudgetHelp => 'A nullás keret is megengedett.';

  @override
  String get goalTargetHelp => 'Naponta legfeljebb egy önellenőrzés.';

  @override
  String get goalInvalidValue => 'Érvénytelen célérték.';

  @override
  String get goalLoadError =>
      'A célok nem tölthetők be biztonságosan. Az eredeti adatok megmaradtak, a módosítások letiltva.';

  @override
  String get goalSaveError =>
      'A célok mentése nem sikerült. A felület nem jelöli teljesítettnek a módosítást. Töltsd újra az adatokat, majd próbáld újra.';

  @override
  String get goalReload => 'Célok újratöltése';

  @override
  String get hubTitle => 'Saját Menti • Áttekintés';

  @override
  String get hubIntro =>
      'A rögzített adataid egy helyen. A hiányzó bejegyzés nem jelent alkoholmentes napot.';

  @override
  String get hubProfile => 'Karakter és ruha';

  @override
  String get hubXp => 'Menti-előrehaladás';

  @override
  String get hubDaily => 'Mai önellenőrzés';

  @override
  String get hubGoals => 'Személyes heti cél';

  @override
  String get hubChallenges => 'Külön heti kihívások';

  @override
  String get hubJournal => 'Heti italnapló és költés';

  @override
  String get hubMissing => 'Menti itt még nem lát mentett adatot.';

  @override
  String get hubReadError =>
      'Ez az adat nem olvasható megbízhatóan. Nem helyettesítettük alapértékkel.';

  @override
  String get hubGlobalError =>
      'Az áttekintő nem tölthető be. Az eredeti adatokat nem módosítottuk.';

  @override
  String get hubRefresh => 'Áttekintő frissítése';

  @override
  String hubUpdated(String date) {
    return 'Pillanatkép: $date';
  }

  @override
  String hubWeek(String start, String end) {
    return 'Aktuális hét: $start – $end';
  }

  @override
  String get hubDailyAnswers => 'A mai napi válaszok rögzítve.';

  @override
  String get hubNoDailyAnswers =>
      'Nincs rögzített mai válasz a napi bejegyzésben.';

  @override
  String get hubXpToday => 'A mai XP-önellenőrzés rögzítve.';

  @override
  String get hubNoXpToday => 'Ebben az XP-naplóban nincs mai önellenőrzés.';

  @override
  String hubWeekChecks(int count) {
    return 'Naplózott napi XP-önellenőrzés: $count';
  }

  @override
  String get hubNoTarget => 'Nincs mentett személyes célszám.';

  @override
  String get hubNoCheckDays => 'Nincs mentett önellenőrzési naplista.';

  @override
  String get hubGoalConfirmed =>
      'A rögzített önellenőrzések alapján a cél teljesült.';

  @override
  String get hubGoalOngoing =>
      'A rögzített önellenőrzések alapján a cél még nincs teljesítve.';

  @override
  String get hubNoChallenges => 'Erre a hétre nincs választott kihívás.';

  @override
  String get hubEvidenceMissing =>
      'A teljesítéshez szükséges naplóadat hiányzik vagy nem olvasható.';

  @override
  String get hubRecordedEmpty =>
      'A mentett naplóban ezen a héten 0 bejegyzés van. Ez nem igazol alkoholmentes napokat.';

  @override
  String get hubKnownZero =>
      'Az ismert árak rögzített összege 0. Az ismeretlen árak nem számítanak nullának.';

  @override
  String get hubOutfitBasic => 'Alap szett';

  @override
  String get hubOutfitParty => 'Buli szett';

  @override
  String get hubOutfitSport => 'Sport szett';

  @override
  String get hubOutfitBusiness => 'Üzleti szett';

  @override
  String get hubOutfitFestival => 'Fesztivál szett';

  @override
  String get hubOutfitLegendary => 'Legendás szett';

  @override
  String get hubFamilyBoy => 'Fiú Menti';

  @override
  String get hubFamilyGirl => 'Lány Menti';

  @override
  String get hubFamilyNeutral => 'Semleges Menti';

  @override
  String get hubImageError =>
      'A kiválasztott karakter képe nem jeleníthető meg.';

  @override
  String get reactionTitle => 'Menti üzenete';

  @override
  String get hubOverview => 'Áttekintés';

  @override
  String get experienceSettings => 'Beállítások és súgó';

  @override
  String get experienceIntroTitle => 'Ismerd meg Mentit';

  @override
  String get experienceIntroInvite =>
      'Új társ a naplód mellé. Megismered Mentit?';

  @override
  String get experienceIntroOpen => 'Menti bemutatkozása';

  @override
  String get experienceIntroSkip => 'Átugrás';

  @override
  String get experienceIntroNext => 'Tovább';

  @override
  String get experienceIntroBack => 'Előző';

  @override
  String get experienceIntroDone => 'Nézzük a naplómat';

  @override
  String experienceIntroStep(int step, int total) {
    return '$step / $total lépés';
  }

  @override
  String get experienceIntro1Title => 'Szia, Menti vagyok!';

  @override
  String get experienceIntro1Body =>
      'Narancssárga társad az önmegfigyelésben. Te döntesz a tempóról, a karakterről és a ruháról. Nincs kötelező regisztráció.';

  @override
  String get experienceIntro2Title => 'A napló a tiéd';

  @override
  String get experienceIntro2Body =>
      'Rögzíthetsz italokat és ismert árakat, majd megnézheted az összesítéseket. A hiányzó bejegyzés nem bizonyít alkoholmentes napot, az ismeretlen ár pedig nem nulla.';

  @override
  String get experienceIntro3Title => 'Egy perc magadra';

  @override
  String get experienceIntro3Body =>
      'A napi Menti és a saját céljaid a tudatos átgondolásról szólnak. Az XP a meglévő önellenőrzésekhez és feladatokhoz kapcsolódik, nem az italok mennyiségéhez.';

  @override
  String get experienceIntro4Title => 'Adataid és mentéseid';

  @override
  String get experienceIntro4Body =>
      'A napló helyi tárhelyet használ. A mentést és visszaállítást te indítod. Az exportált fájl személyes adatokat tartalmazhat és nem titkosított; kezeld bizalmasan. Ez az app nem állapítja meg a józanságot vagy a vezetési képességet.';

  @override
  String get experienceReactions => 'Menti-üzenetek és reakciók';

  @override
  String get experienceReactionsHint =>
      'A kikapcsolás csak a megjelenítést érinti. Az XP és a céljaid változatlanok.';

  @override
  String get experienceLoadError =>
      'A megjelenítési beállítás nem olvasható biztonságosan. Az eredeti értéket megőriztük.';

  @override
  String get experienceSaveError =>
      'A beállítás mentését nem sikerült igazolni. Az előző állapot maradt érvényben; töltsd újra, majd próbáld ismét.';

  @override
  String get experienceReload => 'Beállítások újratöltése';

  @override
  String get experienceMotionTitle => 'Menti mozgásának csökkentése';

  @override
  String get experienceMotionHint =>
      'Állókép a lebegés, billegés és reakcióanimáció helyett.';

  @override
  String get experienceMotionSystem =>
      'A rendszer mozgáscsökkentése aktív. Ezt a kapcsoló nem írja felül.';

  @override
  String get experienceMotionLoadError => 'A mozgásbeállítás nem tölthető be.';

  @override
  String get experienceMotionSaveError =>
      'A mozgásbeállítás nem menthető. Próbáld újra.';

  @override
  String get experienceToday => 'Ma Mentivel';

  @override
  String get experienceTodayStart1 =>
      'Egy perc magadra? Menti figyel, a napló megvár.';

  @override
  String get experienceTodayStart2 =>
      'A saját tempód jó tempó. Egy rövid önellenőrzés is elég lehet mára.';

  @override
  String get experienceTodayAnswers =>
      'A mai válaszaid elmentve. Menti füzetében ez már megvan.';

  @override
  String get experienceTodayChecked =>
      'A mai önellenőrzés rögzítve. Menti képzeletben bólint.';

  @override
  String get experienceTodayGoal =>
      'A rögzített napok szerint a heti önellenőrzési célod teljesült. Szép, tudatos lépések!';

  @override
  String get experienceTodayChallenge =>
      'A rögzített adatok szerint van teljesített heti kihívásod. Menti megemeli a sapkáját.';

  @override
  String get experienceTodayUnknown =>
      'Most nem minden adat olvasható. Menti nem találgat; az áttekintőben újrapróbálhatod.';

  @override
  String get experienceOpenDaily => 'Napi Menti megnyitása';

  @override
  String get experienceOpenHub => 'Áttekintés megnyitása';

  @override
  String get experienceEmptyJournal =>
      'Menti füzetében még nincs bejegyzés. Akkor naplózz, amikor neked hasznos.';

  @override
  String get experienceAddEntry => 'Bejegyzés rögzítése';

  @override
  String get experienceTodayLoading => 'Menti megnézi a mai rögzítéseket…';

  @override
  String get avatarFamilyBoy => 'Fiú';

  @override
  String get avatarFamilyGirl => 'Lány';

  @override
  String get avatarFamilyNeutral => 'Semleges';

  @override
  String get avatarAgeYoung => 'Fiatalos';

  @override
  String get avatarAgeAdult => 'Felnőttes';

  @override
  String get avatarAgeVeteran => 'Veterán';

  @override
  String get avatarFaceCheerful => 'Vidám';

  @override
  String get avatarFaceCalm => 'Nyugodt';

  @override
  String get avatarFacePlayful => 'Játékos';

  @override
  String get avatarFaceConfident => 'Magabiztos';

  @override
  String get avatarFaceSleepy => 'Álmos';

  @override
  String get avatarFaceDetermined => 'Elszánt';

  @override
  String get avatarEyesRound => 'Kerek';

  @override
  String get avatarEyesWide => 'Tágra nyílt';

  @override
  String get avatarEyesRelaxed => 'Laza';

  @override
  String get avatarEyesSharp => 'Éles tekintet';

  @override
  String get avatarHairBoyCrop => 'Rövid';

  @override
  String get avatarHairBoyWaves => 'Hullámos';

  @override
  String get avatarHairBoyCurls => 'Göndör';

  @override
  String get avatarHairBoyBraid => 'Fonott';

  @override
  String get avatarHairBoyBob => 'Bob';

  @override
  String get avatarHairBoyCrest => 'Taréj';

  @override
  String get avatarHairGirlCrop => 'Rövid';

  @override
  String get avatarHairGirlWaves => 'Hullámos';

  @override
  String get avatarHairGirlCurls => 'Göndör';

  @override
  String get avatarHairGirlBraid => 'Fonott';

  @override
  String get avatarHairGirlBob => 'Bob';

  @override
  String get avatarHairGirlCrest => 'Taréj';

  @override
  String get avatarHairNeutralCrop => 'Rövid';

  @override
  String get avatarHairNeutralWaves => 'Hullámos';

  @override
  String get avatarHairNeutralCurls => 'Göndör';

  @override
  String get avatarHairNeutralBraid => 'Fonott';

  @override
  String get avatarHairNeutralBob => 'Bob';

  @override
  String get avatarHairNeutralCrest => 'Taréj';

  @override
  String get avatarHeadwearCrownCap => 'Koronás sapka';

  @override
  String get avatarHeadwearSportCap => 'Sportsapka';

  @override
  String get avatarHeadwearBeanie => 'Kötött sapka';

  @override
  String get avatarHeadwearHeadphones => 'Fejhallgató';

  @override
  String get avatarHeadwearPartyCrown => 'Ünnepi korona';

  @override
  String get avatarHeadwearHood => 'Kapucni';

  @override
  String get avatarHeadwearNone => 'Fejfedő nélkül';

  @override
  String get avatarHeadwearPartyHat => 'Csúcsos kalap';

  @override
  String get avatarHeadwearBeret => 'Barett';

  @override
  String get avatarOutfitBasic => 'Alap szett';

  @override
  String get avatarOutfitBasicAlt => 'Alap szett · extra';

  @override
  String get avatarOutfitParty => 'Buli';

  @override
  String get avatarOutfitPartyAlt => 'Buli · extra';

  @override
  String get avatarOutfitSport => 'Sport';

  @override
  String get avatarOutfitSportAlt => 'Sport · extra';

  @override
  String get avatarOutfitBusiness => 'Üzleti';

  @override
  String get avatarOutfitBusinessAlt => 'Üzleti · extra';

  @override
  String get avatarOutfitFestival => 'Fesztivál';

  @override
  String get avatarOutfitFestivalAlt => 'Fesztivál · extra';

  @override
  String get avatarOutfitLegendary => 'Legendás';

  @override
  String get avatarOutfitLegendaryAlt => 'Legendás · extra';

  @override
  String get avatarOutfitStreet => 'Utcai';

  @override
  String get avatarOutfitStreetAlt => 'Utcai · extra';

  @override
  String get avatarOutfitCozy => 'Kuckózós';

  @override
  String get avatarOutfitCozyAlt => 'Kuckózós · extra';

  @override
  String get avatarOutfitExplorer => 'Felfedező';

  @override
  String get avatarOutfitExplorerAlt => 'Felfedező · extra';

  @override
  String get avatarOutfitCreative => 'Alkotó';

  @override
  String get avatarOutfitCreativeAlt => 'Alkotó · extra';

  @override
  String get avatarStyleClassic => 'Klasszikus';

  @override
  String get avatarStyleStreet => 'Utcai';

  @override
  String get avatarStyleSporty => 'Sportos';

  @override
  String get avatarStyleBusiness => 'Elegáns';

  @override
  String get avatarStyleParty => 'Bulis';

  @override
  String get avatarStyleFestival => 'Fesztivál';

  @override
  String get avatarStyleCozy => 'Meghitt';

  @override
  String get avatarStyleLegendary => 'Legendás';

  @override
  String get avatarGlassesNone => 'Szemüveg nélkül';

  @override
  String get avatarGlassesRoundGlasses => 'Kerek szemüveg';

  @override
  String get avatarGlassesSunglasses => 'Napszemüveg';

  @override
  String get avatarNeckNone => 'Nyakdísz nélkül';

  @override
  String get avatarNeckChain => 'Aranylánc';

  @override
  String get avatarNeckScarf => 'Sál';

  @override
  String get avatarNeckBow => 'Csokornyakkendő';

  @override
  String get avatarHeldNone => 'Szabad kéz';

  @override
  String get avatarHeldNotebook => 'Jegyzetfüzet';

  @override
  String get avatarHeldFlower => 'Virág';

  @override
  String get avatarHeldSparkWand => 'Csillagpálca';

  @override
  String get avatarDetailNone => 'Arcdísz nélkül';

  @override
  String get avatarDetailFreckles => 'Szeplők';

  @override
  String get avatarDetailStar => 'Csillagjel';

  @override
  String get avatarDetailMoon => 'Holdjel';

  @override
  String get avatarBackNone => 'Hátidísz nélkül';

  @override
  String get avatarBackBackpack => 'Hátizsák';

  @override
  String get avatarBackCape => 'Köpeny';

  @override
  String get avatarAccentGold => 'Arany';

  @override
  String get avatarAccentViolet => 'Lila';

  @override
  String get avatarAccentBlue => 'Kék';

  @override
  String get avatarAccentMint => 'Menta';

  @override
  String get avatarAccentRose => 'Rózsa';

  @override
  String get avatarAccentOrange => 'Narancs';

  @override
  String get avatarBackgroundAmber => 'Borostyán';

  @override
  String get avatarBackgroundViolet => 'Lila alkony';

  @override
  String get avatarBackgroundOcean => 'Óceán';

  @override
  String get avatarBackgroundForest => 'Erdő';

  @override
  String get avatarBackgroundRose => 'Rózsakert';

  @override
  String get avatarBackgroundMidnight => 'Éjfél';

  @override
  String get avatarAuraSunrise => 'Napfény';

  @override
  String get avatarAuraViolet => 'Lila fény';

  @override
  String get avatarAuraOcean => 'Hullám';

  @override
  String get avatarAuraForest => 'Lombok';

  @override
  String get avatarAuraStarlight => 'Csillagfény';

  @override
  String get avatarAuraRose => 'Rózsafény';

  @override
  String get avatarReactionProud => 'Büszke';

  @override
  String get avatarReactionMotivating => 'Bátorító';

  @override
  String get avatarReactionFunny => 'Vicces';

  @override
  String get avatarReactionSleepy => 'Álmos';

  @override
  String get avatarReactionCalming => 'Megnyugtató';

  @override
  String get avatarReactionCelebrating => 'Ünneplő';

  @override
  String get avatarReactionFocused => 'Fókuszált';

  @override
  String get avatarStudio => 'Menti Studio 2.2';

  @override
  String get avatarSave => 'Mentés';

  @override
  String get avatarSaving => 'Mentés…';

  @override
  String get avatarSaved => 'Az összeállítás elmentve.';

  @override
  String get avatarSaveError =>
      'A mentést nem sikerült visszaigazolni. Töltsd újra az adatokat.';

  @override
  String get avatarReadError =>
      'A profil betöltése vagy mentése nem sikerült. Töltsd újra az adatokat.';

  @override
  String get avatarRetry => 'Újratöltés';

  @override
  String get avatarXpUnavailable =>
      'Az XP-adatok nem olvashatók. Csak az alap és a korábban feloldott elemek érhetők el.';

  @override
  String get avatarRandom => 'Véletlen Menti';

  @override
  String get avatarRevert => 'Visszaállítás';

  @override
  String get avatarReset => 'Alap Menti';

  @override
  String get avatarCancel => 'Mégse';

  @override
  String get avatarPresetName => 'Összeállítás neve';

  @override
  String get avatarAddPreset => 'Saját preset mentése';

  @override
  String get avatarFavorite => 'Kedvenc összeállítás';

  @override
  String get avatarDuplicate => 'Másolat készítése';

  @override
  String get avatarApply => 'Alkalmazás';

  @override
  String get avatarNoPresets => 'Még nincs saját összeállításod.';

  @override
  String get avatarPresetHint =>
      'A kedvencjelölést és a másolatot a Mentés gomb rögzíti.';

  @override
  String get avatarUnsaved => 'Nem mentett változtatások';

  @override
  String get avatarUnsavedBody =>
      'A Mentés gombbal megtarthatod az új összeállítást. Elveted most a változtatásokat?';

  @override
  String get avatarDiscard => 'Változtatások elvetése';

  @override
  String get avatarDefault => 'Alapból elérhető';

  @override
  String get avatarUnlocked => 'Feloldva';

  @override
  String get avatarNew => 'Újonnan megszerzett';

  @override
  String get avatarTabBasics => 'Alapok';

  @override
  String get avatarTabFace => 'Arc és fej';

  @override
  String get avatarTabOutfit => 'Ruházat';

  @override
  String get avatarTabAccessories => 'Kiegészítők';

  @override
  String get avatarTabAtmosphere => 'Hangulat';

  @override
  String get avatarTabPresets => 'Presetek';

  @override
  String get avatarFieldFamily => 'Karaktertípus';

  @override
  String get avatarFieldAge => 'Korosztály';

  @override
  String get avatarFieldStyle => 'Stílus';

  @override
  String get avatarFieldFace => 'Arckifejezés';

  @override
  String get avatarFieldEyes => 'Szemek';

  @override
  String get avatarFieldHair => 'Haj és fejforma';

  @override
  String get avatarFieldHeadwear => 'Fejfedő';

  @override
  String get avatarFieldOutfit => 'Ruhaszett';

  @override
  String get avatarFieldAccent => 'Színkiemelés';

  @override
  String get avatarFieldGlasses => 'Szemüveg';

  @override
  String get avatarFieldNeck => 'Nyakdísz';

  @override
  String get avatarFieldHeld => 'Kézi kiegészítő';

  @override
  String get avatarFieldDetail => 'Arcdísz';

  @override
  String get avatarFieldBack => 'Hátidísz';

  @override
  String get avatarFieldBackground => 'Háttér';

  @override
  String get avatarFieldAura => 'Aura';

  @override
  String get avatarFieldReaction => 'Vizuális személyiség';

  @override
  String avatarPreview(String name) {
    return 'Menti-előnézet: $name';
  }

  @override
  String avatarLocked(int level) {
    return '$level. szinten nyílik meg';
  }

  @override
  String get avatarHeadwearCowboy => 'Cowboykalap';

  @override
  String get startLanguage => 'Szia! Milyen nyelven mentizzünk?';

  @override
  String get startWelcome =>
      'Én vagyok Menti. Kis lépések, saját tempó – és egy kabala, aki veled tart.';

  @override
  String get startAgeTitle => 'Előbb egy fontos kérdés';

  @override
  String get startAgeBody =>
      'Elmúltál 18 éves? A Menti megjelenésének korosztálya ettől független. 18 év alatt csak az életmód- és karakterfunkciók érhetők el.';

  @override
  String get startAdult => 'Betöltöttem a 18. életévemet';

  @override
  String get startMinor => 'Még nem vagyok 18 éves';

  @override
  String get startLocalOnly =>
      'Ez helyi életkori nyilatkozat, nem személyazonosítás. A profil ezen az eszközön tárolódik; nincs fiókregisztráció.';

  @override
  String get startCharacter => 'Jöhet a saját Mentid!';

  @override
  String get startName => 'Becenév';

  @override
  String get startNameBody =>
      'Hogy szólíthatlak? A Mentidet később is átöltöztetheted a Studióban.';

  @override
  String get startFinish => 'Mentés és indulás';

  @override
  String get startSaveError =>
      'Nem sikerült biztonságosan befejezni. Az adataid megmaradtak; próbáld újra. Sérült profil esetén állítsd helyre a mentést.';
}
