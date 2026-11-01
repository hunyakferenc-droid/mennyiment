# MennyiMent? 2.0 – C: igazolt cél- és kihívásreakciók

Dátum: 2026. november 1. Ág: `feature/mennyiment-2-goal-reactions`.
Alap: a #18 sikeres CI-vel ellenőrzött állapota, `545aea2e3437dbe9e6fcb6dc250de82e6ce3ef0b`. A #17/#18 továbbra is draft, a main változatlan. Ez a részcsomag azok folytatása; automatikus merge és kiadás nincs.

## Működés

- A Menti két új HU/EN eseményt ismer: a külön heti kihívás és a személyes heti önellenőrzési cél teljesítése. Nem módosul az XP-rendszer, és egyik esemény sem ad pontot vagy új feloldást.
- Reakció csak akkor jelenik meg, ha az éppen megfigyelt héten a rögzített napok száma a korábbi, még nem teljesített célból eléri ugyanazt a célszámot. Csak különböző, naptári dátumú, nem jövőbeli napok számítanak.
- A cél átírása/csökkentése, leállítás/kihagyás, korábbi hét megtekintése, kezdeti betöltés, ismételt megnyitás és már teljesített cél nem indít új eseményt. Az üres italnapló nem bizonyít semmit a fogyasztásról.
- A manuális kihívás és személyes önellenőrzés reakciója kizárólag megerősített mentés után jelenik meg. Sikertelen vagy bizonytalan kimenetelű írás nem frissíti optimistán a cél állapotát.
- A közérzetnaplóhoz kötött kihívás a már megnyitott oldalon végzett sikeres frissítéskor reagálhat, ha új, valós naplóadatokkal lépi át az aktív, változatlan célküszöböt. Az első betöltésen nincs visszamenőleges ünneplés. Hibás/normalizálódó dátumot nem használunk igazolásnak.
- A hétváltás közben befejeződő korábbi mentés adata megmarad, de a következő héten nem vált ki a régi hétre vonatkozó reakciót.
- A reakció megjelenítési állapot, nem új tartós jutalomnapló. Nincs új SharedPreferences-kulcs, adatmodell-verzió vagy migráció.

## Szükséges adatmegőrzési javítás

A régi személyescél-oldal a mentés előtt frissítette az állapotát, nem vizsgálta a bool írási eredményt, és a teljes dokumentum visszaírásakor elveszíthette az ismeretlen mezőket. Erre nem épülhetett volna megbízható teljesítési reakció.

Az új `PersonalGoalStore` az eredeti `mennyiment_personal_goals_v1` kulcsot és mezőket használja. Betöltéskor nem ír és nem migrál. A hiányzó régi mezők megtartják a korábbi alapértékeket. Csak a kifejezetten módosított mezőt cseréli; az ismeretlen mezők, történeti dátumszövegek és duplikátumok megmaradnak. A cél számlálásához ettől függetlenül csak a helyes, különböző dátumokat használjuk.

A betöltés és írás sorosított. Írás előtt újraolvassuk a tárolót, és az eredeti nyers pillanatkép eltérésekor letiltjuk a felülírást, újratöltést kérve. A tartományon kívüli vagy értelmezhetetlen céladat írásvédett állapotot eredményez; nem normalizáljuk és nem töröljük. Hamis írási eredmény/kivétel esetén a cache-t újratöltjük, és nem publikálunk sikert. A már végrehajtott, de sikertelennek jelzett írás csak egy későbbi sikeres betöltés után látható; ettől nem keletkezik új reakció.

Ez nem többfolyamatos ACID-adatbázis és nem a backup/restore újraírása. A meglévő visszaállítási/recovery folyamat, napló, XP, profil és tartós feloldások megmaradnak.

## UI és lokalizáció

A személyes célok oldala az előző szakasz közös, görgethető paneljeit használja, HU/EN szövegekkel, helyi pénz- és dátumformátummal. A hétléptetés naptári aritmetikát használ, a napváltást és app-visszatérést frissítéssel követi. A hibás betöltés nem mutat alapértékeket megbízható adatként; újrapróbálható. A hiba diagnosztikája hibatípus és stack, naplótartalom nélkül.

A költségkereten belüli rögzített részösszeg nem jelenti a teljes hét igazolt teljesítését; erre nem adunk ünneplő reakciót. A költségek önbevallásosak, az ismeretlen ár külön jelzés.

## Érintett fájlok

- `menti_completion.dart`: csak olvasó, naptári teljesítési bizonyíték.
- `personal_goal_store.dart`: konzervatív mentési védelem a meglévő kulcson.
- `personal_goals.dart`: megerősített állapot, reakció, HU/EN, dátumkezelés és újrapróbálás.
- `weekly_challenges.dart`: a meglévő ChallengeStore-hoz kötött, új XP nélküli reakciók.
- `menti_reactions.dart`: két új HU/EN tartalomtípus.
- HU/EN ARB-k, három új tesztfájl és a meglévő Budapest CI-lépés kiegészítése.

## Ellenőrzés

A tesztek lefedik a részleges régi adatot, ismeretlen mezőket, hamis és kivételes írást (beleértve a végrehajtott, de sikertelennek jelzett esetet), elavult pillanatképet, sérült dokumentumot, módosíthatatlan olvasási listát, célszám-csökkentést, ismétlést, hétváltást, DST-t, HU/EN és 320 px/200% szöveges megjelenítést. Külön ellenőrzik, hogy napló/XP/profil/ismeretlen feloldás nem módosul a reakcióktól.

Helyben nincs Flutter SDK; a pub get, gen-l10n, analyze, test és build web sikerét csak tényleges CI-futás igazolhatja. A helyi parancseredmények külön rögzítve, a whitespace- és ARB-ellenőrzés futtatható. A végleges CI-állapotot a draft PR leírása rögzíti; meg nem futott tesztet nem jelölünk sikeresnek.

## Hátralévő munka

A teljes személyes áttekintő (D), az italkatalógus és további aloldalak lokalizációja, valamint készülékes/képernyőolvasós ellenőrzés külön következő feladat. Hosszú kihagyás utáni visszatérési reakció megbízható, külön aktivitásadat nélkül nem készült. Nincs új egészségügyi állítás, webshop, fizetés vagy közösségi funkció.
