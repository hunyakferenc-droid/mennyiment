# Play Console kitöltési jegyzet – tervezet, 2026. november 22.

A fiókot/Console-t nem nyitottuk meg, nem történt feltöltés vagy szerződés elfogadása.
Az alábbiak a normál Android-változatra vonatkoznak, nem a REVIEW kísérleti klubjára.

## Aktuális hivatalos követelmények

- A Google telefonos új appjai és frissítései jelenleg Android 16 / API 36 vagy magasabb
  target SDK-t igényelnek. A csomag tényleges értékét a bundle-ből kiolvasott manifest és
  aab-verification.json rögzíti, az APK-ellenőrzés is API 36-ot vár.
  [Google cél-API](https://support.google.com/googleplay/android-developer/answer/11926878),
  [Android útmutató](https://developer.android.com/google/play/requirements/target-sdk).
- A 64 bites natív kód miatt 16 KB lapméret-támogatás szükséges. A jelenlegi hivatalos
  oldal a nem támogató frissítések tiltására 2027. február 1-jét jelzi. A statikus ELF- és
  csomagigazítás nem runtime-próba; a tényleges 16 KB-os környezet külön nyitott ellenőrzés.
  [Android 16 KB](https://developer.android.com/guide/practices/page-sizes).
- A belső teszt legfeljebb 100 meghívott tesztelőre használható. Nem azonos a zárt teszttel.
  A 2023. november 13. után létrehozott személyes fióknál a production hozzáféréshez
  legalább 12, folyamatosan 14 napig feliratkozott zárt tesztelő és a Google további
  elbírálása szükséges; ez nem a belső teszt automatikus 12/14 előfeltétele.
  [Belső/zárt teszt](https://support.google.com/googleplay/android-developer/answer/9845334),
  [új személyes fiókok](https://support.google.com/googleplay/android-developer/answer/14151465).
- Új személyes fióknál valódi Android-eszköz hozzáférésének igazolása is szükséges lehet,
  a fióktulajdonos Play Console mobilalkalmazásával. Emulátoros CI ezt nem teljesíti.
  [Eszközigazolás](https://support.google.com/googleplay/android-developer/answer/14316361).
- A kizárólag belső teszten aktív app a Data safety szakasz kitöltése alól kivételt kaphat;
  a zárt/nyílt/production állapot más. Adatkezelési tájékoztató és a tényleges App content
  feladatok a Console aktuális állapota szerint intézendők. A tájékoztató legyen nyilvános,
  működő, belépés nélkül elérhető weboldal, és az alkalmazásban is legyen hozzáférhető.
  [Data safety](https://support.google.com/googleplay/android-developer/answer/10787469),
  [review-előkészítés](https://support.google.com/googleplay/android-developer/answer/9859455).

## Kód-, SDK- és manifestalapú válaszjavaslatok

A végső engedélylista a valódi AAB release-manifest.xml és aab-verification.json állományában
van; a debug manifest INTERNET engedélye nem azonos egy adattovábbító funkcióval.
A forrás eltávolítja a Media3 opcionális ACCESS_NETWORK_STATE/WAKE_LOCK engedélyét.
A check_apk_layout.py a debug APK tényleges összevont engedélyeit is ellenőrzi.

| Console-téma | Javaslat / konkrét kódindoklás | Tulajdonosi feladat |
| --- | --- | --- |
| Saját adatgyűjtés, továbbítás | Nem találtunk app által naplóadatot továbbító hálózati útvonalat. SharedPreferences helyi adatok; saját backend/fiók/analitika/reklám-SDK nincs a vizsgált függőségekben. A „nem gyűjt” javaslat a készülékről továbbítás Google-definíciójához kötött, nem azt jelenti, hogy nincs személyes adat. | Végső SDK/manifest/funkciók egyezésének jóváhagyása. |
| Adatmegosztás | Nincs automatikus appbeli megosztás. Export/import a meglévő file_picker és backup_file.dart útvonalon, a felhasználó által választott rendszer-fájlszolgáltatóval történik. | Felhős szolgáltató és felhasználó által kifejezetten választott megosztás kivételének ellenőrzése. |
| Android rendszermentés | allowBackup nincs kikapcsolva a forrásban. A rendszer és OEM beállításaitól függő OS-mentés/D2D a SharedPreferences adatait is érintheti. Nem appbeli felhőszinkron. | Tájékoztatóban következetesen szerepeljen; ne ígérjünk kizárólag készüléken maradást minden rendszerbeállítás mellett. |
| Helyi adattípusok | Napló: név, mennyiség, alkoholfok, ár, idő; közérzet/alvás/tünetek és szövegek; Menti-név és választások; kedvencek; célok/keretek/megtakarítás; XP, feloldások, kalandok és beállítások. REVIEW-ban külön klub- és próbaadatok. | Érzékeny egészségi/pénzügyi és szabad szöveges adatok kezelési leírásának jogi jóváhagyása. Ezek önmagukban nem off-device gyűjtési bejelölések. |
| Titkosítás | Nincs megvalósított külön app-adattitkosítás; a JSON-export nem titkosított. Saját adatfeltöltő csatorna nincs. | Az űrlap tényleges elágazását követni; független biztonsági auditot vagy titkosítási garanciát ne jelöljünk. |
| Fiók/adattörlés | Nincs appbeli bejelentkezés, szerveres fiók vagy törlési portál. Ez a csomag nem vezet be adattörlést. | Ne adjunk meg kitalált fiók- vagy törlési URL-t. |
| Reklám / vásárlás | Nincs reklám-, fizetési vagy előfizetési funkció a vizsgált kiadásban. | Tényleges üzleti modell jóváhagyása, változáskor új audit. |
| Engedélyek | Rendszer-fájlválasztó; nincs általános tárolási, kamera-, mikrofon-, hely-, kontakt- vagy egészségszenzor-engedélykérés az auditált útvonalakon. A signature szintű DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION AndroidX belső védelem, nem felhasználói runtime-engedély. | A mellékelt összevont release manifest ellenőrzése, Console-jelzések követése. |
| Tartalombesorolás | Alkoholt megnevező napló és képi utalások vannak; a mennyiséget nem jutalmazzuk. Az alkoholra vonatkozó IARC-kérdést nem szabad „nincs utalás”-ként lezárni. Nincs saját chat/UGC-megosztás, szerencsejáték vagy erőszakos játékmenet. | Teljes IARC-kérdőív kitöltése tényleges képek/funkciók alapján. PEGI/IARC számot nem állítunk elő találgatással. |
| Célközönség / egészség | Márkairány: felnőtt célközönség; a meglévő kiskorú mód korlátozásai megmaradnak. A közérzet és önreflexió egészséghez kapcsolódó funkció lehet; nincs diagnózis, vezetési alkalmasság vagy biztonságos alkoholadag. A REVIEW mozgásgombokat értékel, nem mér mozgást. | Életkori célzás, Families és egészségfunkció-nyilatkozat tényleges Console-opcióinak tulajdonosi felülvizsgálata. |

A video_player Android/Media3 hálózatra is képes SDK, de az itt használt LocalMentiVideo
helyi assetet játszik le; a normál AAB médiakatalógusa üres és nem tartalmaz REVIEW MP4-et.
A package_info_plus a saját app verzióját/csomagadatait olvassa; a crypto helyi hash-ellenőrzést végez.
A pontos lockfile-verziók és annak SHA-256 értéke a CI dossier-audit.json fájljában szerepelnek.
Ez nem független adatvédelmi tanúsítás és nem minden jövőbeli SDK-verzióra szóló garancia.

## Belső teszt kezdőknek – tulajdonosi műveletek, itt nem végrehajtva

1. Ellenőrizd a fiók állapotát, szerepkörét, személyes/szervezeti típusát és igazolási feladatait.
2. Erősítsd meg a meglévő com.example.mennyiment csomagnév használhatóságát/tulajdonjogát.
   Nem nevezzük át automatikusan; a Console-ban a végső azonosító fontos, később frissítést és adatokat érint.
3. Biztosíts megfelelő feltöltőkulcsot biztonságos külső konfigurációban, és egyeztesd a nyilvános
   tanúsítványát a Console feltöltési tanúsítványával. Upload key és Play App Signing app-signing key
   nem ugyanaz. Aláírt AAB-t csak valós egyezés ellenőrzése után jelölj feltöltésre késznek.
4. Hagyd jóvá az adatkezelői/szolgáltatói adatokat, nyilvános privacy URL-t, kapcsolatot,
   HU/EN szövegeket, normál alkalmazás képeit és App content feladatokat. Kísérleti REVIEW-képet
   ne használj a normál AAB olyan funkciójának reklámozására, amely ott nincs bekapcsolva.
5. A Console belső teszt sávjában kezeld a legfeljebb 100 tesztelő listáját és az opt-in hivatkozást.
   A tényleges feltöltés, szerződés és tesztelők meghívása nem része ennek a fejlesztési végrehajtásnak.
6. Az alkalmazás terjesztési aláírásával települt példányon fizikai próbát és adatmegőrző frissítést is végezz.

Képek követelményeinek forrása: [Google preview assets](https://support.google.com/googleplay/android-developer/answer/9866151).
A csomag valódi 1080×1920 Android-képeket készít normál nézetekről, külön a REVIEW QA-képektől.
A végső képméret, PNG/JPEG formátum és jóváhagyás a képek jegyzékében/átadásában szerepel.
