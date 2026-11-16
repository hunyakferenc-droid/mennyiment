# MennyiMent? 3.0.0+42 – Animation Studio fejlesztési felmérés

Alap: #45 draft PR, `171adf46c124bc3a48da150ae1fccd075399209f`, 2.9.0+41. #44: `624228aa21e774ab457084c2329e422025309173`. Mindkettő nyitott draft és változatlan. A kiinduló CI ténylegesen sikeres: 43731625843; 1194 korábbi teszt történeti alap, nem az új csomag eredménye. Külön ág/munkakönyvtár: feature/menti-animation-studio.

## Amit nem kellett újraépíteni

18 eredeti teljes PNG és stabil azonosító, 14 reakció, közös eseménybusz/reakciótervező, verziózott lokális médiakatalógus, egyetlen globális dekóder, aszinkron megszakítás/újraindítás, némítás, mozgáscsökkentés, lifecycle és saját PNG-visszaesés; teljes napló és adatvédett mentési útvonal, profil/korhatár/XP/feloldások/kalandok/HU–EN/export/import. A roadmap régi hiánylistáját nem tekintjük a jelenlegi kód állapotának.

## Valódi hiányok és változtatások

- A korábbi REVIEW csak három reakciókártyát mutatott. Új tiszta leltármodell minden 18×14 párhoz pontos állapotot ad. A jóváhagyott és a REVIEW-katalógus külön marad; REVIEW-elérhetőség nem ad normál lejátszási jogot.
- Külön fejlesztői belépő `tool/menti_animation_studio.dart`, explicit REVIEW buildkapcsolóval. A normál appnak nincs útvonala ide. A meglévő előnézeti/lejátszó-komponenseket használja, nem második motort.
- Lány, semleges, fiú családsorrend; családonként mind a hat kinézet. Mentett aktív karaktert weben csak olvas, a választások ideiglenesek. Android REVIEW továbbra is külön com.example.mennyiment.review sandbox; Studio név/R ikon, normál ID változatlan.
- Mind a 14 reakcióhoz eredeti PNG és animáció, elkészült/jóváhagyásra vár/hiányzik állapot, tiltott gombok hiánynál. Betöltési hibánál nincs hamis hiányállítás; újrapróbálás elérhető. A production katalógus olvasása nem tart meg korábbi aszinkron tesztzónához kötött cache-future-t.
- Ugyanazon asset/hash másik karakterhez rendelése a REVIEW parserben hibát ad. A három meglévő klip jóváhagyási jelzői változatlanul false.
- Hét eseményszimuláció: naplómentés, XP, szint, karakter, kiegészítő, kihívás, bátorítás. Közvetlenül a helyi preview controllernek jelez, nem a globális eseménybusznak vagy tárolónak. Nem ír profilt, naplót, XP-t, korhatárt vagy feloldást.
- Sikeres nem szintlépő XP-mentéshez múló xpEarned jelzés; szintlépésnél megmarad a korábbi egyetlen erősebb jelzés. Újranyitás/ismételt napi jelölés nem jelez és nem jutalmaz újra. Kiegészítő-jelzés előkészített interfész, nem új jutalomrendszer.
- Gyengébb Androidhoz videókapcsolóval teljes PNG-mód, egy dekóder, nincs automatikus ciklus, korlátos mérések. Meglévő 540×720 néma klipek; nincs új átkódolás vagy RAM-teljesítményígéret. Az inicializálási adatok nem teljes RAM/telefonbenchmarkok.

## Médiakorlát

Jelenleg **0 jóváhagyott**, **3 fiú-fesztivál REVIEW-jelölt**, **249 hiányzó hozzárendelés**. Lány/semleges kész videó nincs. A 18 kinézet támogatása nem 18 elkészült animáció állítása. A hiányokat saját PNG kezeli; másik karakter klipjét nem helyettesítjük be. Új generálás, karakter-újrarajzolás vagy Higgsfield-kreditköltés nem történt.

## Tesztelési kapu

Új modell- és widgettesztek: pontos 252 hozzárendelés, minden család saját médiája, approval-gate, cross-look tiltás, XP egyszeriség/megőrzés, HU/EN 320/360/390/430 és 200%, mind a 18 választás ×14 kártya, hét read-only eseményszimuláció. Célzott új csomag: 15 ténylegesen sikeres teszt; a kapcsolódó meglévő részhalmaz külön fut. Ez nem teljes regressziós sikerállítás.

A CI teljes analyzert/regressziót/gen-l10n-egyezést, normál és Studio web/APK-t, API 35 x86_64 natív és valódi Windows Chrome-kaput futtat. A korábbi 52 böngészős állítás megmarad; az eredeti háromvideós teszt a régi előnézeti nézetet külön URL-paraméterrel éri el, és új Studio UI-kapu is fut. Natív oldalon a három valódi dekódolás HU/EN mellett lány/semleges Studio-állapotpróba is van. Végső darabszámok/commitok/csomagok kizárólag a tényleges friss futás alapján kerülnek a végső átadási jelentésbe.

Fizikai telefon, OEM-billentyűzet/fájlválasztó, gyenge telefon RAM/codec és tényleges régi verziófrissítés külön kézi ellenőrzés. Nem futott ellenőrzést nem nevezünk sikeresnek. Nincs schema/migráció, appadattörlés, új engedély, analitika, main merge, Play-feltöltés, publikálás vagy új release-kulcs. Médiaaktiváláshoz továbbra is tulajdonosi/azonossági/háttér/jogi jóváhagyás szükséges.
