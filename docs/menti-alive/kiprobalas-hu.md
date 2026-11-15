# MennyiMent? 2.8.0+40 – normál alkalmazás és Menti Alive REVIEW

Két külön csomag készül. A **normál alkalmazásban 0 jóváhagyott videó** van. A külön **REVIEW fejlesztői előnézetben 3 tényleges videójelölt** játszható le. Ezek továbbra is jóváhagyásra várnak.

## Kész web ZIP Windows alatt – Python és Flutter nélkül

1. A választott normál vagy REVIEW ZIP-et csomagold ki külön, ékezetmentes mappába (például `C:\dev\mennyiment-normal` és `C:\dev\menti-alive-review`). Ne a ZIP ablakából indíts.
2. Indítsd az `INDITAS.cmd` fájlt. Hagyd nyitva az ablakot. Python nem kell; az indító ellenőrzi a környezetet és jelzi a foglalt portot.
3. Mindig **http://127.0.0.1:7357**. A `file://` megnyitás nem indítja a Flutter-alkalmazást. Eltérő host/port vagy böngészőprofil külön tárolást jelent.
4. Csomagváltáskor Ctrl+C-vel állítsd le az előző szervert, majd indítsd a másik mappából. A böngészőadatokat ne töröld. Szükség esetén Ctrl+F5.

## A három valódi jelölt kipróbálása

- A REVIEW fejléc és „Jóváhagyásra váró média” felirat különbözteti meg a próbát. HU/EN csak az előnézet nyelvét váltja.
- Ha ugyanazon hoston/profilban van elmentett teljes kinézet, az látható a mentett karakter sorában. Ez a sor csak olvas.
- „A három fiú fesztiváljelölt megtekintése” ideiglenesen kiválasztja a jelölt kinézetet. Nem menti át az alkalmazásban kiválasztott Mentit.
- Üdvözlés, Kacsintás, Gratuláció → Lejátszás, majd Újraindítás és Leállítás. Az eredeti PNG a videó mellett összehasonlítható. Egy időben egy videó játszik.
- Válassz lány vagy semleges kinézetet: nincs hozzá videóhelyettesítés; a saját eredeti PNG maradjon. A mentett karakter nem változhat.
- A videókapcsoló és a rendszer csökkentett mozgása állítsa le a mozgást. Háttérbe helyezés után ne induljon el magától újra.
- A mérföldkő/önkontroll gombok motorbemeneti próbák. Nem írnak XP-t vagy teljesítést. A légzésreakcióhoz nincs ebben a háromklipes csomagban média, ezért eredeti PNG a helyes eredmény.
- A klipek megtartják a forrás beégetett stúdióhátterét. A közös keret nem háttéreltávolítás; jogi, tulajdonosi és vizuális jóváhagyás még szükséges.

## Flutter-forrás Windows alatt

Flutter 3.47.7, Git és Chrome szükséges. A forrás és az SDK ékezetmentes útvonalra kerüljön, például `C:\dev\mennyiment` és `C:\src\flutter`.

```powershell
git clone --branch feature/menti-alive https://github.com/hunyakferenc-droid/mennyiment.git C:\dev\mennyiment
Set-Location C:\dev\mennyiment
$env:Path = 'C:\src\flutter\bin;' + $env:Path
flutter doctor
flutter pub get
flutter gen-l10n
flutter run -d chrome --web-hostname 127.0.0.1 --web-port 7357
```

Ez a normál app. Ne klónozz rá meglévő helyi munkára. A külön REVIEW-build fejlesztői Python-szkriptje ideiglenes munkafában csomagolja a jelölteket, a normál pubspec módosítása nélkül:

```powershell
python tool/build_menti_alive_preview.py --platform web --output C:\dev\menti-alive-review
```

**A kész REVIEW ZIP indításához Python nem kell.** Ha nincs Python, használd a kész ZIP-et. A fejlesztői buildszkript egy már commitolt forrást fordít; az output mappa legyen üres. A feldolgozás újrafuttatásához FFmpeg/ffprobe és a leltári hash alapján ellenőrzött eredeti videók szükségesek; új Higgsfield-generálás nincs.

## Android – előbb mentés és aláírás-ellenőrzés

A normál és a REVIEW debug APK alkalmazásazonosítója változatlan: `com.example.mennyiment`. A REVIEW csak fejlesztői előnézet. **Azonos alkalmazásazonosítója miatt ugyanazon készüléken a normál alkalmazás felületét lecserélné; nem települ mellé külön appként.** Ezért elsősorban a kész webes REVIEW-csomagot vagy elkülönített tesztkészüléket használj. A normál apphoz visszatéréshez megfelelő verziójú, azonos aláírású normál APK szükséges. Ne telepíts inkompatibilis APK-t a telefonod meglévő alkalmazására.

Frissítés előtt készíts fájlos mentést a normál alkalmazásban. Közvetlen frissítéshez azonos tanúsítvány kell; külön CI-futások debugkulcsa eltérhet. A jelentés és a csomag build-info.txt fájlja közli a konkrét aláírót. Eltérésnél ne töröld a régi appot: a korábbi privát kulccsal fordítás vagy külön tesztkészülék szükséges. Kiadási kulcs nem készült; ezek nem Play-kiadások.

A REVIEW nézet nem ment profilt, nyelvet, kapcsolót, XP-t vagy naplót. Az alkalmazásváltás és a valódi Android-fájlkezelő működése készüléken külön ellenőrzendő. A widget- vagy Chrome-teszt nem fizikai Android-próba.
