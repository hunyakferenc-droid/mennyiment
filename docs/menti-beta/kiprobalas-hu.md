# MennyiMent? 2.9.0+41 – béta kipróbálás

## Kész web ZIP Windows 10/11 alatt

1. A normál és REVIEW ZIP-et külön, ékezetmentes mappába bontsd ki. Ne a ZIP ablakából indítsd.
2. Nyisd meg az `INDITAS.cmd` fájlt. Python és Flutter nem szükséges. Az ablak maradjon nyitva.
3. Chrome: **http://127.0.0.1:7357**. Mindig ugyanaz a host, port és böngészőprofil; böngészőadatot ne törölj.
4. Csomagváltáskor Ctrl+C-vel állítsd le az előző szervert. A foglalt portot az indító jelzi; ne válts másik portra.
5. Normál app: nyelv → életkori nyilatkozat → fiú/lány/semleges Menti → név → mentés. Kiskorúként csak az életmód- és karakterfunkciók érhetők el.
6. Felnőtt módban naplózz, majd szerkeszd a bejegyzést. A hiányzó ár nem 0 Ft; a 0 ismert ár. Visszalépéskor a mentetlen szerkesztést a megerősítéssel hagyhatod el.
7. Napi önellenőrzésért járhat XP; ivásért nem. A kinézet feloldása nem költi el az XP-t. A teljes Mentit a Menti-gyűjteményben váltod, a korábbi réteges karakter a Studio útvonalon marad.
8. A menü Mentés és visszaállítás oldalán készíts fájlos mentést. Az import előnézet és megerősítés után ír; hibás fájlt ne próbálj kézzel javítva ráerőltetni.
9. Újratöltés után ellenőrizd a nevet, Mentit, naplót és XP-t.

## REVIEW

Külön fejlesztői előnézet, három jóváhagyatlan fiú fesztiválklippel. HU/EN → jelöltek → lejátszás/újraindítás/leállítás. Másik 17 kinézetnél saját PNG, helyettesítő videó nélkül. A rendszer mozgáscsökkentése és a videókapcsoló érvényes. A normál alkalmazásban 0 aktivált klip van. A háttér a forrásba beégetett, nem lett kivágva vagy egységesre cserélve.

Androidon a **normál** app `com.example.mennyiment`, a **REVIEW** `com.example.mennyiment.review`, neve **Menti Beta REVIEW**, ikonja R jelzéses. Külön Android-adatterületen élnek: a REVIEW nem olvassa a normál Mentit vagy naplót. Ez szándékos; a választás ideiglenes. Ne importálj valós személyes mentést a fejlesztői előnézetbe.

A korábbi 2.8 REVIEW még a normál azonosítót használta: azt nem tekintjük külön telepítésnek. A mostani külön azonosító nem költözteti át a régi telepítés adatait.

## Android-frissítés

A debug APK nem Play-kiadás. Normál app frissítéséhez egyező alkalmazásazonosító és tanúsítvány kell. Minden csomaghoz build-info és SHA-256 tartozik. A CI debugkulcsa futásonként eltérhet; a külön REVIEW azonosító önmagában nem oldja meg a normál aláíráseltérést.

Előbb fájlos mentés. Eltérő aláírásnál **ne töröld az alkalmazást, ne törölj adatot és ne kerüld meg a rendszer védelmét**. A korábbi privát kulccsal fordítás vagy elkülönített tesztkészülék szükséges. Nincs új release-kulcs.

## Flutter-forrás

Flutter 3.47.7, Git, Chrome; `flutter doctor`, `flutter pub get`, `flutter gen-l10n`, majd `flutter run -d chrome --web-hostname 127.0.0.1 --web-port 7357`. A forrás és SDK ékezetmentes útvonalon legyen. Az izolált REVIEW csomag: `python tool/build_menti_alive_preview.py --platform web --output C:\dev\menti-review` (üres output). A fejlesztői buildszkript Python-függése nem vonatkozik a kész ZIP indítására.
