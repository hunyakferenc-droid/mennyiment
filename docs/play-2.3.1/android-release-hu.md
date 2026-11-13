# Android release-előkészítés

## Mi változott?

Az alkalmazásazonosító továbbra is `com.example.mennyiment`. A `release` buildtípus kizárólag a külön `release` signing configot használja; nincs visszaesés a debug-kulcsra. A debug build nem igényel kiadási beállítást.

Minden app-szintű Release feladat függ a `validateMennyiMentReleaseSigning` ellenőrzéstől. Hiányzó/olvashatatlan konfiguráció, hiányzó keystore, szabványos debug-alias/fájlnév, Android Debug tanúsítvány, érvénytelen tanúsítvány vagy használhatatlan privát kulcs megállítja a buildet. A hiba `MENNYIMENT_RELEASE_SIGNING[...]` kódot ad, titkos értékek és szolgáltatói kivételek továbbnaplózása nélkül. Ez nem bizonyítja egy tetszőleges kulcs üzleti megfelelőségét vagy Play-jóváhagyását.

## Külső konfiguráció – kulcslétrehozás nélkül

1. A kiadó biztosítsa a megfelelő, biztonságosan kezelt feltöltőkulcsot. Ez a csomag nem hoz létre és nem szállít kulcsot.
2. Az [üres sablon](../../android/key.properties.example) alapján készíts helyi, figyelmen kívül hagyott `android/key.properties` fájlt, vagy még inkább a repón kívüli fájlt.
3. Külső fájlnál állítsd a `MENNYIMENT_RELEASE_PROPERTIES` változót az abszolút útjára. A négy kötelező mező: `storeFile`, `storePassword`, `keyAlias`, `keyPassword`. Relatív `storeFile` a properties-fájl mappájához képest értendő; Windowson használj előre perjelet.
4. A `MENNYIMENT_STORE_FILE`, `MENNYIMENT_STORE_PASSWORD`, `MENNYIMENT_KEY_ALIAS`, `MENNYIMENT_KEY_PASSWORD` környezeti változók mezőnként felülírják a fájlt. Üres, hiányzó vagy nem megfelelő érték nem helyettesítődik debug-adattal.
5. A keystore és kitöltött properties ne kerüljön Gitbe, munkanaplóba vagy képernyőképre. A repó figyelmen kívül hagyja a szokásos kulcsokat és `key.properties` fájlokat; egy tetszőleges más fájlnév ettől nem válik automatikusan biztonságossá. Ne használd a `--debug`, Build Scan vagy környezetkiíró diagnosztikát titkokkal.

A `storeType` opcionális, a Java provider alapértelmezése használatos. A jelszó nem kerül automatikusan a másik mező helyére. A konfigurációs fájl Java Properties-formátumú; a jelszavak és escape-karakterek kezelését a tulajdonosnak kell ellenőriznie.

## Mi fut, mi nem?

A `tool/check_release_signing.py` tényleges `:app:bundleRelease` kísérleteket indít hiányos, hiányzó fájlra mutató és debug-aliasos konfigurációval. Mindháromnak hibával kell leállnia, új AAB nélkül; a segéd ellenőrzi a tesztjelszavak hiányát a kimenetben. Nem gyengíti az ellenőrzést és nem készít tesztkiadási kulcsot. A végső futási eredmény a fejlesztési jelentésben szerepel.

**Aláírt release AAB nem készül kiadási kulcs nélkül.** A hiányzó tulajdonosi aláírás szándékos kiadási akadály, nem „publikálásra kész” állapot. A későbbi, tulajdonos által indított `flutter build appbundle --release` csak sikeres befejezés és a tényleges aláírás/csomag ellenőrzése után nevezhető kész AAB-nak.

## Frissítés és korábbi debug APK-k

Az átadott 2.2.8+32 APK tanúsítványának SHA-256 értéke `81b09f4862de94438b97cf074b91901fa9ad68d87f979d783750badf6faf992c`; a 2.3.0+33-é `90bb6f1a99998d754f6936a64b2c434cb0d636edfdd5ffb7fb5a554e396ea59b`. Ezek eltérnek, mert a CI debug-aláírása nem jelent megőrzött kiadási identitást. A +34 tényleges ujjlenyomata a friss build jegyzőkönyvében található.

Az adatmegőrző normál frissítéshez a csomagazonosítónak és az elfogadott aláírási identitásnak is illeszkednie kell, megfelelő verziókóddal. **Meglévő alkalmazás eltávolítása nem javasolt aláírásütközés megkerülésére.** Használj webes próbát vagy külön tesztkészüléket; meglévő app frissítéséhez azonos korábbi kulcs vagy a platform által támogatott, megfelelő aláírási lánc szükséges. A tanúsítványból nem állítható elő a magánkulcs.

Play App Signingnál a feltöltőkulcs és a terjesztett app aláírókulcsa eltérő szerepű; a Playről települő build ezért nem automatikusan frissíti az ettől eltérő debug-kulcsú példányt. A kulcskezelési és App Signing-döntést a kiadó hozza meg, szerződéselfogadás és feltöltés nélkülünk. [Android: alkalmazásaláírás](https://developer.android.com/studio/publish/app-signing).

## További műszaki kapuk

Az aktuális hivatalos cél-API követelmény a szokásos telefonos új appokhoz/frissítésekhez API 36. A projekt Flutter-verziója és a tényleges APK badging eredménye ellenőrizendő; nem elég a tervezett érték. [Google: target API követelmény](https://support.google.com/googleplay/android-developer/answer/11926878).

A natív könyvtárakat tartalmazó csomagnál 16 KB lapméretet is vizsgálni kell. A debug APK ZIP/ELF ellenőrzése hasznos előkészítés, de nem helyettesíti a későbbi release AAB, az abból készülő APK-k és egy valódi 16 KB-os Android-környezet próbáját. [Android: 16 KB lapméret](https://developer.android.com/guide/practices/page-sizes).
