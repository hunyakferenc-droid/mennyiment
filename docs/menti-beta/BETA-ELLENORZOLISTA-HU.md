# Mi szükséges a valódi béta-próbához?

- [ ] Sikeres analyzer, teljes regresszió (a korábbi 1176 teszt megőrzésével), 1010 HU/EN kulcs és generált lokalizáció.
- [ ] Forráscommittal és hash-sel megjelölt normál/REVIEW web és debug APK.
- [ ] Valódi Windows-futón ZIP-kibontás, INDITAS.cmd, Chrome, HU/EN, mentés/újratöltés, REVIEW-videók. Ez automatizált Windows, nem kezdő felhasználó kézi próbája.
- [ ] Android-emulátor: első indítás/korhatár/karakter, napló létrehozás/szerkesztés, XP egyszeriség, fájlrendszeres export/import, hibás mentés, újratöltés és külön REVIEW sandbox.
- [ ] API 24 minimum és API 36 target tényleges APK-ból; emulátor API 35 eredményét nem kiterjeszteni minden Android-verzióra. Fizikai gyenge készülék, OEM-billentyűzet/fájlválasztó/visszagomb külön kézi próba.
- [ ] 320/360/390/430 logikai px, HU/EN, 200% szöveg; a widget és Chrome/natív bizonyítékot külön jelölni.
- [ ] REVIEW címke, R ikon, eltérő com.example.mennyiment.review ID; normál ID változatlan; telepítések elkülönülnek.
- [ ] Előzetes fájlos mentés; normál frissítés csak egyező tanúsítvánnyal. Eltérésnél nincs uninstall, clear-data vagy aláírásmegkerülés.
- [ ] Csomagméret, klipméret és inicializálási idők; natív memória/codec mérések pontos környezettel. Becsült RGBA-képkocka mérete nem teljes dekóder-RAM.
- [ ] Jóváhagyatlan klip csak REVIEW. Rendszeres mozgáscsökkentés, leállítás, háttér/visszatérés, hibánál saját PNG; másik kinézethez nincs idegen videó.
- [ ] Offline működés, meglévő engedélykészlet; helyi SharedPreferences és export titkosítási garancia nélkül; internet csak fejlesztői eszköz/letöltés, debug engine és opcionális külső hivatkozások szerint.
- [ ] Sérült régi mentés nem írható automatikusan felül; XP/feloldás/napló/profil/korhatár megőrzési próbák.
- [ ] Tulajdonosi döntés: végleges applicationId, adatkezelő neve/elérhetősége, adatvédelmi URL, célközönség/Play korhatár, grafikai/videós jogok. Ezeket nem találjuk ki.
- [ ] Kiadási aláírás külső titkokból, hiányában világos hiba; debug aláírású build nem publikálható kiadás. Új release-kulcs és release AAB ebben a munkában nincs.

## A normál applicationId hosszú távú döntése

A `com.example.mennyiment` szintaktikailag Android-azonosító, de példa-névtér: tulajdonoshoz tartozó stabil név választása javasolt az első Play-regisztráció előtt. Nem állítjuk, hogy a Google névütközés vagy tulajdonosi ellenőrzés nélkül elfogadja. A normál azonosítót nem változtattuk meg.

Az Android-frissítéshez ugyanaz az applicationId és kompatibilis aláírás szükséges. Az ID-váltás külön alkalmazás, külön sandbox és külön Play-bejegyzés; nem automatikus adatfrissítés. Már kiadott Play-appnál az ID nem cserélhető. Ha a tulajdonos később új ID-t választ, külön verziózott export/import terv, régi app megőrzése, régi/új csomag külön megnevezése és kézi adatellenőrzés kell. A REVIEW külön neve nem a normál ID migrációja.

Hivatalos kiinduló dokumentáció: https://developer.android.com/build/configure-app-module#set-application-id és https://developer.android.com/studio/publish/app-signing . A béta debug csomagok nem helyettesítik a Play App Signing és a kiadási kulcs tulajdonosi döntését.
