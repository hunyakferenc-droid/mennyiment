# MennyiMent? 2.0 – audit és fejlesztési jelentés

Állapot: részleges, helyben elkészített, Flutterrel még nem ellenőrzött változtatás.
Dátum: 2026. október 31.
Ág: `feature/mennyiment-2-foundations`.
A helyi klón kezdetben `4e4a9bb` commiton állt. A GitHub-kapcsolaton keresztül később igazoltuk, hogy a távoli main a kért `6bc8eb38b9b67c0ef76c7f60254e78573450a384` commit; annak első szülője a helyi alap. A kért main összes megváltozott fájlját a kapcsolaton keresztül beolvastuk, a main.dart módosításait háromutas, konfliktusmentes összefésüléssel integráltuk. A backup/restore teljes fájlkészlete és a main új indítási recovery-védelme megmaradt. A távoli fejlesztési commitok közvetlenül a kért main fájlfájára épülnek, annak szülőjével. A main ágat nem módosítjuk.

## Audit és prioritások

A `lib/` és `test/` fájlkészlet, függőségek és CI áttekintése megtörtént; a következő megállapítások célzott forrásvizsgálaton alapulnak, nem teljes soronkénti vagy futásidejű auditon.

| Prioritás | Megállapítás | Következő lépés |
| --- | --- | --- |
| P0 | Flutter/Dart nincs a PATH-on; az SDK-letöltés proxyhibával leáll. | Az előírt SDK elérhetősége után teljes ellenőrzés, majd további szakasz. |
| P1 | `main.dart` kb. 1358 sor: navigáció, tárolás, dialógusok, UI egyben. | Fokozatos komponenskivonás, külön tárolási migráció nélkül. |
| P1 | A kezdőlap heti végpontja 7×24 órát adott hozzá. DST-váltáskor nem mindig hétfő éjfél lett. | Ebben a csomagban közös naptári hétkezelés és célzott teszt. |
| P1 | `personal_goals.dart`: betöltési hibánál alapértékes UI maradhat írható; mentés nem őrzi az ismeretlen mezőket és nem ellenőrzi a bool eredményt. | Külön adatmegőrzési javítás hibainjektálásos teszttel; most nem módosítva. |
| P1 | `dashboard_v2.dart`: az üres napokból számolt célhaladás még a figyelmeztetés mellett is félreérthető; zöld üres napok. | Explicit önbevallás és hiányzó adat külön megjelenítése; adatmodell-módosítás külön vizsgálattal. |
| P1 | `menti_xp_store.dart`: a legacy `_decode` hibánál üres mapet adhat, a listák hibás elemei kiszűrődnek. | Szabályozott, írást tiltó állapot és visszaállítási tesztek; ne veszítsünk régi XP-t. |
| P1 | `main.dart` több helyen létrehoz havi/heti szűrt listákat és rendezést minden rebuildnél. | Profilozás után célzott előszámítás; kis naplóknál nem bizonyított teljesítményhiba. |
| P2 | HU/EN ARB és generált kód meglévő; sok képernyő továbbra is magyar literálokat használ. | Dashboard, célok, mozgásbeállítás, pénzügy és kezdőlapi szövegek tételes ARB-átvezetése. |
| P2 | A kezdőlapi reakció szövegként volt eltárolva; nyelvváltáskor magyar maradt. | Ebben a csomagban esemény tárolása és locale szerinti renderelés. |
| P2 | Sötét téma és lekerekített komponensek már léteznek, de több helyi panelstílus van. | Közös komponensek fokozatos használata; most a fejlődési oldal kapott közös panelt és oldaltörzset. |
| P2 | Keskeny nézetben a hosszú ListTile-címek és trailing gombok vizuális ellenőrzést igényelnek. | 320/360/390 px, nagy betűméret, TalkBack/VoiceOver és kontrasztmérés. |
| P2 | `lifestyle_insights.dart` és `lifestyle_insights_javitott.dart` párhuzamos implementáció. | Importok és használat igazolása után külön konszolidáció. |

A fő navigáció kezdőlapról Navigator push útvonalakon nyitja a dashboardot, statisztikát, profilt, napi Mentit és célokat. A bottom bar `selectedIndex` értéke 0: az aloldalak saját route-ok, nem tartós tabok. Az átállítás későbbi navigációs tesztekkel történjen.
A napló mentésében már van snapshot/konkurenciavédelem és sikertelen mentést kezelő logika; a kihívástároló sorosít és megőrzi az ismeretlen mezőket. Ezeket a jelen módosítás nem írja át.
A betöltési/hibaállapotok nem egységesek: a fejlődési oldal újrapróbálható, a dashboard/pénzügy kezdeti olvasása nincs hasonlóan védve.

## Elkészült módosítások

- `lib/menti_reactions.dart`: két nyelvű, determinisztikus tartalomkatalógus, napi önellenőrzés/heti feladat/szintlépés/0%-os bejegyzés eseményekkel. A katalógus nem ad XP-t, nem használ tárolót, és nem következtet az üres napokból. A tartalom jelenleg a Dart-katalógusban van, nem ARB-ben.
- `lib/main.dart`: aktuális locale alapján megjelenített reakció; sikeresen mentett 0%-os ital saját reakciót kap. A reakciószöveg nincs két sorra levágva. Közös naptári heti időhatárok.
- `lib/menti_progress.dart`: meglévő, sikeresen végrehajtott XP-eseményhez kapcsolt reakció. Duplikált esemény nem indít új reakciót. Meglévő hibaüzenet és újrapróbálás megmarad; diagnosztika hibatípussal/stackkel, tárolt naplóérték kiírása nélkül.
- `lib/menti_ui.dart`: újrahasznosítható panel és SafeArea-t használó, görgethető, maximált szélességű oldaltörzs; fejlődési oldalra bevezetve.
- `lib/menti_xp_store.dart`: naptári `weekStart`/`weekEnd`; a hétkulcs formátuma, tárolókulcsok és XP-pontértékek változatlanok. Régi rekordok nem kerülnek átírásra.
- `test/menti_2_foundations_test.dart`: HU/EN katalógus, indexhatárok, heti időhatárok, Budapest 167/169 órás hetek, 320 px/200% szöveg és rendszeres animációcsökkentés tesztjei; szintlépéskor pontosan a meglévő napi XP, napló/profil/ismeretlen ruhafeloldás megőrzése és ismételt napi esemény idempotenciája. Megírva, nem futtatva.
- `.github/workflows/flutter-ci.yml`: a meglévő Budapest/DST tesztlépés az új tesztet is futtatja; a többi meglévő ellenőrzés megmarad.
- `docs/MENNYIMENT_2_RELEASE_HU.md`: bolti szövegtervek, adatvédelmi és kiadási feladatok.

A beszédbuborék az alkalmazás mozgásbeállítását és a rendszer akadálymentességi beállításait is figyeli. Karakterasset, feloldás, SharedPreferences-kulcs és XP-szabály nem változott. Nem készült új webshop, fizetés vagy közösségi funkció.

## Valós ellenőrzési eredmények

| Parancs | Eredmény |
| --- | --- |
| `flutter pub get` | 127, `flutter: command not found` |
| `flutter gen-l10n` | 127, `flutter: command not found` |
| `flutter analyze` | 127, `flutter: command not found` |
| `flutter test` | 127, `flutter: command not found` |
| Budapest/DST célzott flutter tesztek | 127, `flutter: command not found` |
| `flutter build web` | 127, `flutter: command not found` |
| `git diff --check` | 0, sikeres whitespace-ellenőrzés |

SDK-letöltési kísérlet: `curl` exit 7, `Failed to connect to proxy port 8080`.
`gh auth status`: a jelenlegi GH_TOKEN érvénytelenként jelentve; tokenértéket nem írtunk ki.
`git ls-remote origin`: ugyanaz a proxykapcsolati hiba. Az ág feltöltési kísérlete (`git push -u origin feature/mennyiment-2-foundations`) exit 128, proxykapcsolati hiba. A draft PR létrehozási kísérlete (`gh pr create --draft`) exit 1, GraphQL proxykapcsolati hiba (`socket: operation not permitted`). Ezek a terminálos kísérletek nem hoztak létre PR-t. Később működő GitHub-kapcsolatot találtunk; a forrásfát létrehozó feltöltést azonban az automatikus jóváhagyási ellenőrzés elutasította: a forráskód és workflow célrepo-ba feltöltéséhez további felhasználói engedélyt kér. A felhasználó ezután kifejezetten jóváhagyta a feltöltést és a draft PR nyitását. A GitHub-kapcsolaton keresztül a feltöltés folytatódott; a CI aktuális állapotát a PR rögzíti. A terminálos proxyhiba nem jelenti a GitHub-kapcsolat elérhetetlenségét. Nincs igazolt Flutter-fordítás, futó UI-preview vagy tesztsiker.

## Következő mérföldkövek és kockázatok

1. A: SDK és GitHub-hozzáférés helyreállása után verzióellenőrzés, formatter, pub get, gen-l10n, analyze, teljes teszt, Budapest/DST teszt, web build. A távoli main és a kért alapcommit azonossága igazolt, az integráció elkészült. Ez a csomag addig draft állapotú.
2. B: megmaradt HU/EN literálok, főképernyő és navigáció modernizálása, 320 px/nagy szöveg/navigációs regressziók. Minden jelentős szakasz végén mind az öt előírt parancs.
3. C: igazolt cél- és kihívásteljesítési reakciók. Visszatérési reakcióhoz előbb megbízható utolsó aktivitás szükséges; nincs kitalált visszatérési vagy alkoholmentes napi állítás.
4. D: egységes személyes áttekintő, amely a tényleges napló, napi önellenőrzés, külön heti kihívás és személyes cél tárolóit kapcsolja össze. A meglévő fejlődési oldal heti XP-feladatai nem azonosak a külön ChallengeStore kihívásaival. Üres nap nem alkoholmentes nap, ismeretlen ár nem nulla költség.
5. E: adatmegőrzési és visszaállítási hibainjektálás, készülékteszt, bolti/jogi ellenőrzés. Csak ezután kiadás, külön felhasználói engedéllyel.

A teljes személyes áttekintő és a teljes 2.0 képernyőmodernizálás nem készült el. Az előírt sikeres tesztkapu nem volt elérhető, ezért nagyobb adatmodell- és navigációátalakítás nem indult. A meglévő teszteket nem töröltük; futásuk még igazolandó. A kezdetben hiányzó backup/restore fájlokat a távoli mainből integráltuk: data_backup, backup_file, data_backup_page, data_restore és tesztjeik változatlanok. A Budapest CI-lépés az összes mainbeli backup/restore regressziót is megőrzi. A teljes mentés/visszaállítás működését a jelen fejlesztés helyben nem tudta futtatással igazolni.
