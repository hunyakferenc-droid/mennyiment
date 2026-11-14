# MennyiMent? 2.5.0+37 – három teljes Menti-kinézet kipróbálása

Ez külön kísérlet, nem tulajdonosilag jóváhagyott új látvány. Csak három teljes kinézet van; a korábbi karakterrendszer és mentései megmaradnak. Nincs új XP-szabály, vásárlás vagy háttérválasztó.

## Windows – kész Web ZIP

1. A ZIP teljes tartalmát bontsd ki egy új mappába. A benne levő fájlokat együtt tartsd.
2. Kattints duplán az `INDITAS.cmd` fájlra. A mellékelt PowerShell-indító helyi kiszolgálót indít; **Python nem szükséges**. A kiszolgáló ablakát hagyd nyitva.
3. Mindig a `http://127.0.0.1:7357` címet használd ugyanabban a böngészőben/profilban. Más host vagy port külön helyi tárolást jelent. Ha a csomag cseréje után régi felület marad, Ctrl+F5-tel töltsd újra az oldalt; böngészőadat-törlés nem szükséges. Az indító nem töröl böngészőadatot. Foglalt portnál érthető hibával megáll; ne indíts két példányt egyszerre.
4. Bezáráshoz a kiszolgáló ablakában Ctrl+C. A ZIP megnyitása `file://` címen nem támogatott indítás.

## Windows – Flutter-forrás

Telepített Flutter 3.47.7, Git és Chrome szükséges. A forrás gyökerében terminálból:

```powershell
flutter pub get
flutter gen-l10n
flutter run -d chrome --web-hostname 127.0.0.1 --web-port 7357
```

Ez forrásból fordít; a kész Web ZIP használatához nem kell Flutter. Valódi Windows-gépes ellenőrzést csak külön elvégzett próbából állítunk.

## Rövid próba

1. Első indításkor a megszokott nyelv-, korhatár- és profilútvonalat használd. A régi Menti magától nem változik meg.
2. A főoldali további műveleteknél nyisd meg a Beállításokat, azon belül **Teljes Menti-kinézetek**. A régi Studio fejlécében is van galéria ikon; mentetlen régi szerkesztésnél előbb ments vagy vond vissza.
3. Válaszd sorban a Fiú, Lány, Semleges alapot. Mindegyik azonos egyszerű háttéren jelenik meg. A nagyító ugyanazt a teljes képet mutatja.
4. Válassz másik mintát, majd Mégse vagy Vissza: az elvetési megerősítés után az elmentett kinézet maradjon meg.
5. Válassz mintát és Ments. Ellenőrizd a főoldalt, profilt és kalandtérképet. Töltsd újra az alkalmazást: ugyanaz maradjon kiválasztva.
6. A galériában válaszd **Korábbi összeállítás használata**, majd Mentés. Az eredeti karaktered és feloldásaid legyenek meg. Ismét kiválasztható bármelyik teljes minta.
7. A meglévő Mentés/visszaállítás nézetben készíts fájlt. Válts másik mintára, majd a fájlt az előnézet és megerősítés után állítsd vissza. A mentett minta térjen vissza. Régebbi, új kulcs nélküli mentés nem törli az új választást.
8. HU/EN, nagy rendszerbetű, keskeny kijelző: görgetés, nagyító, Mentés és Mégse maradjon elérhető. Csökkentett mozgással a kijelölési átmenet is álljon le.
9. A három PNG-hez nincs külön pislogás, beszéd vagy arcdeformálás.

## Android debug APK és adatmegőrzés

A debug APK nem Play-kiadás. Az alkalmazásazonosító változatlan: `com.example.mennyiment`. Frissítéshez a telepített és az új APK aláíró tanúsítványának egyeznie kell, és a verziókódnak megfelelőnek kell lennie. A külön CI-futások debugkulcsa eltérhet. A konkrét új csomag tanúsítványát az átadási jelentés rögzíti; ez nem bizonyítja a telefonon levő példánnyal való egyezést.

Eltérő aláírásnál ne töröld a meglévő alkalmazást. Az eredeti aláíró debugkulccsal újraépített APK vagy előzetesen ellenőrzött export/import útvonal szükséges. A telefonos telepítést, adatmegőrző frissítést és grafikai teljesítményt valódi készüléken kell ellenőrizni.
