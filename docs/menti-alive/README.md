# Menti Alive 2.8.0+40

Alap: #43 draft PR, `2feb5f872dfa89ff079b8d852bc38a8f8e404421`. A 18 eredeti teljes kinézet és PNG, a 14 reakció, a globális egydekóderes motor, a mentés, XP és normál felületi bekötések már elkészültek. Ezekre építünk; nincs profil-/XP-migráció vagy új jutalmazás.

## Tényleges médiakészlet

2026. november 15-én a csatlakoztatott egyetlen magánmunkatér normál videóelőzményének teljes, végiglapozott eredménye 26 job: **23 letölthető, ffprobe/hash alapján ellenőrzött kész videó**, két sikertelen és egy blokkolt generálás. A projektlista üres. Új generálás és kreditköltés nem történt.

Mindegyik job ugyanazt a `d33d5264-c282-4ccc-9f9a-fa480799e504` referenciaazonosítót jelöli. Ez nem bizonyít automatikusan képi azonosságot. Mind a 23 kész klip kezdő/középső/záró képkockája átnézett. Több új videó alsó teste levágott, másik széles keretben apró karaktert mutat; vannak fehér, fekete és lila beégetett hátterek. A besorolás továbbra is **boy-festival-v1 jelölt**, nem tulajdonosi vagy identitás-jóváhagyás. A többi 17 kinézethez nincs igazolt kész média. A pontos URL-ek, jobok, állapotok, paraméterek és lenyomatok a `media-inventory.json` fájlban szerepelnek. A 2.7-es történeti leltár változatlan marad.

## Az első három lejátszható jelölt

| Reakció | Forrás job | Kezelés |
|---|---|---|
| welcome | f4285f42-f007-4682-9e33-80596995e5ec | néma, H.264 Main 3.1, 540×720, 24 fps |
| wink | b67e7b8f-cb74-4293-9783-8acd0cd95102 | ugyanaz |
| congratulation | 19e7b417-b349-41c8-aaaf-04aea914fe4f | ugyanaz |

Mind kb. 5,04 s és 0,4–0,55 MB, 6 MiB és 8 s alatt. Eredeti videó és PNG nem lett felülírva. A feldolgozás determinisztikus parancsait a `tool/menti_alive/process_candidates.py` rögzíti; a kimenet `tool/menti_alive/review_assets/`. Minden jelölt `previewOnly:true`, `reviewRequired`, üres jóváhagyóval/dátummal és **false** identitás-, háttér-, jogi és tulajdonosi jóváhagyással.

## Háttérkezelési döntés

A lila sapka, ruha, táska és cipő színei átfednek a lila stúdióháttérrel. A színkulcsos törlés eltüntethet karakterrészleteket; nem tekintjük elfogadott háttéreltávolításnak. Az alfa-videó nem univerzális H.264/Android MediaCodec funkció, ezért nem állítunk átlátszó Android-lejátszást. Az ellenőrizhető alternatíva **közös, átlátszatlan stúdiókeret, a klip beégetett hátterének megtartásával**. Nem állítjuk, hogy a belső gradiens/háttér egységesre cserélődött. Nincs szegmentálás, színkulcs vagy átszínezés; a Lanczos-méretezés megtartja a forrás arányait. A keret, a forrásban megváltozott póz/részletek és teljes mozgás továbbra is tulajdonosi vizsgálatra várnak.

## Elválasztott Flutter-integráció

- A normál `main.dart` nem importálja a REVIEW oldalt; a normál pubspec nem tartalmazza a jelölteket vagy a REVIEW-katalógust. A normál produkciós katalógus továbbra is **üres, 0 jóváhagyott videó**.
- A külön `tool/menti_alive_preview.dart` célpont csak `MENTI_ALIVE_REVIEW=true` fordítási jelzéssel nyitja meg az előnézetet. Normál indításból nincs hozzá útvonal.
- Az izolált buildszkript a commitolt forrást ideiglenes munkafába csomagolja, csak ott bővíti a pubspecet. Titkot/ignorált kulcsot nem másol. Az eredeti alkalmazásazonosító és aláírási beállítás marad. A REVIEW launcher felirata különbözik.
- A külön katalógusadapter nem teszi jóváhagyottá a médiát: minden flag false marad. A normál katalógus ugyanazokat az objektumokat sem választhatja ki. A kiválasztás pontos look/reaction egyezést igényel.
- Ugyanaz a MentiAnimationController, LocalMentiVideo és MentiAnimationPlayer fut, mint a normál főoldal/profil/gyűjtemény mentett karakterénél. A normál eseménykapcsolatok megmaradnak; jóváhagyott pontos média nélkül eredeti PNG a helyes eredmény.
- Újraindítás előtt a dekóder lezárása megvárandó. Újabb választás, leállítás vagy életciklus-váltás érvényteleníti a függő újraindítást.
- A fejlesztői mérföldkő/önkontroll gombok kifejezett motorbemeneti próbák: nem írnak XP-t vagy teljesítést. A kézi bemutató megkerüli az automatikus gyakoriságot, a normál automatikus események szabálya változatlan. A légzésreakcióhoz itt nincs klip: nincs másik videóval pótlás.

## Adatvédelem és állapot

A REVIEW csak SharedPreferences.get/reload művelettel olvassa a mentett teljes kinézetet. Nem használ megszerzést/migrációt végző profilstore-betöltést. A nyelv, ideiglenes kinézet és kapcsoló csak memóriában él; nincs új tartós kulcs. Hibás/ismertlen karakteradatot nem ír felül és nem találgat. A normál napló, XP, feloldások, korhatár, Studio és export/import megmarad. Az Android-engedélyek szigorítása és a kiadási aláírás védelme változatlan.

## Ellenőrzés és aktiválási kapu

`python3 tool/check_menti_alive_media.py` a valódi fájlokat ffprobe/hash alapján, a 18 PNG-t lenyomattal és a normál manifest kizárását ellenőrzi. A modell/widgettesztek a katalógusok elválasztását, rossz mezőket, másik karakter fallbackjét, dekóderlezárást/újraindítást és HU/EN 320–430 px/200%-os felületet, byte-pontos adatmegőrzést vizsgálnak. A korábbi 1152 teszt követelményei megmaradnak; a friss eredményt a konkrét CI-forrás és átadás rögzíti.

Jogi feltételek és tulajdonosi hozzájárulás még nem igazoltak. A korábbi hivatalos jogi elérés HTTP 403-mal meghiúsult; ebből és az előfizetésből nem következik felhasználási jog. Minden jelölt jóváhagyásra vár. Normál aktiválás csak teljes vizuális/karakterazonossági, háttér-, jogi és névvel/dátummal rögzített tulajdonosi jóváhagyás után, külön felülvizsgált produkciós katalógusbejegyzéssel lehetséges. Automatikus elfogadás nincs.

Kipróbálás: `kiprobalas-hu.md`. A fizikai Android-, emulátoros és valódi Windows-eredményeket külön kell jelölni; egy build vagy widgetteszt ezeket nem helyettesíti.
