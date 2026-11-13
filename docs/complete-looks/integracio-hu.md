# Teljeskinézetes kísérlet – megvalósítás

Alap: #40 `0bdb09cab60061367e590447dbce29c64ac73deb`, 2.4.1+36. Külön ág: `experiment/menti-complete-looks`; verzió 2.5.0+37. A korábbi PR és munkakönyvtár változatlan.

## Grafika

Pontosan három szabadon választható bejegyzés: `boy-base-v1`, `girl-base-v1`, `neutral-base-v1`. Mindegyik egyetlen teljes RGBA PNG. A közös Flutter-vászon 3:4 arányú, azonos talpvonallal és megjelenítési magassággal; a forrás képarányát ugyanazzal a vízszintes/függőleges skálával őrzi meg. A környezet külön, közös egyszínű világos levendula (`#F2EFF6`). Nincs családonkénti háttér vagy háttérválasztó.

A lány alkalmazásbeli képe a feltöltött L01 eredeti **bájtra azonos másolata**. A beszélgetésben mutatott új, világos hátteres generálási próba nem az alkalmazás assetje: a környezet nem kerül a karakterképbe sütve.

A fiú és semleges mintához az F01 és S01 eredetikből képszerkesztő eszközzel készült származtatott kivágás. Ez generatív művelet: nem állítunk bájtszintű karakterazonosságot vagy tulajdonosi elfogadást. Az első, sapkát a szélig vivő semleges változat elutasítva; a margós második változat került a kísérletbe. Az eredeti források változatlanok a leltárban, így az arc és anyagrészletek összehasonlíthatók. A tulajdonosi vizuális kapu nyitva marad. Nincs korábbi alkalmazásrenderből gyártott referencia.

A képméretek, bájtok, SHA-256 és teljes natív RGBA dekódolási felső becslések: `asset-metrics.json`. Futáskor a dekódolás a megjelenítési szélesség × eszközpixelsűrűség méretére korlátozott, a natív szélességet nem lépi túl. A nagyító külön háromszoros dekódolási keretet kér, hogy a kétujjas zoom ne a kis előnézetet nagyítsa elmosódottá; a normál kártyák továbbra is kis méretben dekódolódnak. A forrásfájlok nincsenek újraméretezve vagy felülírva; a megjelenítő a mért tartalmi keret alapján helyez. Egyszerre egy nagy kép és három kis kártya van, nincs réteganimáció vagy külső letöltés. A PNG-khez nem tartozik arcmimika; csak rövid kijelölési átmenet van, mozgáscsökkentésnél nulla időtartammal.

## Tárolás és visszatérés

Egy új, külön `mennyiment_complete_look_v1` kulcs tartalmazza a verziót, aktív módot és stabil kinézetazonosítót. Üres telepítésen sem ír betöltéskor. Az eredeti profil, nyers mezők, régi opcióazonosítók, XP, korhatár és feloldások nem módosulnak. Nincs migráció és automatikus átváltás.

A mentés egyszerre csak egy írást enged. Újratöltött snapshotot hasonlít a megnyitott állapothoz, visszaállítási tranzakció alatt nem ír, megköveteli az írás sikerjelzését, utána újraolvassa az értéket, és csak ekkor frissíti az alkalmazásállapotot. Hibás/ismeretlen verzió vagy snapshot-eltérés tiltja az írást. A hibaüzenet újratöltést kér; a backend részleges írásánál sem ígér hamis sikert. A SharedPreferences nem több folyamat közötti adatbázis-tranzakció; a meglévő tároló korlátai itt is érvényesek.

Az export a meglévő közös mentési útvonalon viszi az új kulcsot. Az import ellenőrzi a sémát és ismert azonosítókat; sérült/ismeretlen helyi kísérleti állapotot nem cserél le vakon. Régi, kulcs nélküli mentés overlayként megőrzi a választást. Sikeres teljes visszaállításkor a gyökérnézet újratöltése az új scope-ot is betölti.

A galériában a korábbi mód kiválasztása és mentése visszakapcsolja a régi karaktert, az új választás is megmarad. Fejlesztői visszatérés: a külön `/workspace/mennyiment-character-quality` munkakönyvtár és `fix/menti-character-quality` ág használható reset/adattörlés nélkül. A régi alkalmazás az ismeretlen új kulcsot figyelmen kívül hagyja; mentést készíts állapotváltás előtt.

## Későbbi katalógus

A hosszú távú 30/30/30, induló 5/5/5 választás nincs legyártva. A katalógus azonosító/család/asset/feloldási feltétel szerkezetű; most mindhárom feltétel `free`. XP/prémium később külön termék- és jogosultsági megvalósítás. Nincs pontlevonás, fizetés vagy ál-vásárlási gomb. A három működő minta átadása után további karaktergyártás nem folytatódik tulajdonosi értékelésig.
