# Kiadási előkészítés – ellenőrzendő tervezet

Ez a dokumentum nem megfelelőségi igazolás. A szövegek a kiadásra kerülő buildben ténylegesen ellenőrzött funkciókhoz igazítandók. A HU/EN felület teljes lefedettségét még ellenőrizni kell.

## Google Play – magyar szövegterv

Név: MennyiMent?

Rövid leírás:
Italnapló, költségek és napi önellenőrzés Mentivel, a saját tempódban.

Hosszú leírás:
Ismerd meg a szokásaidat Mentivel, a narancssárga társaddal! A MennyiMent? segít feljegyezni az italokat és az ismert költségeket, áttekinteni a naplódat, és időt szánni a napi önellenőrzésre.

• Italnapló saját italokkal és kedvencekkel.
• Statisztikák és költségösszesítések a rögzített adatok alapján.
• Reggeli Menti, személyes célok és heti kihívások.
• Menti-szintek és ruhák: a jutalmak az önellenőrzéshez és a tudatos követéshez kapcsolódnak.
• Személyre szabható karakter és játékos reakciók.

A hiányzó bejegyzés nem bizonyít alkoholmentes napot. A hiányzó árak miatt a költségösszesítés nem feltétlenül teljes. Az alkalmazás nem ösztönöz alkoholfogyasztásra, nem orvosi eszköz, és nem alkalmas a józanság vagy a vezetési képesség megállapítására. Felnőttek tudatos önmegfigyelését támogatja.

## Google Play – English draft

Name: MennyiMent?

Short description:
Track drinks, recorded costs and daily check-ins with Menti, at your own pace.

Full description:
Get to know your habits with Menti, your orange companion. MennyiMent? helps you record drinks and known costs, review your journal and take time for a daily check-in.

• A drink journal with custom drinks and favourites.
• Statistics and spending summaries based on your records.
• Morning Menti, personal goals and weekly challenges.
• Menti levels and outfits that reward reflection and mindful tracking.
• A customisable character with playful reactions.

A missing entry does not prove an alcohol-free day. Missing prices can make spending totals incomplete. The app does not encourage drinking, is not a medical device and cannot determine sobriety or fitness to drive. It supports mindful self-reflection for adults.

## Rövid funkcióbemutatás

A napló önbevallásos adatokat tárol; a statisztika ezeket összegzi. A napi Menti hangulati és önreflexiós felület. Az XP és ruhatár a meglévő önellenőrzési és feladatteljesítési eseményeket használja. A személyes célok és a külön heti kihívások a saját vállalások követésére valók. A mentés/visszaállítás pontos adatkörét a kiadási buildben külön igazolni kell, mielőtt teljes körű mentést ígérünk.

## Kiadás előtti ellenőrzőlista

- [ ] SDK: Flutter 3.47.7 / Dart 3.13.5 tényleges elérhetősége és kompatibilitása ellenőrizve.
- [ ] Minden mérföldkő: pub get, gen-l10n, analyze, test, build web sikeres.
- [ ] A meglévő teljes CI és Europe/Budapest DST-regresszió sikeres.
- [ ] HU/EN hiánylista üres; hosszú szövegek és hibaüzenetek is ellenőrizve.
- [ ] 320/360/390 px, táblagép, 200% szöveg, sötét kontraszt, képernyőolvasó, fókusz és érintési méret ellenőrizve.
- [ ] Manuális és rendszeres animációcsökkentés, háttérbe kerülő route-ok vizsgálva.
- [ ] Újraindítás és frissítés után napló, saját italok, kedvencek, XP, összes feloldott ruha és választott karakter megmarad.
- [ ] Hibás, ismeretlen verziójú és hiányos adatok nem írhatók felül észrevétlenül.
- [ ] Mentés/visszaállítás roundtrip, hibás import, sikertelen írás és ismeretlen mezők regressziója sikeres.
- [ ] Mentés pontosan tartalmazza a dokumentált adatkört; export előtt és import után összehasonlítás.
- [ ] Android/iOS valódi eszközön: telepítés, életciklus, billentyűzet, offline állapot, back navigáció.
- [ ] Hiányzó ár/adat és jövőbeli bejegyzés megjelenítése helyes.
- [ ] Függőségek, licencek és meglévő karaktergrafikák felhasználási jogai ellenőrizve.
- [ ] A tesztelt commitból származó kiadási artifact, verzió és aláírás rögzítve.
- [ ] A felhasználó jóváhagyta a kiadást; nincs automatikus merge vagy publikálás.

## Adatvédelem – ellenőrzendő követelmények

- Adatleltár: ital és időpont, ár, saját italok, kedvencek, hangulat/energia, szabad szöveges önellenőrzés, célok, kihívások, XP, karakter és beállítások. Vizsgálni kell, hogy egyes adatok egészségügyi/különleges adatnak minősülnek-e.
- Adatkezelő, elérhetőség, célok, jogalapok, megőrzés, érintetti jogok és panaszút dokumentálása magyarul és angolul, jogi felülvizsgálattal.
- SharedPreferences nem titkosított adattároló: platformonként ellenőrizendő az OS backup, eszközvédelem és esetleges webes tárolás. Ne ígérjünk titkosítást vagy teljesen helyi adatkezelést igazolás nélkül.
- Manifestek, SDK-k, hálózati forgalom és tranzitív függőségek alapján ellenőrizni kell az adatküldést. A Play Data Safety és az Apple App Privacy nyilatkozata ennek feleljen meg, ne feltételezésnek.
- Exportált mentés érzékeny szövegeket tartalmazhat: figyelmeztetés, tárolási hely és megosztási út ellenőrzése. Diagnosztikába ne kerüljön naplótartalom.
- Törlési/exportálási lehetőség és a backupra gyakorolt hatás dokumentálása; törlést jelen fejlesztés nem hajt végre.
- Ha később analitika vagy hibajelentő szolgáltatás lesz: külön adatvédelmi értékelés, minimalizálás és szükséges hozzájárulás. Most ilyen nem került be.

## Korhatár és felelős alkoholtartalom

Felnőtt célcsoporthoz igazított kommunikáció; a Menti karakter ne célozzon gyermekeket. Töltsük ki őszintén az aktuális Play/IARC és Apple korhatárkérdőíveket; a végleges korhatárt ne találjuk ki. Ellenőrizni kell a célországok alkohollal kapcsolatos szabályait és a platform irányelveit. Ne legyen fogyasztási verseny, mennyiségi jutalom, megszégyenítés vagy józanságra/vezetésre vonatkozó ígéret. A 0%-os bejegyzés sem bizonyít egy teljes alkoholmentes napot.

## Google Play és App Store teendők

1. Tulajdonos ellenőrizze a fejlesztői fiókokat és alkalmazásazonosítókat; hozzáférést és számlázást ne módosítsunk automatikusan.
2. Aláírás, kulcskezelés és biztonságos CI-secretkezelés; Android target API, iOS minimum és SDK-követelmények ellenőrzése az aktuális áruházi dokumentációból.
3. Adatvédelmi URL, támogatási elérhetőség, kategória, HU/EN metaadatok és a valós buildből készített képernyőképek.
4. Play Data Safety, App Privacy, exportmegfelelőség és korhatárkérdőívek kitöltése tényleges adatáramlás alapján.
5. iOS privacy manifest/required-reason API-k és a beágyazott SDK-k ellenőrzése; Android jogosultságok indokoltsága.
6. Belső teszt / TestFlight, valódi eszközök és visszaállítási próba. Külső feltöltés és publikálás külön felhasználói engedéllyel.
7. Review-megjegyzések, adatmegőrzési tájékoztató, kiadási jegyzet és visszagörgetési terv készítése. Store review előtt ne állítsunk teljes megfelelést.

## Későbbi közösségi funkciók feltételei

Külön specifikáció és jóváhagyás szükséges. Alapértelmezetten privát napló; explicit és visszavonható megosztás, tárgyankénti szerveroldali jogosultságvizsgálat, azonosítás és fióktörlés. Kiskorúak védelme, jelentés/tiltás/moderáció, visszaélés- és spamvédelem, sebességkorlát, adatminimalizálás, incidenskezelés és adattárolási régió vizsgálata. Alkoholmennyiséget rangsoroló toplista és fogyasztásösztönző verseny nem kerülhet be. Nyilvános profil és üzenetküldés most nem készült.
