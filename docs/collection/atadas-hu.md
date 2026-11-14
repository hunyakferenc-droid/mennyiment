# Menti-gyűjtemény 2.6.0+38 – megvalósítás és ellenőrzési leltár

**A teljes, végleges CI-eredmény és a letölthető alkalmazáscsomagok a [#42 draft PR leírásában](https://github.com/hunyakferenc-droid/mennyiment/pull/42) szerepelnek, az átadási commit ellenőrzése után.** Ez a fájl a rögzített alkalmazásforrás helyi eredményeit és az átadási tartalmat dokumentálja; a javítás előtti sikertelen tesztfutást nem állítja be sikeresként.

Alap: #41 `0044dc52e23cf9165bc7266474ef72c2ae7cef30`, korábbi alkalmazásforrás `592d49a9a66c32ae1a10c60f66899bb4fa767636`. Külön ág: `feature/menti-collection`, külön munkakönyvtár; a korábbi PR-ek változatlanok.

Megvalósított alkalmazásforrás: **`5fbcafdffebcc34e280bb9b03ca4d4babb9a83db`**. Az ezt követő átadási változtatás tesztútvonalat, dokumentációt és bizonyítékokat érint; az alkalmazás-, asset-, Android- és függőségi fájlok azonosságát külön `git diff` ellenőrzi. A letölthető CI-csomag saját pontos checkout-commitját az artifact neve és `build-info.txt` fájlja tartalmazza. A végleges átadási commitot és zöld CI-futást a PR leírása rögzíti; nem önmagára hivatkozó commitazonosítót írunk ebbe a fájlba.

## Mi készült el?

- 15 különböző, kezdettől ingyenes teljes kinézet: családonként alap, buli, fesztivál, sport és üzleti. Három további, tényleges legendás kép 200 XP-nél végleg megszerezhető; a pont nem fogy el.
- Nagy képes, lusta kártyalista; családszűrő; Összes/Megszerzett/Feloldható; valódi feltételek és haladás; nagyító; ragadós Mentés/Mégse; mentetlen választás és külső változás védelme. A lista utolsó vezérlője üzenet fölé görgethető.
- Új felhasználónál teljes kinézet az első választásban. A főoldal, profil, gyűjtemény, nagyító és kalandtérkép közös képet használ. Meglévő összeállítás nem alakul át automatikusan; a korábbi Studio explicit, visszaváltható mód.
- A meglévő teljeskinézet-kulcs v1/v2 kompatibilitása; változatlan régi alap-ID-k; ismeretlen mezők és megszerzett kinézetek megőrzése; snapshot-védelem és perzisztálás utáni felületfrissítés. Korábbi mentés nem veszi el a tartós feloldást.
- 360×480-as valódi bélyegképek; korlátozott képdekódolás; éles nagyító; állóképes megjelenítés, hamis mimika nélkül. Nincs új háttérválasztó, runtime font-/képletöltés vagy rendszerengedély.
- HU/EN termékfeliratok, 952 egyező ARB-kulccsal. Nincs fizetés, előfizetés, helyi prémium-jogosultságkapcsoló, új XP-keresési szabály, minijáték, szoba vagy 90 kinézet tömeges gyártása.

A napló, szerkesztő, keresés/szűrés, korhatár, XP, kalandhaladás, régi Studio és fájlos mentés/visszaállítás már létezett; ezeket felhasználtuk, nem építettük újra. Tárolási és jutalmazási részletek: [adat- és XP-szerződés](adat-es-xp-szerzodes-hu.md).

## Grafika

[Számozott képes leltár](kepes-leltar-hu.md), [eredet és SHA-256](catalog-provenance.json), [böngészhető galéria](../images/menti-collection/galeria.html), [önálló képgaléria ZIP](../images/menti-collection/menti-collection-gallery-5fbcafd.zip).

18 tényleges konfigurációt néztünk át az eredeti mellett, sötét és világos Flutter-felületen: F01–F06, L01–L06, S01–S06. A lány képek az eredeti RGBA-fájlok bájtpontos másolatai; a korábbi három alap asset változatlan. A hátteres forrásokból származtatott kivágások eredete követhető. Ezek AI-segített technikai jelöltek, nem új, automatikusan tulajdonosilag jóváhagyott karakterek; apró kontúr/textúra eltérés lehetséges. Az eredetileg is forrásszélig érő részleteket nem nevezzük kitaláltan helyreállított eredetinek. Az alkalmazás arányos közös vászonnal és talpvonallal rajzol, széles köpenynél/gördeszkánál a teljes szélességet is figyelembe veszi.

A csomag 18 bélyegképet és 85 képet tartalmaz: 3 eredeti/sötét/világos összehasonlító lap, 36 mentési/nézetazonossági, 14 onboarding/XP és 32 kijelző-/szövegméret-kép. A képgaléria ZIP önálló ellenőrző anyag, nem az alkalmazás Web ZIP-je.

## Tényleges helyi ellenőrzések

| Ellenőrzés | Rögzített eredmény |
|---|---|
| Analyzer | Hibamentes |
| Lokalizáció | 952 HU/EN kulcs egyezik; nincs le nem fordított üzenet |
| Új állapot-/kompatibilitástesztek | 20 sikeres: v1, ismeretlen mezők, küszöb alatt/pontosan/felett, hibás/jövőbeli XP, feloldás/értesítés egyszer, hibás írás, párhuzamosság, külső XP-snapshot, visszaállítás uniója |
| Teljes helyi regresszió a megvalósítási commiton | 1110 sikeres, **1 sikertelen** régi navigációs elvárás; ez nem teljesen sikeres futás |
| A megmaradt hibás teszt javítása | A főoldal már a gyűjteményt nyitja; explicit régi Studio-belépés és két visszalépés került a tesztbe. Az eredeti név-/család-/ruha-/nyerskulcs-állítások megmaradtak. A teljes érintett tesztfájl újrafuttatva: **9 sikeres** |
| Régi Studio | Mind a 18 régi profil szerkesztése, mentése és újraindítása célzottan sikeres; nincs golden- vagy toleranciagyengítés |
| Galéria/onboarding/korhatár | A meglévő mátrixokat az új útvonalhoz igazítottuk; 320/360/390/430 px, HU/EN, 200% és billentyűzet-inset, választás/elvetés/mentés/újratöltés, régi mód |
| Élő XP-s galéria és külső változás | 8 HU/EN × kijelzőméret feloldási/szűrési eset és 2 külső választásváltozásos eset sikeres |
| Webbuild | Flutter 3.47.7, helyi web release sikeres, CDN nélkül |
| Debug APK | Sikeres, érvényes aláírás, változatlan csomagnév, statikus ZIP-/64 bites ELF 16 KB ellenőrzés sikeres; készülékre nincs telepítve |
| Chrome 157 | **10** HU/EN mentés/újratöltés/nézetazonosság/export/import/visszaváltás; **4** valódi friss onboarding/korhatár/lányválasztás és napi 190→200 XP; **16** viewport-/szövegméret-eset, 32 kép; runtime hibák nélkül |
| Dekódolás | 18 valós kép × 4 szélesség = 72 szoftveres mérés; a natív dekódolás legfeljebb kb. 6,3 MB RGBA/kép. Nem telefonos benchmark |
| Python nélküli indító | PowerShell 7/Linux: 8 HTTP-ellenőrzés sikeres; ez nem valódi Windows-teszt |

A végleges átadási commit teljes, javított regresszióját a CI újra futtatja. Csak a PR leírásában végül sikeresként rögzített futás csomagja használható esti próbára. A korábbi csomagok tesztszámai és a javítás előtti piros CI nem új sikeres validációk. A böngészős 200% a Flutter web által olvasott HTML gyökér-betűmérettel történt, nem valódi telefon rendszerbeállításával. A nagy szöveg melletti teljes választási/mentési utat a Flutter widgettesztek is végigjárják.

Géppel olvasható bizonyítékok: [helyi eredmények](evidence/local-verification.json), [10 Chrome-folyamat](evidence/complete-verification.json), [onboarding/XP](evidence/collection-journey-verification.json), [16 viewport](evidence/collection-matrix-verification.json), [képek hashleltára](evidence/image-index.json), [dekódolás](evidence/decode-measurements.json), [helyi APK](evidence/local-debug-apk.json), [indító Linux alatt](evidence/windows-launcher-linux.json).

## Aláírás és fennmaradó telefonos lépések

A helyi APK tartós debug-aláírója: `bc7109b7016de67d7bad33c7fabbdf4ba56be793bd3ab1f05cff92155bacf6d7`, egyezik a korábbi helyi build aláírójával. A korábbi #41 CI APK aláírója `c2aa6f45b0d1b171045961395e54315fc03dc4441b14a88d65d2446a31950af1`, a korábbi 2.4.1 CI-é `e93201f1c6c3c414a01db7dda285a66313999eb96d6148456e1b3206998fde3d`: ezek eltérőek. A CI-futások debugkulcsa változhat. A konkrét, végleg átadott CI APK tanúsítványát a PR végleges jelentése és a csomag saját aláírásellenőrzése közli.

Adatmegőrző közvetlen frissítéshez ugyanaz a csomagnév, megfelelő verziószám és azonos aláíró szükséges. Eltérő tanúsítványnál a korábbi kulccsal kell újrafordítani, vagy külön tesztkészüléket kell használni; a meglévő alkalmazás törlése nem frissítési megoldás. Kiadási kulcs nem készült, aláírt release AAB és Play-publikálás nem történt.

Nincs csatlakoztatott Android-telefon vagy futó emulátor. Fizikai Android, valódi Windows, telefonos TalkBack, rendszerbillentyűzet és telepítés/frissítés nincs sikeresként beállítva. A tulajdonosi grafikai elfogadás a származtatott kivágásoknál még szükséges a véglegesítéshez. Hiányzó kezdő katalóguselem nincs: 5+5+5 valós kép szerepel; nincs helykitöltő másolat.

Rövid kezdő útmutató és telefonos ellenőrzőlista: [kiprobalas-hu.md](kiprobalas-hu.md). Exportálj mentést, ellenőrizd a tényleges fájlt, próbáld a választás → mentés → főoldal/kaland/profil → újraindítás → export/import → korábbi Studio utat HU/EN nyelven és nagy rendszerbetűvel. Az alkalmazásazonosító változatlan: `com.example.mennyiment`. Nincs main merge, adattörlés, Play-feltöltés vagy publikálás.
