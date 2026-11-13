# Data safety – válaszjavaslatok, nem beküldött nyilatkozat

Érvényességi kör: a 2.3.1+34 jelenlegi Android-kódja és lockfile-ja. A webes üzemeltetést külön kell vizsgálni. A fejlesztői fiók, telepített kiadási build, később hozzáadott SDK és szolgáltatói szerződés nem ismert. A végleges választ a tulajdonos hagyja jóvá a Console tényleges kérdéseinél.

## Mit jelent itt a „gyűjtés”?

A Google űrlapja a készülékről továbbított adatokra vonatkozik; a kizárólag helyi feldolgozás nem ugyanaz. A felhasználó kifejezett fájlátadása külön megosztási kivétel lehet, ha a választás és következménye világos. Ez nem jelenti azt, hogy az appban nincsenek személyes adatok. Zárt tesztnél is kell Data safety űrlap és privacy URL; a kizárólag belső teszt eltérő elbírálású. [Google: Data safety útmutató](https://support.google.com/googleplay/android-developer/answer/10787469).

## Főkérdések

| Téma | Javaslat és indok | Jóváhagyás feltétele |
| --- | --- | --- |
| Az Android app saját adatgyűjtése / adattovábbítása | A kódból **nem azonosítható saját, készülékről naplóadatot továbbító funkció**. Az űrlap gyűjtési kérdésére ezért a „nem” a javaslat. | Végső release manifest, SDK-k és tényleges futás egyezzen az auditált állapottal; ne kerüljön hozzá analitika/hibafeltöltő/reklám. |
| Harmadik félnek megosztás | Nincs automatikus, app által működtetett megosztás. A saját fájlexport rendszer-fájlválasztós, felhasználó által kezdeményezett művelet. | A felhős fájlszolgáltató és a látható felhasználói választás alapján ellenőrizni kell a Google kivételének alkalmazhatóságát. Ne jelöljük ellenőrzés nélkül minden jövőbeli exportot „nem megosztásnak”. |
| Android rendszermentése | A manifest nem tiltja le az alapértelmezett OS-mentési jogosultságot; a SharedPreferences adatai is érintettek lehetnek. | A rendszer saját szolgáltatását külön kell kezelni az app saját gyűjtésétől. A tulajdonosnak a tájékoztatóban is következetesen szerepeltetnie kell. |
| Fiók létrehozása | Nincs appbeli fiók vagy bejelentkezés. | Ne válasszunk nem létező fióktípust. |
| Titkosítás továbbításkor | Nincs saját adatfeltöltő útvonal; ebből nem következik app-szintű titkosítási garancia. | A gyűjtési válasz utáni tényleges űrlapelágazást kell követni. A JSON-export nem titkosított; a külső szolgáltató HTTPS-e nem app-adattitkosítás. |
| Adattörlés kérése | Nincs szerveres fiók/adattár, törlési portál vagy új appbeli adattörlés. | Ne adjunk meg kitalált törlési URL-t. A helyi adatokra és másolatokra vonatkozó eljárást a tulajdonos/jogi felülvizsgálat tisztázza. |
| Független biztonsági vizsgálat | Nincs dokumentált független audit. | Ne jelöljünk ilyen tanúsítást. |
| Reklám | A kódban és függőségekben nincs reklám-SDK vagy hirdetési funkció. | Későbbi változtatásnál újraellenőrzés. |

## Helyi adattípusok – nem automatikus űrlapos gyűjtési bejelölések

| Helyi tartalom | Lehetséges személyes jelleg | Kódindoklás |
| --- | --- | --- |
| Menti-név és szabad szövegek | Valódi nevet vagy más személyes adatot is tartalmazhatnak | [Identitásmodell](../../lib/menti_identity/menti_identity.dart), [napi válaszok](../../lib/daily_menti_store.dart) |
| Közérzet, alvás, tünetértékelés | Egészséggel kapcsolatos, érzékeny információ lehet | [Közérzetnapló](../../lib/wellbeing_journal.dart) |
| Italtételek, dátumok, mennyiségek, árak | Szokások, fogyasztás és pénzügyi feljegyzések | [Naplómodell](../../lib/drink_journal.dart), [közös mentés](../../lib/main.dart) |
| Célok, keretek, félretett összegek | Saját jelzés szerinti pénzügyi/életmódbeli adatok | [Célok](../../lib/personal_goal_store.dart), [megtakarítás](../../lib/savings_goals.dart) |
| XP, feloldások, kalandok és beállítások | Használati előzmények és választások | [XP](../../lib/menti_xp_store.dart), [kalandállapot](../../lib/menti_adventure_store.dart) |

## SDK- és rendszerindoklás

- `shared_preferences` 2.5.6; Android backend 2.4.28: az app által használt legacy API saját `FlutterSharedPreferences` állományt használ `MODE_PRIVATE` módban. Ez nem külön app-titkosítás.
- `file_picker` 13.3.0; Android backend 2.1.2: rendszer `OPEN_DOCUMENT` / `CREATE_DOCUMENT` útvonal. A plugin manifestje nem kér általános tárolási, média-, hely-, kamera- vagy mikrofonengedélyt ehhez az útvonalhoz; a választott fájl helyi gyorsítótárba másolódhat.
- `package_info_plus` 10.2.2: Androidon az app saját csomagmetaadatait olvassa, többek között verziót és buildszámot. Nincs gyűjtő végpont. Weben a `version.json` lekérése a kiszolgált oldalhoz tartozik.
- `flutter_svg`, `intl`, Flutter és a csomagolt betűk a helyi megjelenítést/formázást szolgálják. Nem található Firebase, Crashlytics, Sentry, hirdetési vagy analitikai SDK a lockfile-ban.
- Az Android fő manifest nem kér új veszélyes engedélyt. A debug/profile manifest `INTERNET` engedélye fejlesztési célú Flutter-képesség; megléte nem bizonyít adatfeltöltést. A végső csomag összevont manifestjét a buildnél újra ellenőrizni kell.

Ezek a dependency-források és [pubspec.lock](../../pubspec.lock), [backup fájlkezelés](../../lib/backup_file.dart), [adatmentés](../../lib/data_backup.dart), [visszaállítás](../../lib/data_restore.dart), [Android manifest](../../android/app/src/main/AndroidManifest.xml) ellenőrzéséből származó megállapítások. Nem minden jövőbeli SDK-verzióra szóló garanciák.

## Külön lezárandó kérdések

A webes host naplózása, esetleges külső fontfallback és a választott felhős fájlszolgáltató nem írható le ismeretlenül „semmilyen adattovábbításként”. Az OS-mentés beállításait sem szabad appbeli felhőszinkronnak nevezni. Az adatkezelői nyilatkozatot ezekkel és a végleges szolgáltatókkal együtt kell jóváhagyni. A nulla külső kérést mérő HU/EN böngészőteszt csak a tesztelt útvonalak eredménye, nem általános hálózati garancia.
