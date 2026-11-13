# Zárt Play-teszt – kezdőknek, kézi tulajdonosi útmutató

Ez nem végrehajtott feltöltés. Play-fiókba nem léptünk be, nem fizettünk, nem fogadtunk el szerződést és nem küldtünk tesztelői meghívót.

## Először a letöltött csomaggal próbálj

A Web ZIP teljes kibontása után `INDITAS.cmd`, majd Chrome: http://127.0.0.1:7357. Python és Flutter nem szükséges. Maradj ugyanabban a böngészőprofilban, ugyanazon a hoston és porton. A debug APK technikai próba, nem feltöltendő Play-kiadás; az eltérő aláírás miatt ne távolíts el meglévő appot. [Részletes Windows-útmutató](../2.2.6-windows-hu.md), [aláírási feltételek](android-release-hu.md).

## Mi kell az első zárt teszthez?

1. **Tulajdonosi adatok és fiók:** ismert kiadó, elérhetőség, fióktípus és a Console által kért azonosítás. Díjfizetés és szerződéselfogadás kizárólag a tulajdonos feladata.
2. **Végleges csomagidentitás és aláírás:** döntés az alkalmazásazonosítóról, biztonságosan kezelt feltöltőkulcs, App Signing-terv és ténylegesen sikeres, ellenőrzött release AAB. A jelenlegi kulcs nélküli projekt szándékosan nem készít ilyet.
3. **Adatkezelés:** végleges kiadói/privacy adatok, aktív nyilvános privacy URL, appon belüli egyező tájékoztatás; jóváhagyott Data safety, egészségapp-nyilatkozat, reklámnyilatkozat és tartalmi kérdőív.
4. **Áruházi anyagok:** jóváhagyott leírás, megfelelő ikon és feature graphic, ellenőrzött képjelöltek. A webes képeket külön kell kezelni a fizikai Android-próbától.
5. **Készülékes próba:** indítás, visszagomb, billentyűzet, 200%-os szöveg, HU/EN, korhatár, mentés/visszaállítás, újraindítás és adatmegőrző frissítés. Release/native 16 KB megfelelőség is ellenőrizendő.

## Tulajdonos által végrehajtandó Console-lépések

- Hozd létre vagy válaszd ki a megfelelő appot; ellenőrizd a csomagazonosítót és az országokat. A későbbi identitásváltás nem rutin frissítés.
- A Console tesztelési részében hozz létre zárt tesztcsatornát. A fiókod által elérhető lépéseket kövesd; a képernyőnevek változhatnak.
- Állíts össze valódi tesztelői listát vagy saját Google-csoportot. Itt nem találtunk ki e-mail-címeket és nem állítottunk be külső listát.
- Csak az ellenőrzött, megfelelő kulcsú release AAB-t válaszd ki. Ellenőrizd a verziókódot, a kiadási megjegyzést és a Console figyelmeztetéseit. Ne a debug APK ZIP-et töltsd fel.
- Töltsd ki a szükséges tartalmi és áruházi adatokat a jóváhagyott tervezetekből. Egy megírt dosszié nem jelenti, hogy a Console már elfogadta őket.
- A Console ténylegesen létrejött jelentkezési linkjét add át a kiválasztott tesztelőknek. Ők a megfelelő Google-fiókkal csatlakozzanak és a Playről telepítsenek. Ezt a linket előre nem találjuk ki.
- Rögzíts valódi visszajelzéseket és hibajavításokat. Ne állíts készülékes próbát vagy tesztelői aktivitást pusztán egy build alapján.

[Google: belső, zárt és nyílt teszt beállítása](https://support.google.com/googleplay/android-developer/answer/9845334).

## Külön követelmény a production hozzáféréshez

A 2023. november 13. után létrehozott személyes fejlesztői fiókoknál a jelenlegi szabály legalább 12, folyamatosan legalább 14 napja feliratkozott zárt tesztelőt követel meg a production hozzáférés kérelmezése előtt. Ez nem a zárt teszt elindításának általános előfeltétele, és nem automatikus production-jóváhagyás. A fiók tényleges típusát, dátumát és Console-kapuit a tulajdonosnak kell ellenőriznie. [Google: új személyes fiókok tesztelési követelményei](https://support.google.com/googleplay/android-developer/answer/14151465).

## Rövid tesztelői ellenőrzőlista

- Van saját fájlos mentés a régi telepítésről; nem töröltél appot az aláírás megkerülésére.
- Névjegy valódi verzió/build adatot mutat; az Adatok és biztonság érthető.
- Ismeretlen ár és valódi 0 Ft különbözik; szerkesztés csak mentéskor változtat.
- Kalandnál a dupla aktiválás nem dupláz, az újranyitás nem játssza újra a jutalmat.
- HU/EN, nagy betűk, billentyűzet és visszagomb mellett is elérhetők a vezérlők.
- Külön próbaadatokkal export, fájl meglétének ellenőrzése, importelőnézet és visszaállítás; hibás fájl ne írjon felül adatot.
- Kiskorú módban a korlátozások megmaradnak, korábbi adatok nem tűnnek el.
