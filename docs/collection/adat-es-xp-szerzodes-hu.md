# Gyűjtemény: megőrzés és bővítési határok

Az eredeti teljeskinézet-tároló kulcsa változatlan: `mennyiment_complete_look_v1`. Az új dokumentumverzió 2; nincs második profil- vagy XP-tároló. A korábbi három `*-base-v1` azonosító és képfájl változatlan. Egy v1-es olvasás önmagában nem ír vissza semmit. A dokumentum explicit választásmentéskor vagy tényleges új XP-feloldáskor bővül v2-re.

A v2 az aktív megjelenítési módot, a kiválasztott ID-t, a véglegesen megszerzett XP-s ID-kat és a már bejelentett ID-kat tárolja. Az ismeretlen kiegészítő JSON-mezők és megszerzett ID-k megmaradnak. Hibás, ismeretlen verziójú vagy ismeretlen kiválasztott ID-jű dokumentum írásvédett. V1-ben a későbbi v2-feloldásmezőkkel ütköző, kétértelmű bővítést nem értelmezzük automatikusan.

A `MentiXpStore` meglévő jelenlegi dokumentumát olvassuk; a galéria nem migrál XP-t, nem ad és nem költ pontot. Az új értesítési csatorna csak sikeresen perzisztált XP-változás után kér újraolvasást. Alkalmazás-visszatéréskor is újratöltünk. Olvashatatlan XP-nél nincs új feloldás vagy kitalált haladás; az ingyenes és korábban megszerzett választások elérhetők.

A 200 XP elérése mindhárom tényleges legendás képet végleg feloldja. A mentés sorrendje: friss snapshot és XP-snapshot ellenőrzése → perzisztálás → tárolt érték visszaellenőrzése → felület/értesítés. A párhuzamos mentéseket közös írászár védi. Külső választásváltozás és mentetlen helyi választás ütközésekor a galéria újratöltést kér.

A feloldás és a bejelentési jelölés egy dokumentumban kerül mentésre. Egy sikeres feloldási eseményhez egy összevont visszajelzés tartozik, újranyitás/újraindítás nem ismétli. Megszakítás esetén a tartós jelölés és a képernyőre rajzolás között az értesítés elmaradhat; a megszerzett kinézet ettől megmarad. Nem állítunk megszakításon át garantált, pontosan egyszer kirajzolt üzenetet.

A mentés/visszaállítás a meglévő tranzakciót és rollback-naplót használja. A jelenlegi és bejövő megszerzett/bejelentett ID-k uniója marad meg, az érkező választás visszaállítható. Az ismeretlen kiegészítések összeolvadnak, azonos mezőnél az importált érték nyer. Az új kulcsot nem tartalmazó régi mentés a jelenlegi választást nem törli. A kiskorú nyilatkozat meglévő védelme változatlan.

Új profilnál a meglévő korhatárdokumentum egy hiányos létrehozási jelölést kap a karakteradatok mentése előtt. Sikertelen későbbi írás/újraindítás után a létrehozás folytatható; a részben mentett karakter nem teszi befejezetté az onboardingot és nem ad felnőtt jogosultságot. Meglévő profilt nem alakítunk át automatikusan. A régi Studio és a gyűjtemény saját mentett választása egymástól függetlenül megmarad; a megjelenítési mód váltása explicit mentés.

## Grafika és teljesítmény

A teljes képek statikusak: nincs rájuk rajzolt hamis mimika/pislogás. Átlátszó képeket közös alkalmazásfelületen használunk, külön karakterháttér-választó nélkül. A közös 3:4 vászon és talpvonal azonos; széles köpenynél/gördeszkánál a szélesség is korlátozza az arányos méretet, így nem vágjuk le a tartozékot a merev magasság kedvéért. Az eredeti referencia szélén eleve levágott részletet nem állítjuk vissza kitalált eredetiként.

Valódi, a közös Flutter-renderből készült 360×480-as átlátszó bélyegképek, lusta kártyalista és korlátozott képdekódolás szolgálja a mobilos galériát. A nagyító teljes forrásból, legfeljebb natív méretig dekódol. A bélyegképek nem másolatokból létrehozott új katalóguselemek. A helyi Roboto és magyar karakterkészlete/licence már létezett; nincs új külső font- vagy képletöltés.

## Későbbi prémium bővítés

Katalógus-ID, grafikai forrás/jóváhagyási állapot és feloldási feltétel külön metaadat. Később új hozzáférési feltétel illeszthető hozzá. Ez most nem vásárlási jogosultság: nincs fizetési SDK, előfizetés, vásárlásgomb vagy helyi prémium-kapcsoló. Valódi vásárláshoz külön termék-, áruház-, bizonylatellenőrzési és adatvédelmi terv kell. A 90 kinézet, minijáték és szoba nincs ebben a csomagban.
