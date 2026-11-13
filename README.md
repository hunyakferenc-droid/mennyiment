# MennyiMent?

Flutter alkalmazás helyi italnaplóval, közérzetkövetéssel és személyre szabható
Menti karakterrel. Magyar és angol felület; a profil és a naplók helyben maradnak.

- [2.3.0+33: Menti-kalandok, jelvények és reggeli kipróbálás](docs/2.3.0-adventures-hu.md).
- [Korábbi 2.2.8+32: bejegyzésszerkesztés, árpótlás, ellenőrzések és kipróbálás](docs/2.2.8-journal-management-hu.md).
- [Korábbi 2.2.7+31: kereshető és szűrhető napló](docs/2.2.7-journal-hu.md).
- [Kezdő Windowsos útmutató: kész web ZIP vagy Flutter-forrás](docs/2.2.6-windows-hu.md).
  A ZIP-ben az `INDITAS.cmd`, a forrásban a `tool/windows/FORRAS_INDITAS.cmd`
  indítható. Python nem szükséges. Cím: **http://127.0.0.1:7357**.
- [Android debug build, adatmegőrzés és telefonos próba](docs/2.2.6-android-hu.md).
- [Márka- és fejlesztési irány](docs/MENNYIMENT_BRAND_ES_FEJLESZTESI_IRANY.md),
  [roadmap](docs/roadmap.md).

Fejlesztői környezet: Flutter **3.47.7**, Dart **3.13.5**. Ellenőrzés:

```sh
flutter pub get
flutter gen-l10n
flutter analyze
flutter test --concurrency=2
flutter build web --no-web-resources-cdn
flutter build apk --debug
```

Ez fejlesztési változat. A debug APK és a jelenlegi debug-aláírásos release
konfiguráció nem jelent publikálásra kész kiadást.
