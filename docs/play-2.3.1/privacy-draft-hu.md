# Adatkezelési tájékoztató – NEM VÉGLEGES TERVEZET

Alkalmazás: MennyiMent?, 2.3.1+34. Az adatkezelő személyét, elérhetőségét, célországait és a végleges jogi feltételeket a tulajdonosnak kell megadnia. Ez a dokumentum nem helyettesíti ezeket az adatokat, és jelen formájában nem publikálható kész tájékoztatóként.

## 1. Kit kell megnevezni?

- Adatkezelő / alkalmazás kiadója: **[tulajdonos által megadandó]**.
- Kapcsolattartó és adatvédelmi elérhetőség: **[megadandó]**.
- Székhely / ország és alkalmazandó jog szerinti további kötelező adatok: **[megadandó]**.
- Hatálybalépés, verzió és felülvizsgálati eljárás: **[jóváhagyandó]**.

Nem következtetünk a GitHub-felhasználónévből jogi személyre, cégre vagy kapcsolati címre.

## 2. Milyen adatok lehetnek az alkalmazásban?

A felhasználó által megadott naplótételek neve, mennyisége, alkoholfoka, időpontja és opcionális ára; kedvencek és saját katalógus. Közérzet-, alvás- és tünetértékelések, szabad szöveges megjegyzések, napi válaszok. Személyes célok, keretek, önellenőrzési napok és saját jelzés szerinti megtakarítások. Menti-név, megjelenés, szettek, XP és feloldások; nyelvi, mozgási és reakcióbeállítások; önkéntes korhatárnyilatkozat. Kalandvállalások, teljesítések, döntésfeljegyzések és jelvénydátumok.

Ezek érzékeny információt is tartalmazhatnak. A saját név vagy szabad szöveg miatt nem állítható, hogy az adatállomány anonim. Az app nem ellenőrzi személyazonossággal az életkort.

## 3. Mire és hol használja a jelenlegi kód?

A funkciók helyben jelenítik meg és számítják a bejegyzéseket, kimutatásokat, karaktert és haladást. Natívon helyi alkalmazásbeállításokat használ; Androidon a SharedPreferences app-tárolóját. Weben az adott böngészőprofil és webcím helyi tárolóját használja. Nincs saját felhasználói fiók, alkalmazáson belüli felhőszinkron, reklám- vagy analitikai SDK, illetve saját naplóadat-feltöltő kód.

Az Android alapértelmezett rendszermentési lehetősége nincs letiltva. A készülék és az operációs rendszer beállításai alapján rendszermentés vagy készülékek közötti átvitel érintheti a helyi adatokat. Ez nem a MennyiMent? saját szinkronszolgáltatása, és nem garantált helyreállítás. A rendszermentés külön szabályait is figyelembe kell venni. [Android: Auto Backup](https://developer.android.com/guide/topics/data/autobackup).

## 4. Export, import és más szolgáltatók

Az export olvasható, alkalmazás által nem titkosított JSON-fájl. A felhasználó választja a fájl helyét és a visszaállítandó állományt. A rendszer fájlválasztója felhős szolgáltatót is kínálhat; ilyenkor az adott szolgáltató hozzáférése, hálózata és feltételei is számítanak. Importnál átmeneti helyi másolat készülhet. A címzettnek vagy más alkalmazásnak átadott fájl feletti későbbi kontroll nem garantálható az appból.

## 5. Webes eltérések

A webes kiszolgáló és hálózati közvetítő a betöltési kéréseket, IP-címet és egyéb technikai kérésadatokat láthatja saját beállításai szerint. **[A tényleges webes szolgáltató, naplózás, hely és megőrzési idő tulajdonosi adata szükséges.]** A HU/EN és emoji alapbetűk csomagoltak; nem támogatott írásjelekhez a Flutter böngészős megjelenítő külső fontot kérhet. A Névjegy weben a kiszolgált version.json fájlt kéri le. Ezeket nem szabad a natív Android-alkalmazás adataival összemosni.

## 6. Védelem, megőrzés és helyreállítás

Nincs külön alkalmazásszintű adattitkosítás, jelszavas alkalmazászár vagy szerveres helyreállítás. Az operációs rendszer és a böngésző védelme külön réteg. A helyi adatok és a mentési fájl elveszhetnek; a hibás vagy újabb mentés visszaállítása elutasítható. Nincs adatvesztés elleni garancia.

A jelenlegi kód nem vezet be automatikus megőrzési határidőt vagy távoli törlést. A rendszermentés és a felhasználó által készített másolatok külön életciklusúak. Ebben a csomagban nincs új adattörlési funkció. A tulajdonosnak kell meghatároznia a végleges adatvédelmi kérelmek, megőrzés és kapcsolattartás rendjét; nem állítható, hogy az appban nem létező törlési portál működik.

## 7. Jóváhagyandó részek

**[Az adatkezelés jogalapja és a célország szerinti jogok/eljárások.]** **[Érintetti kérelmek elérhetősége.]** **[Kiskorúakra és célközönségre vonatkozó végleges döntés.]** **[Tényleges szolgáltatók és esetleges adattovábbítás.]** Jogi és tulajdonosi felülvizsgálat szükséges.

A Play-listinghez és apphoz végleges, egyező tájékoztató szükséges. Az itt leírt műszaki áttekintés nem pótolja az aktív, nyilvánosan hozzáférhető, nem PDF alapú privacy URL-t és a kiadó azonosítását. [Google: User Data](https://support.google.com/googleplay/android-developer/answer/10144311), [egészséggel kapcsolatos appok tájékoztatása](https://support.google.com/googleplay/android-developer/answer/16679511).
