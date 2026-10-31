# MennyiMent? 2.0 – B: főképernyő és navigáció

Az előző, sikeres CI-vel ellenőrzött #17-es draft csomagra épülő, külön fejlesztési ág: `feature/mennyiment-2-home-navigation`. A mainhez képest a #17 változtatásait is tartalmazza; annak beolvasztása után a közös előzmény miatt csak a B-szakasz különbsége marad. Automatikus merge és kiadás nincs.

## Mi változik?

- A főképernyő Menti-kártyája, adatlapkái és funkciókártyái külön, újrahasznosítható widgetekbe kerültek (`home_widgets.dart`).
- A rács keskeny kijelzőn vagy nagy betűméretnél egy oszlopra vált. Nincs betűméretet visszacsökkentő FittedBox és két sorra vágott funkcióleírás. A Menti karakter a szöveg fölé kerül, ha kevés a hely.
- Az italrögzítés gombja közvetlenül a köszöntés alatt érhető el. A meglévő italkatalógust és mentési útvonalat használja.
- A köszöntés, összegzések, XP-magyarázat, üres/hibaállapot és bejegyzésmenü szövege HU/EN ARB-be került. A pénzösszegek locale szerinti HUF/Ft formátumúak. A felhasználói italneveket és profilnevet nem fordítjuk át.
- A „Napló” gomb immár teljes, időrendbe rendezett, görgethető bejegyzéslistát nyit (`drink_journal_page.dart`), nem a célok/naptár oldalt. Az „Összes bejegyzés” ugyanide vezet. A célok/naptár változatlanul megnyitható a Célok kártyáról.
- A napló új oldala csak olvasható pillanatképet kap. Nem ír SharedPreferences-adatot, nem migrál, és nem módosítja a forráslista sorrendjét. Az ismeretlen ár külön jelzés, a valódi 0 Ft nem adathiány.
- A napló hozzáadás gombja visszatér a kezdőlapra és megnyitja a meglévő italválasztót; megnyitástól nem keletkezik bejegyzés. A meglévő kezdőlapi ár-/törlési műveletek megmaradnak. A teljes listában szerkesztő még nincs.
- A „Menti” navigáció az előrehaladás oldalát nyitja; a profil a felső profilgombon továbbra is elérhető. A navigáció őre a gyors ismételt koppintásból nem nyit két azonos route-ot.
- A navigáció megmarad Navigator push/back alapúnak: nem hoz létre párhuzamos tabállapotokat és üzleti tárolókat. A kezdőlapról elhagyó route-ok vissza gombbal térnek vissza.
- Nagy betűméretnél a navigáció ikonokat használ; a célok neve megmarad a képernyőolvasónak és a tooltipben. A törzs SafeArea-t használ.
- Nem betölthető napló helyett nincs kitalált nullaösszesítés vagy üresnapló-állítás. A naplóadatot igénylő célok letiltva maradnak, a hiba újrapróbálható és lokalizált. A mentési és snapshot-védelem logikája megmarad.
- Nem olvasható XP-nél újrapróbálható állapot jelenik meg: a felület nem állítja, hogy a felhasználó első szintű. A diagnosztika hibatípust és stacket ír, naplótartalmat nem.

## Adatbiztonság

Nem változik SharedPreferences-kulcs, XP-szabály vagy karakterasset. A backup/restore és indítási recovery-védelem változatlan. A tárolt ismeretlen mezők, ruhafeloldások és profilválasztás megőrzését célzott teszt ellenőrzi. A képernyőn szereplő „naplózott nap” nem alkoholmentes nap; nincs új fogyasztáshoz kapcsolt jutalom.

## Ellenőrzés

Új `home_navigation_test.dart`: HU/EN, 320/390 px és 100%/200% szöveg; az egész kezdőlap végiggörgetése; valódi naplóútvonal és gyors dupla navigáció; Menti és vissza navigáció; hozzáadás megszakítása; sérült napló és XP; profil, nyers napló, XP és ismeretlen jutalom megőrzése; másolat rendezése és változatlan forrás.

Helyben az öt kötelező Flutter-parancs az SDK hiányában nem indítható. Az ARB-k JSON-szintaxisa és azonos kulcskészlete Python-ellenőrzéssel vizsgálva; `git diff --check` futtatva. A Flutter-fordítás, l10n-generálás, statikus elemzés, teljes teszt, Budapest/DST és web build tényleges eredményét az ehhez az ághoz tartozó PR GitHub Actions futása rögzíti. Csak annak befejezése után állítható sikeresnek.

## Korlátok és következő feladatok

Ez a főképernyő/navigáció szakasz, nem a teljes 2.0 csomag. Az italkatalógus, beviteli dialógusok, régi dashboard és több más aloldal lokalizációja külön feladat. A naplóbejegyzések teljes szerkesztése külön fejlesztés. A személyes áttekintő összekapcsolása és a külön kihívástároló reakciói továbbra is hátravannak. Fizikai készülék, TalkBack/VoiceOver és mért kontrasztvizsgálat még szükséges; a widgetteszt ezeket nem helyettesíti.
