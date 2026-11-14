# MennyiMent? 2.6.0+38 – rövid kipróbálás

A Web ZIP és a debug APK kipróbálási csomag. Nem Google Play-kiadás.

## Kész Web ZIP Windows alatt – Flutter és Python nélkül

1. Töltsd le a jelentésben hivatkozott, azonos forráscommithoz tartozó webes artifact ZIP-et. Csomagold ki például a `C:\dev\mennyiment-web` mappába. Ne a ZIP ablakából indíts.
2. Kattints az `INDITAS.cmd` fájlra. A mellékelt PowerShell-indító ellenőrzi a környezetet, és érthető hibát jelez például foglalt portnál. Python nem kell. Hagyd nyitva az indító ablakát.
3. Chrome-ban mindig ugyanazt a címet használd: **http://127.0.0.1:7357**. Az eltérő host, port vagy böngészőprofil külön tárolást jelent. A `file://` megnyitás nem indítja az alkalmazást.
4. Bezárás: az indító ablakában Ctrl+C. Új csomagra cserélés előtt állítsd le a szervert, és őrizd meg a régi könyvtárat. A böngészőadatokat ne töröld. Elavult felületnél Ctrl+F5 használható.

PowerShellből, ugyanebben a mappában:

```powershell
Set-Location C:\dev\mennyiment-web
.\INDITAS.cmd
```

## Flutter-forrás Windows alatt – ékezetmentes útvonalakkal

Telepíts Git-et, Chrome-ot és Flutter 3.47.7-et például a `C:\src\flutter` mappába. A projektet is **ékezetmentes útvonalra** tedd, például `C:\dev\mennyiment`. A felhasználói Letöltések/Asztal vagy ékezetes projektmappa helyett ezt használd, különösen Android/Gradle fordításnál.

```powershell
New-Item -ItemType Directory -Force C:\dev | Out-Null
Set-Location C:\dev
git clone --branch feature/menti-collection https://github.com/hunyakferenc-droid/mennyiment.git mennyiment
Set-Location C:\dev\mennyiment
$env:Path = 'C:\src\flutter\bin;' + $env:Path
flutter doctor
flutter pub get
flutter gen-l10n
flutter run -d chrome --web-hostname 127.0.0.1 --web-port 7357
```

Ha már létezik a forrásmappa, ne klónozz rá és ne írj felül helyi munkát. Ellenőrizd a `git status` és `git rev-parse HEAD` eredményét. A jelentés forráscommitja alapján ellenőrizhető, melyik állapotot fordítod. A kész Web ZIP-hez Flutter nem szükséges.

## Rövid ellenőrzőlista

- Új telepítés: HU/EN, korhatár, kezdő kinézet és név kiválasztása; Mentés után főoldal. Kiskorú módban az eredeti korlátozások maradjanak meg.
- Meglévő profil: a Menti ne változzon meg magától. Főoldal vagy Saját Menti → Menti-gyűjtemény.
- Fiú/Lány/Semleges szűrő; öt különböző ingyenes kezdő kinézet családonként; Összes/Megszerzett/Feloldható nézet.
- Választás → nagyító → Mégse/Vissza: az elvetés megerősítése után az eredeti mentett kép maradjon meg. Másik választás → Mentés → főoldal/profil/kalandtérkép → újratöltés: ugyanaz a kép jelenjen meg.
- A legendás kinézetek küszöbe 200 XP. A feloldás nem költ XP-t. Csak meglévő önellenőrzési/átgondolási szabályok adnak XP-t; a fogyasztás nem.
- Mentés/visszaállítás: exportálj fájlt, változtass választást, majd előnézet és megerősítés után importáld. A korábban megszerzett kinézetek régebbi mentés mellett is maradjanak meg.
- Korábbi összeállítás használata → Mentés; ellenőrizd az eredeti Studio-szettet. A gyűjtemény választása visszaváltható.
- Telefonon 200%-os rendszerbetű, keskeny kijelző, visszagomb, görgetés és nagyító. Csökkentett mozgással a statikus képek ne kapjanak mesterséges mimikát vagy pislogást.

## Android, adatmegőrző frissítés

Telepítés előtt a meglévő alkalmazás saját mentési felületével készíts fájlos mentést, és ellenőrizd, hogy a fájl valóban megvan. Az alkalmazásazonosító változatlan: `com.example.mennyiment`. A közvetlen frissítéshez azonos aláíró tanúsítvány és megfelelő verziószám kell. A külön CI-futások debugkulcsa eltérhet; a konkrét APK tanúsítványát a jelentés közli.

Eltérő aláírásnál **ne töröld a meglévő alkalmazást**. Az adatmegőrző frissítéshez a korábbi debugkulccsal kell újra fordítani, vagy elkülönített tesztkészüléken kell próbálni. A kiadási aláírást külön kell konfigurálni; kiadási kulcs nem készült. Fizikai telefonos, emulátoros és valódi Windows-próba eredményét a jelentés külön jelöli.
