# MennyiMent? 2.0 D/E – személyes központ és minőség

Specifikáció: https://github.com/hunyakferenc-droid/mennyiment/issues/20
Alap: a #19 PR ellenőrzött HEAD-je, `fcfb954d7801f7fce383ac1ce9b77869dba691b9`.
Ág: `feature/mennyiment-2-personal-hub`. A draft PR a #19 ágát célozza, így csak a D/E különbségét mutatja. A main közvetlenül nem módosul; nincs automatikus merge vagy kiadás.

## D1 – elkészült

A kezdőlap új „Saját Menti • Áttekintés” gombja egyetlen, görgethető központot nyit. Megjelenik a kiválasztott karakter és ruha eredeti assetje, XP/szint és következő szint, a mai napi válaszok és a külön XP-önellenőrzés, a személyes heti önellenőrzési cél és költségkeret, a külön heti kihívások, valamint a hét eddig rögzített italai, alkoholtartalma és ismert költsége. A meglévő oldalakat és szerkesztési útvonalakat nem töröltük.

A központ csak olvas. Egy SharedPreferences-újraolvasás után szinkron pillanatképet készít; a meglévő üzleti modellek tiszta dekódolóit és naptári célbizonyítékát használja. Nem hív író/migráló `Store.load()` függvényeket, nem indít XP-migrációt és ruhafeloldást. Nincs új kulcs, párhuzamos tartós adattár vagy backup-séma. A személyes cél, napi Menti és kihívás meglévő validátorát közös tiszta dekódolóvá emeltük ki; az üzleti írási szerződés és XP-szabály változatlan.

| Adatállapot | Megjelenítés |
| --- | --- |
| Nincs tárolt dokumentum | „Ehhez még nincs mentett adat”, nem nulla és nem első szint. |
| Nem olvasható / ismeretlen támogatási verzió | Lokalizált hiba és újrapróbálás; más olvasható részek megmaradnak. |
| Tárolt üres napló vagy naplista | Rögzített 0, külön szöveggel és fogyasztásra vonatkozó következtetés nélkül. |
| Hiányzó vagy hibás régi ár | Ismeretlen ár; az ismert összeg részösszeg, nem teljes költség. A nyers rekord nem változik. |
| Ismert 0 Ft | Valódi rögzített nulla, nem adathiány. |
| Napi válaszok megvannak, XP-önellenőrzés nincs | A két forrás eltérése látható, nincs feltételezett XP-jóváírás. |
| Cél teljesült | Csak helyes, különböző, nem jövőbeli, az aktuális hétre eső rögzített napok alapján. |

A jövőbeli italbejegyzések és más hetek nem kerülnek az eddigi heti összesítésbe, de nem törlődnek. A kihívások kihagyott/leállított állapota külön jelenik meg. Közérzetnaplóhoz kötött kihívásnál a hiányzó/hibás közérzetadat nem helyettesíthető nulla vagy teljesített napokkal. Hiányos/idegen karakterbeállításnál nem választunk helyette találomra másik családot vagy ruhát. Régi XP-adat migrációját az áttekintő nem végzi el.

A hét helyi hétfőtől a következő helyi hétfőig tart. Naptári aritmetika kezeli a 167/169 órás Budapest/DST heteket és az ISO hét évhatárát. Napi időzítő és app-resume frissíti a pillanatképet; a kérésazonosító megakadályozza, hogy egy korábbi lassú betöltés felülírjon egy újabbat. A központ megnyitási őre a gyors dupla koppintást is kezeli. A vissza gomb a kezdőlapra visz.

## D2 – elkészült

A `MentiReactionCard` a meglévő HU/EN eseménykatalógus közös megjelenítése a #19 céloldalain és az új központban. Mérsékelt, 200 ms-os áttűnést és a meglévő szövegbuborékot használja; az alkalmazás manuális és a rendszer animációcsökkentését tiszteletben tartja. Nincs új jutalom, XP vagy kitalált esemény.

A központ első betöltéskor nem ünnepel. Két sikeres, azonos heti pillanatkép között csak ténylegesen hozzáadott napokkal, változatlan célszám átlépésekor jelenhet meg reakció. A célcsökkentés, puszta időmúlás, ismételt frissítés, újranyitás, hétváltás és költségrészösszeg nem esemény. A meglévő C-szakasz pontos eseménybizonyítékát használjuk. Visszaállítás az alkalmazás meglévő root/recovery útján történik, nem az áttekintőn belül.

Újrafelhasználható hiányzó/hibaállapot és szemantikával ellátott progress komponens került a közös `menti_ui.dart` fájlba. A központ a meglévő természetes magasságú rácsot és SafeArea/görgethető panelt használja. HU/EN feliratok, helyi pénz/dátum, tördelhető szövegek és rövid appbar-cím segítik a 320 px/200% nézetet. Az eredeti fiú/lány/semleges karakterek és ruhák változatlanok; új grafika nem készült.

## E – ellenőrzések és CI

Új adatmodell- és widgetregressziók: teljes tároló-pillanatkép változatlansága; hibás/részleges/hiányzó adatok; rögzített nulla és ismeretlen ár; 18 család/ruha kombináció; örökölt XP írás nélküli olvasása; mai válasz/XP eltérés; célreakciók ismétlés és hamis teljesítés nélkül; backup/restore roundtrip unknown mezőkkel; Budapest DST és ismétlődő óra, év/hét váltás; napváltás/app-resume és elavult async válasz; HU/EN 320 px 100%/200%; locale-váltás; újrapróbálás; navigáció és mozgáscsökkentés.

A meglévő teljes CI megmarad. A pull_request trigger a #19 célágát is elfogadja, hogy a külön D/E draft PR valóban futtasson ellenőrzést. A Budapest/DST lépés az új központteszteket is tartalmazza, a korábbi XP, célmentés, ruha és backup/restore regressziók mellett.

Helyben továbbra sincs Flutter/Dart SDK. A pub get, gen-l10n, analyze, test és build web helyi futtatási eredménye külön rögzítve; ezek helyi sikere nem állítható. A generált lokalizációt a CI állítja elő. A végleges PR-leírás tartalmazza a konkrét commitot, CI-futást és minden kötelező lépés tényleges eredményét; függő vagy hibás futás nem minősül sikernek. A helyi ARB-kulcs/helyőrző- és whitespace-ellenőrzés ettől külön kezelendő.

## Android + Chrome kézi tesztterv (még nem végrehajtott)

1. Android: meglévő adatokat tartalmazó telepítés frissítése; 320/360/390 dp, 100%/200% szöveg, rendszer sötét mód, TalkBack. Központ megnyitás/vissza/dupla koppintás, az összes kártya görgetése és felolvasási sorrend. A kiválasztott karakter/ruha egyezzen a ruhatárral.
2. Chrome: keskeny és széles ablak, 200% szöveg/zoom, billentyűzetes fókusz és visszanavigáció. HU/EN váltás és a pénz/dátum ellenőrzése. Külön profilban üres, rögzített nullás, hiányzó árú, részleges és hibás adat ellenőrzése; saját éles adatot ne sértsünk teszteléshez.
3. Mozgás: az alkalmazás mozgáscsökkentő kapcsolója és OS/browser prefers-reduced-motion külön és együtt. Ne maradjon háttérben futó karakteranimáció vagy ismétlődő ünneplés.
4. Idő: Europe/Budapest tavaszi/őszi óraátállítás, ismétlődő 02:30, vasárnap/hétfő és december/január határ. Éjszakára háttérbe tett app visszahozása után a mai napi kulcs és aktuális hét frissüljön.
5. Adatok: export a megnyitás előtt és után, tartalmi összehasonlítás; restore, újraindítás, majd központ- és ruhatár-ellenőrzés. XP, feloldások, unknown mezők és nyers napló maradjanak meg. A központ megnyitása ne hozzon létre új kulcsot.
6. Kontrasztok mérése és képernyőolvasós kézi vizsgálat; valódi eszközös teljesítmény nagy naplóval. A widgetteszt ezeket nem helyettesíti.

## Ismert korlátok és következő pontok

A központ olvasó áttekintő; a szerkesztés az eredeti oldalakon marad. A SharedPreferences-pillanatkép nem többfolyamatos ACID-garancia; másik böngészőlap párhuzamos írását explicit frissítés után látjuk. Nem készült backend, fiók, webshop vagy chat. További régi aloldalak lokalizációja, valódi eszközök, kézi akadálymentesség és store/jogi ellenőrzés hátravan. A csomag nem jelent Play-kiadásra kész vagy jogilag mindenben megfelelő állapotot.
