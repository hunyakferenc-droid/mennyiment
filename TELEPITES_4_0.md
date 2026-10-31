# MennyiMent? 4.0 – első integrált fejlesztési csomag

A beküldött projektből készült; nem tiszta újraírás. A korábbi főprogram, pénzügyi központ, Menti XP, avatar, naptár és statisztika megmarad.

## Új, működésre tervezett funkció

- Közérzetnapló: napi hangulat (1–5), alvásminőség (1–5), másnapossági tünetek (0–4), szabad szöveges megjegyzés.
- Dátumválasztás múltbeli napokra, bejegyzések módosítása és törlése.
- Utolsó 60 bejegyzés megjelenítése; minden bejegyzés a telefon/böngésző helyi tárolójába mentődik.
- Főoldali belépési pont a közérzetnaplóhoz.
- A régi italnapló és többi mentési kulcs változatlan.

## Mentési kulcs

Új: `mennyiment_wellbeing_v1` (`SharedPreferences`). Nem módosítja a `mennyiment_drinks_v1` és a korábbi avatarkulcsok tartalmát.

## Telepítés

1. A működő projekt teljes mappájáról készíts másolatot (ne csak a `lib` mappáról).
2. A csomag `lib/main.dart`, `lib/wellbeing_journal.dart`, `test/widget_test.dart` fájljait másold át a működő projekted azonos útvonalaiba. Ha a csomag teljes projektjét akarod használni, tartalmazza a szükséges alapfájlokat és Menti-képeket is.
3. Nyisd meg VS Code-ban a projektgyökeret.
4. Futtasd:

```powershell
cd "D:\mobil app\mennyiment"
& "C:\flutter\bin\flutter.bat" pub get
& "C:\flutter\bin\flutter.bat" analyze
& "C:\flutter\bin\flutter.bat" test
& "C:\flutter\bin\flutter.bat" run -d chrome
```

## Korlátok

- A kód a feltöltött RAR forrásából készült, de ebben a környezetben **nem volt telepített Flutter SDK**, így tényleges fordítás és Flutter-tesztfuttatás még nem történt.
- Az adatok jelenleg eszközön/böngészőn tárolódnak. Ez **nem felhőmentés**. A böngésző adatainak törlése adatvesztést okozhat.
- A hiányos italárak miatt a költés csak ismert részösszeg, az önbevallásos hangulatadatokból nem állítunk egészségügyi diagnózist vagy ok-okozati kapcsolatot.
- A közösségi modul, fiókrendszer, felhőszinkron és valóban réteges karakteranimáció még **nincs** ebben a csomagban.
- A régi `main_backup.dart.dart` fájlt nem tettem a kiadási csomagba, mert korábbi kódverziót tartalmaz; külön archiváld, ha szükséges.
