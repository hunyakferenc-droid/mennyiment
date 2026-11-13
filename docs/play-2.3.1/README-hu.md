# Google Play-felkészítési dosszié – 2.3.1+34

Ellenőrzés dátuma: 2026. november 13. **Tervezetek, nem benyújtott Play-adatok.** Nem történt Play-feltöltés, díjfizetés, szerződéselfogadás vagy publikálás. Az ellenőrzött forráscommit és a csomagok a végső [fejlesztési jelentésben](../2.3.1-play-preparation-hu.md) szerepelnek.

Alap: eb445a770916320c7092715d5152a3ae86784938, a lezárt #37 Menti-kalandok. A korábbi #36 naplószerkesztés és #37 kalandok nem épültek újra. Külön ág: feature/mennyiment-2-3-1-play-preparation, külön munkakönyvtár.

- [Áruházi szövegtervezetek](store-listing-hu.md)
- [Adatkezelési tájékoztató tervezete](privacy-draft-hu.md)
- [Data safety válaszjavaslatok és kódindoklás](data-safety-hu.md)
- [Android release és aláírás](android-release-hu.md)
- [Zárt tesztelés kezdőknek](closed-test-hu.md)
- [Hiányzó tulajdonosi döntések](owner-decisions-hu.md)
- [Tényleges képek offline galériája](../images/menti-2.3.1-play/index.html)
- [10 áruházi képjelölt HU/EN képleírással](../images/menti-2.3.1-play/store-candidates.json)

## Mi javult a felhasználónak?

A beállításokból elérhető Adatok és biztonság, Súgó és Névjegy a meglévő funkciók működését magyarázza. A mentési gomb ugyanazt az export/import útvonalat nyitja, ugyanazzal a visszaállítás utáni alkalmazásfrissítéssel. A Névjegy a futó csomag verzióját és buildszámát olvassa, nem kézzel másolt fejlesztési címkét mutat.

Az útmutató reggel is gyorsan elérhető: megkülönbözteti a hiányzó és 0 Ft-os árat, az önbevallást és az igazolt eseményt, a helyi fájlos mentést és az esetleges Android-rendszermentést. Nincs új adatkulcs, adattörlés, fiókrendszer, analitika vagy jutalmazási szabály. Karakterképek és opcióazonosítók megmaradnak.

## Ellenőrzési határok

A Flutter-tesztek, analyzer, lokalizáció, webbuild, debug APK és a valós Chrome-próba friss eredménye a végső jelentésben található. A kiadási aláírás hiánya szándékosan megakadályozza a release buildet; ez nem aláírt AAB. A negatív release-ellenőrzések nem helyettesítik a későbbi, valódi feltöltőkulccsal készített AAB ellenőrzését. Fizikai Android- és valódi Windows-próba külön jelölt, nem vélelmezett eredmény.

## Hivatalos források

A részanyagok a vonatkozó állítás mellett hivatkoznak a Google forrásaira. Az ellenőrzési dátum a fenti dátum; a benyújtás napján a tulajdonosnak ismét ellenőriznie kell a Console aktuális követelményeit. A Play Console felületét és a fiókadatokat nem nyitottuk meg.
