# MennyiMent? 3.3.0+46 – rövid kipróbálási útmutató

## Android REVIEW

A REVIEW külön alkalmazás: com.example.mennyiment.review, neve MennyiMent? REVIEW,
ikonján R-jelölés. A normál MennyiMent? adatai külön Android-sandboxban maradnak.

1. Töltsd le az ellenőrzött REVIEW APK-t. Korábbi REVIEW frissítése előtt ellenőrizni
   kell az aláírási kompatibilitást. A #48 és #50 eredeti CI-APK-jának kulcsai eltérnek;
   egy új CI debug-kulcsa nem helyettesíti az eredetit. **Ne törölj alkalmazást vagy adatot
   aláírási hiba megkerülésére.** Megfelelő eredeti kulccsal készült build vagy külön
   tesztkészülék szükséges. A tanúsítványból a magánkulcs nem állítható elő.
2. Első használat: válassz nyelvet, járd végig a meglévő korhatárfolyamatot,
   válassz saját Mentit és nevet. Magyarul és angolul is ellenőrizd a visszalépést.
3. Rögzíts naplót 0 Ft-tal, majd külön hiányzó árral. Jelölj kedvencet és nyisd újra
   az italválasztót; a csillag maradjon. Nézd meg a statisztikát. Nagy rendszerbetűvel,
   képernyő-billentyűzettel is legyen elérhető a Mentés.
4. Napi önellenőrzés után ellenőrizd az XP-t; az ital naplózása nem ad XP-t.
5. Fitneszklub: teljesíts Ritmust vagy kártyamenetet. Ismételd aznap: egy napi jelölés
   maradjon. Háttérbe küldés után térj vissza; félbehagyott menet alkalmazásleállítás
   után ne jelöljön napot. Elmentett rekord és napok újraindítás után maradjanak meg.
6. Repülő módban próbáld a helyi naplózást, kedvenceket, statisztikát és a klubot.
   Egy kiválasztott felhős fájlszolgáltató vagy Android-rendszermentés külön internetet igényelhet.

A fizikai telefonos telepítés és frissítés csak tényleges próba után jelölhető késznek.
Az emulátor nem helyettesíti az adott telefon billentyűzetét, fájlválasztóját és háttérkezelését.

## Hét nap és éjfél kipróbálása várakozás nélkül

A klub alján a Hét nap kipróbálása külön próbaadatokkal gomb nyitja a PRÓBAMÓDOT.
Külön mentési kulcsot és virtuális dátumot használ. A saját rekordokat és a készülék óráját
nem módosítja. Következő próbanap gombbal léptess; kihagyásért nem vész el eredmény.
Kártyamenet közben egy kártya után is léptethetsz próbanapot: a menet az új, befejezéskori
napra számítson. Aznapi ismétlés ne adjon második jelölést. Hét jelölés után új kihívás
indítható; ugyanaz a nap az új kihívásban sem számít újra. Frissítés után a próbaadatok
maradjanak meg, visszalépve a saját klubban az eredeti adatokat lásd.

## Ellenőrzött, újraépített baseline útvonal

A külön baseline-artifact a #50 forrásából ugyanazzal a CI-debugkulccsal újraépített
3.2.0+45 APK. **Nem az eredeti, korábban terjesztett #50 APK.** Friss, erre alkalmas
külön tesztkészüléken előbb ez telepíthető, adatok rögzíthetők, majd a hozzá tartozó,
azonos CI-futású 3.3.0+46 REVIEW-val törlés nélküli frissítés próbálható.
A két konkrét fájl aláírását/verzióját a compatible-rebuilt-route.json rögzíti.
Már telepített újabb változatot ne próbálj régebbire kényszeríteni.

## AAB és normál változat

Az app-release-UNSIGNED.aab release módban fordított, aláíratlan előkészítő csomag,
nem telefonra telepíthető APK és nem Play-feltöltésre kész állomány. A normál
com.example.mennyiment változatban a kísérleti klub, videók és próbaóra továbbra sincsenek
bekapcsolva. Titkot ne tegyél a repóba vagy a próbajegyzőkönyvbe.

## Windows webes csomag

A friss REVIEW Web ZIP kibontása után INDITAS.cmd indítja a szervert. Python és Flutter
nem szükséges. Chrome-cím mindig http://127.0.0.1:7357; a korábbi szervert előbb zárd be,
a böngészőadatokat ne töröld. A forrásból indítás külön Flutter-környezetet igényel;
a repository tool/windows/FORRAS_INDITAS.cmd ellenőrzi és magyarázza a hiányokat.
