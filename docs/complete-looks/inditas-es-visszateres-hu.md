# Teljes kinézetes kísérlet – elkülönítés

- Ellenőrzött alap: `0bdb09cab60061367e590447dbce29c64ac73deb`, 2.4.1+36.
- #40 nyitott draft, ellenőrzéskor ugyanezen a HEAD-en. Nem módosítjuk.
- Külön ág: `experiment/menti-complete-looks`.
- Külön munkakönyvtár: `/workspace/mennyiment-complete-looks`.
- A korábbi munkakönyvtár `/workspace/mennyiment-character-quality`, ága `fix/menti-character-quality`; változatlanul megmarad.

A leltár első commitjaiban csak a tulajdonosi referenciák leltára és az elkülönítés készült. Nincs alkalmazás-, verzió-, tárolási-, XP- vagy feloldásmódosítás, nincs új grafika vagy build. A három RAR megérkezett: 18 eredeti PNG és a valódi számozott képes leltár rendelkezésre áll. A három alkalmazásbeli alapmintához azonos, egyszerű hátteret használunk; egyedi háttérválasztás későbbi feladat.

Visszatérés fejlesztéskor: nyisd meg a korábbi munkakönyvtárat a `fix/menti-character-quality` ágon. Nem kell reset, fájltörlés vagy az egyik munkakönyvtár tartalmának felülírása. A későbbi alkalmazáson belüli módváltást külön verziózott állapot valósítja majd meg; a régi összeállításokat nem alakítjuk át automatikusan.

Az első kész integráció három működő mintát ad át HU/EN felülettel. A 90 kinézet gyártása, XP-s vagy fizetős feloldások élesítése, main merge és publikálás nem része ennek a lépésnek.

A 2.5.0+37 kísérleti integráció részletei: [integráció](integracio-hu.md), [kipróbálás](kiprobalas-hu.md). A korábbi, csak leltárról szóló állapotleírás történeti.
