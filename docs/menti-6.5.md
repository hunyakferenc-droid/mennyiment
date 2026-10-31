# MennyiMent? 6.5 – egységes Menti-rendszer

## Profil és megjelenítés

A meglévő profilkulcsok és katalógus változatlanok. A MentiProfileStorage közös, típusbiztos feloldója a régi magyar neveket és a stabil azonosítókat is kezeli. A főoldal, Studio és fejlődési oldal a mentett család–ruha PNG-t jeleníti meg; a gardrób ugyanazokat a képutakat használja. Mentés után a főoldal újratölti a profilt és az XP-t. Új profil-adattároló nem készült.

A MentiEvolution egyetlen képet lebegtet és reakciókor billent/nagyít. Nem vált vissza eredeti képkockákra. A MentiAnimation fix pislogó képkockái és az AnimatedCartoonAvatar egyszerű rajzolt karaktere ezért nem kerül az új közös megjelenítési útvonalba. A régi modulok megmaradnak. A képek dekódolási szélessége a megjelenítési mérethez és képpontsűrűséghez igazodik, felső korláttal; a PNG-fájlok nem változtak. Az animációvezérlők dispose-ban felszabadulnak.

## XP-források és függő döntés

- Hiteles jelenlegi tároló: mennyiment_menti_xp_v2; MentiXpStore.
- Történeti napi bejegyzések: mennyiment_reflection_days_v1; a korábbi gardrób ebből számolt napok száma × 10 XP-t.
- Történeti számláló: mennyiment_menti_progress_v1 JSON xp mező; a Studio korábban ezt olvasta és 100 XP-s szintlépést használt.
- A meglévő közös rendszer napi +10 és heti review +15, cost +15, goal +20 jutalmakat használ, napi/heti ismétlést tiltva. Ezek nem változtak.

Most minden érintett képernyő a MentiXpStore értékét és a már meglévő 1 + xp ~/ 50 szintszabályt használja. A korábban kiválasztott ruhaszett a szintkorláttól függetlenül kiválasztva marad.

**Jóváhagyásra váró történeti migráció:** a korábbi számlálók eseményeinek átfedése nem bizonyítható. Új összeadást vagy korrekciót ez a fejlesztés nem végez. A main ágból örökölt MentiXpStore-migráció változatlan: létező v2 XP esetén azt tekinti hitelesnek; hiányában a régi XP és a napi adatokból számolt XP maximumát veszi. Ez megőrzi a nagyobb számlálót, de nem bizonyítja az összes különálló történeti jutalom megőrzését. Ha a régi számláló magasabb a már létező v2-nél, nincs automatikus összevonás. Az eredeti történeti JSON megmarad. Az ilyen adatok rendezése külön jóváhagyást és migrációs tervet igényel; e feladatban nem találgatunk.

A Studio 100-ról 50 XP-s szintlépésre igazítása szándékos képernyő-egységesítés, nem XP-jóváírás vagy adatátírás. A feloldási szintszámok változatlanok.

## Ellenőrzés

A regressziós készlet mind a 18 régi magyar profilt a főoldalon és a gardróbban összeveti, új választást ment, majd új preferenciapéldánnyal és új widgetfával újratölt. Mind a 18 képpel ellenőrzi a lebegő, koppintásos és reakciós animáció identitását. Külön teszt vizsgálja a 360 pixeles főoldalt, a dekódolási méretet, a szinthatárokat és a Studio hiteles XP-forrását. A korábbi karakterkatalógus-, mentési, XP-jutalmazási és egyéb alkalmazástesztek is megmaradtak.

A tesztek Flutter widget-/egységtesztek, mockolt helyi preferenciákkal; fizikai mobileszközös újraindítás és teljes böngészős végponttól végpontig teszt nem történt. A webes kiadási build ellenőrzött. A keskeny képernyőn a főoldali XP-feliratok túlcsordulását tördeléssel javítottuk.
