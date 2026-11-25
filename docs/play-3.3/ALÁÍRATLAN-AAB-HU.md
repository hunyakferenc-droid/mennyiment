# 3.3.0+46 – aláíratlan release AAB-jelölt

Ez valódi release módban fordított, a normál alkalmazásazonosítót használó AAB,
**feltöltési aláírás nélkül**. Nem telepíthető közvetlenül telefonra és nem nevezhető
Play-feltöltésre késznek. Telefonos próbához a külön REVIEW debug APK való.

Az előkészítő kizárólag rögzített Git-commit archívum külön ideiglenes másolatában állítja
nullára a release signing configot, és ott kapcsolja le az aláírási feladat függőségét.
A munkafa eredeti Gradle-őre változatlan: a szokásos `flutter build appbundle --release`
hiányzó vagy debug aláírásnál továbbra is hibával leáll. Nincs rejtett debug-visszaesés,
kulcslétrehozás, titokmásolás vagy módosítás a felhasználói adatokon.

Reprodukálás: az ellenőrzött hivatalos bundletool-all 1.18.3 mellett:

    python3 tool/build_unsigned_play_candidate.py --unsigned --bundletool /eszkozok/bundletool-all-1.18.3.jar --output /uj/ures/aab-mappa

Hivatalos eszköz: https://github.com/google/bundletool/releases/tag/1.18.3
SHA-256: a099cfa1543f55593bc2ed16a70a7c67fe54b1747bb7301f37fdfd6d91028e29

Az `aab-verification.json` a tényleges bundletool-validálást, a bundle-ből kiolvasott
manifestet, cél-API-t, engedélyeket, natív ELF-igazítást és az aláíratlan állapotot rögzíti.
A normál csomag nem tartalmaz REVIEW-videót. A 16 KB-os statikus ellenőrzés nem
jelent 16 KB-os runtime- vagy fizikai készülékes próbát.

A tulajdonos feladata a megfelelő feltöltőkulcs és a Play Console feltöltési
tanúsítványának egyeztetése, biztonságos külső konfigurációban. Ezután a projekt
meglévő szigorú release útvonalán újra kell építeni és ténylegesen ellenőrizni az
aláírt AAB-t. Részletek: ../play-2.3.1/android-release-hu.md.
Nem szükséges és nem javasolt magánkulcsot vagy jelszót chatbe, repóba vagy naplóba tenni.

## A bevizsgált jelölt aláírt példányának ellenőrzése

Ha az upload kulccsal közvetlenül a bevizsgált aláíratlan AAB külön példányát
írtad alá, a JDK 21-gyel futtatható ellenőrző ugyanazt a csomagtartalmat és
minden csomagbejegyzés tényleges aláírását ellenőrzi:

    java tool/VerifyPlayAab.java app-release-UNSIGNED.aab app-release-SIGNED.aab JELÖLT_SHA256 FELTÖLTÉSI_TANÚSÍTVÁNY_SHA256

A jelölt SHA-256 értékét a bevizsgált csomag ellenőrzési jelentéséből
(`aab-verification.json`, `aabSha256`) vedd. A tanúsítvány SHA-256 értékét
a Play Console **feltöltési kulcsának tanúsítványából** másold ki. Az ellenőrző
elfogadja a kettőspontokkal tagolt ujjlenyomatot is. Siker esetén az aláírt
AAB SHA-256 értékét is kiírja. A bemeneti fájlokat nem módosítja.

Az összehasonlítás feltétele az egyező csomagtartalom. Külön újrafordított
AAB esetén a két build fájljai eltérhetnek. Az egyezés a feltöltési
tanúsítványt és az AAB tartalmát igazolja. A Console elfogadása és a készülékes
próba külön ellenőrzés.
