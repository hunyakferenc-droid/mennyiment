# MennyiMent? 2.4.1+36 – karakterminőségi csomag

A csomag a #39 átadási állapotára (`193ab29a17ac9d7eccd9f8930d3dedaf19b51bf8`) épül, a `fix/menti-character-quality` ágon, a #40 draft PR-ben. A végleges alkalmazásforrás: **`3df8f66c7be59a92314694f738753ce9cc8755e7`**. A korábbi PR-ek változatlanok; nincs main merge, Play-feltöltés vagy publikálás.

## Mi maradt meg?

A kilenc eredeti karakter, az eredeti PNG-k, az összes választási azonosító és feloldás megmaradt. A csomag nem vezet be új karaktert, tárolási sémát, migrációt, jutalmazási szabályt vagy engedélyt. A profil, italnapló, XP, kalandok és fájlos mentés tárolói változatlanok. Nem kellett választásokat elrejteni vagy régi összeállításokat más opcióra cserélni.

## Bizonyított hibák és javításuk

| Hiba | Javítás |
| --- | --- |
| A reakció csak dekorációt adott, az arc tartósan a személyes szem-/szájbeállításon maradt. | A hét meglévő reakció három tartós arccsoportot kapott: örömteli, figyelmes, támogató. A szemnyitás, száj és szemöldök együtt változik, csökkentett mozgás mellett is. A fej alapformája megmarad. |
| A Studio Hangulat-választása nem jutott el a nagy előnézethez és nagyítóhoz. | Mindkettő a kiválasztott reakciót kapja. A többi kategória továbbra is a személyes arc-/szembeállítást mutatja. A reakció nem írja át ezeket a profilban. |
| A magas ünnepi kalap csúcsa mobilméretben kilóghatott. | Csak a kalap mérete igazodik a rendelkezésre álló helyhez, aránytartóan. A teljes karakter és a pupillák helye változatlan. |
| Egy harmadik kiegészítő hozzáadása kisebbre vette a sálat/szemüveget/gallért, illetve megváltoztatta a láncot. | A viselt elemek geometriája független a kiegészítők darabszámától. Kézi tárgy hozzáadása nem méretezi át a nyakban vagy arcon viselt elemet. |
| A hosszú fonatot a rövid hajakhoz használt illesztés az arc mögé tolta, az atlaszcsempén elszigetelt képtöredékek is látszottak; a választókártya levágta a fonatot. | A fonott haj külön, aránytartó illesztést és teljes előnézeti kivágást kapott. A forrásból származtatott klipmaszk az idegen csemperészleteket is kizárja, akkor is, ha egy halvány alfa-udvar összeér a hajjal. Az atlasztisztító maszkban a fő hajmag összes 16 feletti alfájú képpontja és a hozzá tartozó simított szél, összesen 119 322 képpont megmarad; 6 135 idegen töredékpont nem rajzolódik ki. A PNG-k változatlanok. |

A hét reakcióazonosító nem hét teljesen új arc: `proud`, `motivating`, `celebrating`, `funny` az örömteli; `focused` a figyelmes; `calming`, `sleepy` a támogató csoport. Az eredeti jelképek segítik a megkülönböztetést. A napszemüveg szándékosan takarja a szemet; itt a száj és a jelképek is fontosak. Ismeretlen vagy null reakció továbbra is a személyes arcot használja.

A visszaellenőrzés további, valódi böngészőfüggő hibát talált: a fonat és kapucni normalizált, összetett útvonalai Chrome 157 alatt az arc elé engedtek hajrészleteket. A `f952478` köztes jelölt eredeti CI-képein a szigorú arcvédelmi próba 15 régióban 1546 eltérő képpontot mutatott ki. Ez a jelölt nem az átadott +35-ös kiadás. A végleges javítás az atlasz tisztítását külön klippel végzi, az arcot pedig a teljes 320×400-as karakterkoordinátákban védi. Az új böngészős regresszió 81 karakter–fejfedő pár, 243 szem-/szájrégió, 41 769 képpont-összehasonlítás pontos egyezését követeli meg, tolerancia nélkül. A galériában ennek a köztes hibának is külön előtte–utána párja szerepel.

Azonos aktív reakció ugyanazt a közös renderert használja minden felületen. Esemény nélküli nézetben a személyes arc, a Hangulat-próbában és az ünneplő visszajelzésnél az aktív reakció látható; ez eltérő alkalmazásállapot, nem másik karakter. A személyes arc-/szemválasztást egyik reakció sem írja át.

## Vizuális referencia és tesztek

Egyetlen golden-frissítés indokolt: `test/goldens/menti_225_pair.png`, a lány/idősebb/fonott haj/sapka összeállítás. A korábban eltakart fonat látható lett. A klasszikus bal oldali karakter RGB-képe változatlan. Az RGB-eltérés befoglaló téglalapja `(423,94)–(565,212)`.

- Régi PNG SHA-256: `a14136e828baf965ebad7a09046cc2656facd4a88522c6cc3d22d3f2fdd1ebc8`.
- Új PNG SHA-256: `b488ccf46f11974a46a2d3305140a471ae5504dee76ab33a64183a0dcb75eebb`.
- Golden-tolerancia nem változott; a családi és többi referencia változatlan.
- A meglévő szigorú pupillahely-ellenőrzés változatlan maradt. A teljes alakot zsugorító első próbát ez joggal elutasította; a végleges javítás kizárólag a kalapot méretezi.
- A régi kiegészítőteszt darabszám miatti zsugorodást váró állítása egyenlőségre változott, mert éppen ez volt a hibás működés. Kilenc karakter × húsz ruha új geometriai ellenőrzése erősíti az elvárt függetlenséget; adatmegőrzési állítás nem gyengült.

## Képi bizonyíték és lefedés

A képgaléria azonos méretű, azonos konfigurációjú, változtatás nélkül rögzített Chrome-képeket tartalmaz. Az elkülönített Flutter-renderharness nem új alkalmazásképernyő. A sorok: fiú, lány, semleges; oszlopok: fiatal, felnőtt, idősebb. Normál galérianézetben egy karakter körülbelül 120 px, nagyítva az eredeti 224 px-es render vizsgálható.

A generált renderlefedés és a szemmel ténylegesen átnézett konfigurációk külön listában szerepelnek. A páronkénti lefedés nem a teljes kombinációs tér ellenőrzése, és a stabil PNG előállítása önmagában nem grafikai jóváhagyás. A teljes katalógus leltára az `inventory.json`, a konkrét emberi/ügynöki vizuális ellenőrzés jegyzéke a `reviewed-configurations.json`.

## Friss ellenőrzések és letöltések

Minden alábbi alkalmazás- és képi eredmény forrása `3df8f66c7be59a92314694f738753ce9cc8755e7`, Flutter 3.47.7 / Dart 3.13.5. Az átadási dokumentumok későbbi commitja nem módosítja az alkalmazás forrását.

| Ellenőrzés | Tényleges eredmény |
| --- | --- |
| Analyzer | Nincs jelzés |
| Teljes meglévő tesztcsomag és új regressziók | 1032 sikeres teszt; 48 új eset, meglévő tartalmi állítás/tolerancia gyengítése nélkül |
| Külön Europe/Budapest csomag | 349 sikeres teszt; ez részben átfed a teljes csomaggal, nem 349 további egyedi teszt |
| Lokalizáció és generálás | 906 egyező HU/EN kulcs; nincs lefordítatlan üzenet vagy generáltfájl-eltérés |
| Debug APK és statikus Android-ellenőrzés | Sikeres CI- és helyi build; végleges letöltött CI-APK aláírása, csomagazonosítója, verziója, ZIP/ELF 16 KB-os illesztése ellenőrizve |
| Release-aláírás védelme | 3 sikeres elutasítási ellenőrzés: hiányzó adat, nem létező külső kulcs, debug-alias; nincs release-kulcs vagy AAB |
| Teljes alkalmazás webbuildje | Sikeres; a letöltött ZIP CRC-je és SHA-256-ja ellenőrizve |
| Google Chrome 157.0.8103.78 | 40 sikeres főfolyamat-ellenőrzés HU/EN, 320/360/390/430 px; naplózás, hatmezős szerkesztés, azonos rekord, nulla/tört/hiányzó ár, szűrő, kaland, Studio-draft/visszavonás/dupla mentés/visszalépés, valódi JSON export/import és újratöltés |
| Külön tényleges karakterkiválasztás | 6 sikeres ellenőrzési csoport két HU/EN forgatókönyvben: család/kor/ruha/fonat/kalap/szemüveg/kézi tárgy/reakció, mentés, teljes újratöltés, térkép és küldetés-visszajelzés; XP/napló/ismeretlen profilmezők megőrzése |
| 200%-os szöveg és billentyűzet | A valódi Flutter-szövegskála meglévő HU/EN widgetmátrixában ellenőrizve; a Chrome-folyamatok normál szöveggel futottak |
| Teljes rendergaléria, Google Chrome 157.0.8103.50 | 249 egyező konfigurációjú képpár, összesen 1027 eredeti PNG; 7002 utána-konfigurációelőfordulás / 6579 különböző feloldott profil |
| Szigorú böngészős arcvédelem | 81 karakter–fejfedő pár, 243 régió, 41 769 képpont-összehasonlítás; nulla eltérés, CI-ben és helyi Chrome 157-ben is |
| Galéria tényleges használata | Szűrés és előtte–utána képek 386/720 px táblaszélességen, körülbelül 120/224 px karakterenként; nincs futási hiba vagy külső kérés |

A [teljes Flutter CI](https://github.com/hunyakferenc-droid/mennyiment/actions/runs/43440696189) első próbáján az Android NDK letöltése sérült ZIP-et adott. Az analyzer, 1032 teszt, 349 időzónás teszt és webbuild már ezen a futáson sikeres volt. A hibát nem tesztkihagyással kezeltük: a második próbálkozás teljes CI-je sikeres, benne ismét 1032 és 349 teszttel, web- és APK-builddel. A helyi telepített SDK-val is sikeres az APK-build. A végleges csomag külön ellenőrzött adatlapja az `apk-verification.json`.

A [képgaléria CI-je](https://github.com/hunyakferenc-droid/mennyiment/actions/runs/43440688174) sikeres. A 72 szemmel átnézett tábla 648 előfordulás / 630 különböző profil; az összes végleges CI-kép RGB-képe bitazonos az átnézett képpel. A 529 célzott páronkénti sor 2233 opciópárt fed le 11 mezőn, mind a kilenc identitáson. A teljes kompatibilis katalógustér hajláthatósággal 515 978 035 200 kombináció; null és hét aktív reakcióállapottal 4 127 824 281 600. Ismeretlen nyers mentett értékeket ez a véges katalógusszám nem számol. Nem állítunk teljes kombinációs vagy teljes vizuális lefedettséget.

- [Kipróbálható Web ZIP](https://github.com/hunyakferenc-droid/mennyiment/actions/runs/43440696189/artifacts/14044424843), 89 129 697 byte. SHA-256: `a1ee6fa730706386e630afc9e55a81056efbc568143201b49bada9e79dbb5750`.
- [Debug APK ZIP](https://github.com/hunyakferenc-droid/mennyiment/actions/runs/43440696189/artifacts/14065717554), 156 049 856 byte. ZIP SHA-256: `1a941580e1710450f9c6cd2638062ae43cb120b728650dc0b1a93e356b4f9724`; benne `app-debug.apk`, build-info és ellenőrzőösszeg.
- [Teljes galéria – Előtte ZIP](https://github.com/hunyakferenc-droid/mennyiment/actions/runs/43440688174/artifacts/14045654520), 141 850 814 byte.
- [Teljes galéria – Utána ZIP](https://github.com/hunyakferenc-droid/mennyiment/actions/runs/43440688174/artifacts/14045919416), 454 835 595 byte. A két galéria-ZIP-et ugyanabba a mappába bontsd ki, majd nyisd meg az index.html fájlt.
- A kisebb képes átadási ZIP-ben 71 eredeti PNG, 21 előtte–utána képpár, húsz kilenckarakteres ruhatábla és további tíz valódi alkalmazáskép található. Az egyik utána-kép két összehasonlításhoz közös. Kicsomagolás után közvetlenül az index.html nyitható meg.

A CI-letöltések 14 napig, 2026. november 27-ig érhetők el; GitHub-bejelentkezés szükséges lehet. A kisebb galéria képei és a jegyzék a repositoryban is megmaradnak. A konfigurációs és ellenőrzési adatlapok: `reviewed-configurations.json`, `render-coverage.json`, `face-guard.json`, `browser-flows.json`, `character-flows.json`, `gallery-browser.json`, `preservation.json`.

## APK-aláírás és adatmegőrző frissítés

A konkrét átadott `app-debug.apk` 238 267 008 byte, SHA-256-ja `0d270b8cae098795a8500186b3b04f341e949ff1615c25bdc4a3c348523b9bb7`. Az aláíró tanúsítvány SHA-256-ja **`e93201f1c6c3c414a01db7dda285a66313999eb96d6148456e1b3206998fde3d`**. Az alkalmazásazonosító változatlan: `com.example.mennyiment`, verziókód 36, minimum SDK 24, cél SDK 36.

A korábban átadott +35-ös APK tanúsítványa **`e64dc39dd76010d4954612d93c5a1ceb3ce37f2be2627fdbc40ae04b3a977bfa`** volt: a két aláírás eltér. A telefonon ténylegesen telepített csomag aláírása nem ismert. Adatmegőrző helybeni Android-frissítéshez azonos elfogadott aláírási identitás és megfelelő verziókód kell; a nagyobb verziókód önmagában nem oldja fel az eltérő aláírást. A CI debug-kulcsa futásonként eltérhet, ezért ehhez a konkrét csomaghoz és ujjlenyomathoz kötjük az átadást. Későbbi dokumentációs CI másik APK-ja nem helyettesíti automatikusan ezt a csomagot.

Aláírásütközés miatt a meglévő alkalmazást ne távolítsd el. Használd a Web ZIP-et vagy külön tesztkészüléket, őrizd meg a fájlos mentésedet; helybeni frissítéshez a korábbi megfelelő kulccsal készült build szükséges. Release-kulcsot nem hoztunk létre, aláírt release AAB nem készült, a debug APK nem publikálásra kész csomag.

## Kipróbálás és korlátok

Kövesd a [rövid magyar ellenőrzőlistát](kiprobalas-hu.md). A Web ZIP-ben az `INDITAS.cmd` Python nélkül indítja a csomagot. Mindig ugyanazt a címet használd: **http://127.0.0.1:7357**. A forrásindítás külön útvonal, Flutter SDK-t igényel. Böngészőadatot nem kell törölni.

A debug APK nem Play-kiadás. Valódi telefonos telepítés, emulátoros futás, TalkBack, fizikai teljesítménymérés és valódi Windows-próba ebben a környezetben nem futott. A billentyűzetet és 200%-os szöveget Flutter-widgettesztek, a tényleges mentési folyamatokat elkülönített Chrome-profilok vizsgálják; ezek nem helyettesítik a telefonos próbát.

Telefonon még ellenőrizendő: első indítás/frissítés, rendszerbetű 200%, Studio görgetés és nagyító, reakció csökkentett mozgással, háttérbe lépés/visszatérés, mentés/újraindítás, fájlos export/import és billentyűzet. A korábbi telepített app adatait és mentését őrizd meg. Aláírásütközés megoldásaként ne távolítsd el az alkalmazást.
