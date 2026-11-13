# Tulajdonosi átadási lista – nyitott, nem kitalált adatok

## Az első zárt teszt valódi akadályai

- [ ] Kiadó/adatkezelő neve, országa és kötelező jogi adatai.
- [ ] Valódi támogatási és adatvédelmi elérhetőség; az áruházi kapcsolati e-mail kötelező. Sem e-mail-cím, sem cég, sem webcím nem került kitalálásra. [Google: app létrehozása](https://support.google.com/googleplay/android-developer/answer/9859152).
- [ ] Végleges, nyilvános, aktív privacy URL és az appal egyező, tulajdonos/jogi szakértő által jóváhagyott tájékoztató. A műszaki adatközpont még nem teljes jogi tájékoztató.
- [ ] Fejlesztői fiók típusa, létrehozási dátuma és szükséges azonosítása; szerződésekről és díjakról csak a tulajdonos dönthet.
- [ ] Végleges alkalmazásazonosító: jelenleg com.example.mennyiment, változatlan. Más azonosító külön telepítést és eltérő adat-/frissítési útvonalat jelenthet.
- [ ] Megfelelő feltöltőkulcs, biztonságos külső titokkezelés, App Signing-döntés és sikeres aláírt AAB. Nem készült kiadási kulcs; debug-aláírás nem helyettesíti.
- [ ] Valódi Android-készülékes és release/16 KB próba, fájlválasztó és adatmegőrző frissítés. Ezek nem következnek a debug APK elkészültéből.

## Célközönség és korhatár

A jóváhagyott márkairány elsődlegesen 18–30 éves felnőtteket céloz. A kódban önkéntes felnőtt/kiskorú nyilatkozat van, nem személyazonosság- vagy születésnap-ellenőrzés. A kiskorú mód általános jólléti funkciókat enged; a karaktercsaládok és vizuális életkorok nem határozzák meg automatikusan a Play-célközönséget.

- [ ] A végleges célkorcsoportok, kiskorú mód és áruházi bemutatás legyenek következetesek. Javasolt kiindulás a dokumentált felnőtt célközönség, de a Console-választást nem állítottuk be.
- [ ] IARC/tartalmi kérdőív: az alkoholhoz kapcsolódó tényleges naplófunkciókról és képekről őszintén kell nyilatkozni. Nincs automatikusan megadott korhatár-besorolás.
- [ ] A játékos karaktervilág miatt a gyermekeket megszólító megjelenést is vizsgálni kell; a kiskorú mód önmagában nem Families-megfelelőségi igazolás. [Google: célközönség és tartalom](https://support.google.com/googleplay/android-developer/answer/9867159).
- [ ] Közérzet-, alvás- és tünetnapló miatt a Health apps declaration és a kapcsolódó kategóriák/tájékoztatások felülvizsgálandók. Nem állítunk orvostechnikai minősítést. [Google: egészséggel kapcsolatos funkciók](https://support.google.com/googleplay/android-developer/answer/16679511).

## Adatkezelés és anyagok

- [ ] Data safety végleges válaszok: aktuális Android-csomag, OS-mentés, felhasználói fájlexport és esetleges külső szolgáltatók alapján.
- [ ] Webes host, naplózás, megőrzés és szolgáltatók: külön a natív app helyi működésétől.
- [ ] Jogalapok, megőrzési idők, kérelmek és adatvédelmi eljárás a tényleges célországokhoz. Nincs nem létező törlési portál.
- [ ] Leírástervezet, képek és Menti-grafikák felhasználási jogának tulajdonosi jóváhagyása.
- [ ] Saját, jóváhagyott Google Play-ikon és feature graphic. A megvizsgált `web/icons/Icon-512.png` és Android `mipmap-*/ic_launcher.png` még Flutter-alapjelet mutat; ezek nem kész MennyiMent? áruházi anyagok. 512×512-es saját Play-ikon és 1024×500-as feature graphic szükséges; a képernyőkép-jelöltek nem helyettesítik ezeket.
- [ ] Valódi tesztelői kör és saját Console-jelentkezési link. Nem készült kitalált kapcsolatlista, meghívó vagy fizetett tesztelés.

A fenti lista nem állítja, hogy a Play vagy jogi felülvizsgálat már megtörtént. Main merge, Play-feltöltés, szerződéselfogadás és publikálás ebben a feladatban nem engedélyezett.
