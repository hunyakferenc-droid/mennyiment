# Automatikus ellenőrzés és telefonos jóváhagyás

## Működés

A `.github/workflows/flutter-ci.yml` minden `main` ágra célzó PR megnyitásakor, új commitjakor és újranyitásakor, valamint minden `main` push esetén elindul. Más ág közvetlen push-a és címke létrehozása nem indítja. Azonos PR új futása megszakítja az előzőt.

A rögzített Flutter **3.47.7 stable**, Dart **3.13.5** megfelel a `pubspec.yaml` ^3.13.5 és a lockfile Flutter >=3.44.0 követelményének. A projekt `.metadata` revisionje is a 3.47.7 kiadásra mutat. SDK-frissítést külön PR-ban, a két SDK-korlát és a teljes ellenőrzés vizsgálatával végezzünk.

Ubuntu 24.04 futtatón, legfeljebb 30 perc alatt:
1. Forrás letöltése, SDK telepítése és verziók kiírása.
2. `flutter pub get`
3. `flutter analyze`
4. `flutter test --concurrency=2`
5. `flutter build web`

Az analyze hibája után a teszt és a web build is lefut, ha a függőségek telepítése sikerült. A hibákat nem nyeljük el: a job és a PR ellenőrzése piros lesz. A futás Summary lapján lépésenkénti táblázat látható; az átugrott lépés nem számít sikernek. SDK-/checkout-hibánál a megfelelő lépés naplója mutatja az okot.

## Jogosultságok, adatok és cache

- A workflow tokenje csak `contents: read`; a checkout nem menti el a GitHub-hitelesítő adatot. Nincs `pull_request_target`, secrets-hivatkozás vagy írási jogosultság.
- Nincs artifact-, naplófájl- vagy buildfeltöltési lépés, deploy, release, tagmódosítás vagy automatikus merge.
- Csak a Flutter SDK és a Pub csomagcache kerül gyorsítótárba. A setup action kulcsai tartalmazzák az SDK/platform adatait, a Pub cache kulcsa a `pubspec.lock` hashét is. A munkakönyvtár, `build/web`, felhasználói preferenciák és `.env` fájlok nem kerülnek cache-be.
- A GitHub a parancsok konzolkimenetét tárolja; tesztekhez csak mesterséges adatokat használjunk. Valós naplóadatot, exportot, privát konfigurációt vagy kulcsot ne commitoljunk és ne írjunk a tesztnaplóba. Fork PR-ok is olvashatnak elérhető alapági cache-t, ezért abban soha ne legyen titok.
- A külső actionök teljes commit SHA-ra vannak rögzítve; a Flutter setup belső cache actionje saját upstream verziókövetést használ.

## Ellenőrzés telefonról

1. Nyisd meg a PR-t GitHub Mobile-ban vagy mobilböngészőben, és ellenőrizd: célág `main`, forráság `feature/github-actions-ci`.
2. A **Files changed** nézetben olvasd át a workflow-t és ezt a dokumentumot. Külön ellenőrizd az eseményeket, SDK-t, parancsokat és jogosultságokat.
3. A **Checks / View checks / Details** hivatkozáson nyisd meg a **Flutter CI / Flutter analyze, test, web** futást. Ha az app nem mutat részletes naplót, nyisd meg böngészőben.
4. Várd meg a legújabb PR-commit futásának végét. A négy parancs legyen `success`; piros, megszakított vagy átugrott ellenőrzés mellett ne hagyd jóvá.
5. Hibánál nyisd ki a piros lépést. Infrastruktúrahiba után megfelelő jogosultsággal **Re-run failed jobs** használható; kódhiba javításához új commit kell, amely automatikusan új ellenőrzést indít. Külső közreműködő futása GitHub-jóváhagyásra várhat: előbb vizsgáld meg a kódot és a workflow-t.
6. Másik, jogosult reviewer a **Review changes → Approve → Submit review** művelettel hagyhatja jóvá. Saját PR-t a szerző nem tud jóváhagyni; ilyenkor másik reviewert kell bevonni.
7. A jóváhagyás nem olvaszt be. A manuális merge külön, emberi döntés; a CI ezt nem végzi el. Beolvasztás után a `main` push külön CI-futást indít.

## Opcionális kötelező ellenőrzés

A workflow önmagában nem tiltja a hibás PR manuális beolvasztását. Egy admin a GitHub webes Settings → Rules → Rulesets (vagy Branches → protection) felületén a `main` ágra kötelezővé teheti a PR-t, a review-t és a **Flutter analyze, test, web** ellenőrzést. A pontos checknév az első futás után választható ki. Ez a változtatás nem állít át repository-szabályokat.

## Ellenőrzés a fejlesztés során

A távoli main vizsgálatakor nem volt meglévő GitHub Actions workflow. A YAML szintaxisa és az események/jogosultságok/parancsok statikus ellenőrzése helyben történt. A helyi környezetben nincs Flutter SDK, és a hálózati proxy nem elérhető, ezért helyi Flutter-teszt és actionlint-letöltés nem lehetséges. A tényleges GitHub Actions futás eredményét a PR Checks nézetében kell ellenőrizni; ez a dokumentum nem állít helyi sikeres Flutter-futást.
