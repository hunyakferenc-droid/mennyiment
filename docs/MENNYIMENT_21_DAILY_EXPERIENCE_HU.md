# MennyiMent? 2.1 – F: Menti minden nap

Specifikáció: https://github.com/hunyakferenc-droid/mennyiment/issues/22
Alap: #21 ellenőrzött HEAD, `81877d32001d70069cc55eabea9f9178a1abfa06`.
Új ág: `feature/mennyiment-2-daily-experience`. A külön draft PR a #21 `feature/mennyiment-2-personal-hub` ágára céloz. A main és #21 ága nem módosul; merge és kiadás nincs.

## F1 – opcionális bemutatkozás

Négy rövid HU/EN lépés mutatja be a meglévő karaktert, italnaplót/költséget, napi önellenőrzést/XP-t és a helyi adatokat/mentéseket. Valós funkciókról szól, nincs kész közösségre, webshopra vagy szinkronra vonatkozó ígéret. Csak a meglévő eredeti Menti PNG-t használja. Felhasználói naplóérték vagy szabad szöveg nem kerül a bemutatkozó szövegébe.

A backup-helyreállítás változatlanul megelőz minden új preferenciaolvasást és minden appképernyőt. Sikeres recovery után, a kezdőlap korábbi migrációi előtt a kulcsnevek alapján döntünk a meghívóról. Bármely meglévő `mennyiment_` üzleti vagy ismeretlen jövőbeli kulcs meglévő telepítésnek számít; érzékeny naplóértéket ehhez nem olvasunk. A két új megjelenítési kulcs önmagában nem üzleti adat. Hibás vagy már jelen levő bevezetőjelző mellett nincs újtelepítési meghívó.

Új, adatok nélküli telepítésen nem kötelező teljes képernyős flow indul, hanem egy kihagyható kezdőlapi meghívó. A korábbi automatikus karakterválasztó route megnyitása megszűnt: a karakter és gardrób továbbra is a meglévő gombokról érhető el. Így sem új, sem régi profil nem kerül kényszerű onboardingba. A bemutatkozó megnyitása, lapozása és rendszer-vissza megszakítása nem ír adatot. Csak az explicit „Átugrás” vagy utolsó lépés befejezése menti a látottságot. Sikertelen mentésnél nincs hamis siker és bezárás; a visszaút elérhető marad.

A Beállítások és súgó oldalról a bemutatkozó bármikor újranyitható. Restore után a Navigator és a megjelenítési scope újratöltődik a meglevő root-folyamat részeként, a friss telepítési meghívó pedig nem indul újra.

## F2 – megjelenítési preferenciák

| Kulcs | Típus, alapérték | Mikor írunk? |
| --- | --- | --- |
| `mennyiment_reactions_enabled_v1` | bool; hiányzó értéknél true | Csak a reakciókapcsoló explicit módosításakor. |
| `mennyiment_intro_seen_v1` | bool; hiányzó értéknél false | Csak explicit befejezés vagy átugrás után true. Már true állapot idempotens. |
| `mennyiment_reduce_motion_v1` | meglévő bool és meglévő alapérték | A korábbi mozgáskapcsoló változatlan tárolója. |

A megnyitás és betöltés nem ment alapértékeket. Ismeretlen típusú új preferenciát nem normalizálunk vagy írunk felül; a UI biztonságosan letiltja a reakciókat, és lokalizált újrapróbálást ad. Írás előtt újraolvasunk és az adott kulcs pillanatképét ellenőrizzük. Hamis/kivételes/nem igazolt mentésnél a korábbi megjelenítési állapot marad, cache-újraolvasással. Más kulcs nem változik.

A reakciókapcsoló a kezdőlapi üzenetet, napi minikártyát, fejlődési buborékot és a #19/#21 igazolt eseménykártyáit vezérli. Az elnyomott esemény nem játszódik újra visszakapcsoláskor; új igazolt esemény saját megjelenítési tokent kap. Ez csak memóriabeli UI-azonosító, nem XP-esemény vagy új tartós jutalomnapló. A reakció kikapcsolása nem ír XP-t, naplót, célt, ruhát vagy feloldást.

A mozgáskapcsoló új HU/EN feliratokat kapott. Az OS mozgáscsökkentés és akadálymentes navigáció elsőbbsége megmarad. A fő Menti Evolution belépő mozgása egyetlen rövid ciklusra korlátozott, a reakció szintén véges; nincs új blokkoló vagy végtelen animáció. A korábbi többi avatar és funkció a meglévő rendszeres/manuális mozgásszabályt használja. Csendesebb megjelenítés a reakciók teljes kikapcsolásával választható; külön humorintenzitás-beállítás nem készült.

A backup-formátum és a restore-séma nem változott. A meglévő exporter minden `mennyiment_` kulcsot támogatott típusával ment, ezért az új boolok is részei a mentésnek. Régi, ezek nélküli mentés visszaállítása megőrzi a helyi új preferenciákat. Ismeretlen jövőbeli kulcsok/mezők és az eredeti felhasználói adatok megmaradnak.

## F3 – Ma Mentivel

A kezdőlap nem takaró, természetes magasságú kártyája a #21 csak olvasó adapteréből veszi az állapotot. A fő italrögzítő CTA előtte marad. A szöveg a rögzített személyes cél/kihívás, mai napi válasz vagy XP-önellenőrzés alapján választ; hibás/hiányos adatnál nem találgat. A hiányzó napló nem absztinencia, a költés vagy italok mennyisége nem jutalom.

A meghívó jellegű variáns naptári dátumból determinisztikusan választódik; újrarajzoláskor nem ugrál. A kártya nem emittál jutalomeseményt, nem hoz létre bejegyzést, nem ad XP-t. Napváltáskor, app-resume után és a releváns meglévő oldalakból visszatérve újraolvas. Az elavult async válasz nem írhat felül frissebbet. A gombok a meglévő napi Menti és áttekintő oldalt nyitják. Betöltés és nem olvasható adat külön, semleges üzenetet kap.

## F4 – következetes állapotok

A kezdőlap és a teljes olvasható napló üres állapota közös Menti-hangvételű, cselekvésre alkalmas szöveget és a meglévő rögzítésre vezető gombot használ. A személyes központ hiányzó adat felirata ehhez igazodik, az adatkorrupt állapot és újrapróbálás pedig külön marad. Az ismert nulla, hiányzó bejegyzés és ismeretlen ár korábbi, tesztelt különbsége megmarad. Nem alakítottuk át a teljes navigációs/tárolási architektúrát.

## Tesztek és futási bizonyíték

Az új preferencia-tesztek: alapértékek írás nélküli olvasása; új/régi/unknown telepítés; hibás preference; pillanatkép-ütközés; hamis/kivételes és tartósan végrehajtott, de nem igazolt írás; ismételt introjelzés; régi és új backup/restore; teljes üzleti adatkészlet megőrzése.

Az új widget/regressziós esetek: HU/EN, 320/360/390 px, 100%/200% intro és 200% beállítások; mind a négy lépés; megszakítás/átugrás/újranyitás/mentési hiba; meglévő profil kényszerű flow nélkül; recovery-gate; reakciótiltás és visszajátszás-védelem; OS motion-elsőbbség; véges animáció; billentyűzetfókusz; determinisztikus minikártya; napváltás/resume; Budapest ismételt óra és ISO évhatár. A #19/#21 teljes regressziói megmaradnak. A stacked PR trigger a #21 célágával bővül, védelmi szabály/jogosultság nem változik.

Helyi Flutter SDK továbbra sem elérhető. Az öt kötelező Flutter-parancs és célzott Budapest-tesztek valós helyi eredményét külön rögzítjük; helyi sikert nem állítunk. A teljes GitHub Actions CI futását megvárjuk, hibáit javítjuk. A jelentés végére a végleges futási bizonyíték kerül; a PR-leírás az aktuális HEAD állapotát mutatja.

## Manuális Chrome / Android terv – még nem végrehajtott

1. Tiszta Android/web tárhely, majd régi profilt, XP-t, ruhát és naplót tartalmazó frissítés: meghívó csak tiszta telepítésen, kötelező route egyiknél sem. Intro vissza/átugrás/befejezés és a Súgóból újranyitás.
2. 320/360/390 dp, 200% szöveg, Chrome zoom, TalkBack/VoiceOver és billentyűzetes Tab/Shift+Tab/Enter/Space. A fő italrögzítés maradjon elérhető; minden lépés és gomb görgethető, felolvasható legyen.
3. Reakciók ki/be, majd új igazolt cél, ugyanazon esemény újranyitás nélkül; manuális és OS reduce-motion külön/együtt. Háttérbe lépés és visszatérés, véges mozgás, fókusz és kontraszt mérése.
4. Budapest éjfél, DST ismételt óra, vasárnap/hétfő, december/január; napi szöveg stabilitása sima rebuild és tényleges adatfrissítés között.
5. Export/restore régi és új mentéssel; napló, saját italok, XP, összes feloldás, cél és unknown mezők összehasonlítása. Ismeretlen ár és valódi 0 Ft külön; hibás adatnál nincs fogyasztásra vonatkozó állítás.

Nem készült backend, regisztráció, közösség, webshop vagy szinkron. A bolti/jogi és képernyőolvasós/készülékes kézi ellenőrzések továbbra is kiadás előtti kapuk. A kész csomag nem jelent automatikus kiadásengedélyt.

Az első CI-futás után két tesztfeltételezés javítva: a nagy betűméretes intro teszt közvetlenül a lépésjelzőre görget (a címre igazítás után a lusta lista korábbi eleme már nem feltétlenül van felépítve); a régi backup visszaállításának elvárása a meglévő restore-szabály szerint egyesített/rendezett feloldásazonosítókat ellenőrzi. Egyetlen feloldás sem veszett el, a restore implementáció nem változott.

F4 pontosítás: a kezdőlap a hiányzó naplódokumentum helyett nem mutat nulla adatlapkákat; a teljes napló megkapja a pillanatkép dokumentum-létezési jelzőjét. A mentett üres lista és a hiányzó napló eltérő szöveget kap, külön kezdőlap → napló regresszióval. Ez a jelző csak UI-pillanatkép, nem új tárolókulcs.

## Igazolt CI-eredmény – 2026. november 1.

Draft PR: https://github.com/hunyakferenc-droid/mennyiment/pull/23
Célág: `feature/mennyiment-2-personal-hub` (#21).
Tesztelt implementációs HEAD: `632308bf5a704ae044aec9e76facad7907001f83`.
Teljes sikeres CI: https://github.com/hunyakferenc-droid/mennyiment/actions/runs/41289031979

| Ellenőrzés | Helyi eredmény | GitHub Actions |
| --- | --- | --- |
| `flutter pub get` | 127, Flutter SDK nincs | success |
| `flutter gen-l10n` | 127, Flutter SDK nincs | success |
| `flutter analyze` | 127, Flutter SDK nincs | success, No issues found |
| Teljes `flutter test --concurrency=2` | 127, Flutter SDK nincs | success |
| Europe/Budapest célzott F + A–E / backup / DST regressziók | 127, Flutter SDK nincs | success |
| `flutter build web` | 127, Flutter SDK nincs | success |
| Whitespace | `git diff --check` success | success |
| HU/EN ARB-kulcsok, helyőrzők | Python-ellenőrzés success | lokalizációs tesztek success |

A kezdeti tesztfeltételezések javítva; a végső implementáció minden kötelező CI-lépése sikeres. A további stabilizálás külön kezeli a hiányzó és mentett üres naplót, kikapcsolt üzeneteknél a céloldal opcionális kommentárját is elrejti (a tények és óvatossági szöveg megmaradnak), és az idempotens intro-befejezés előtt is újraellenőrzi a tárolt jelzőt. Ezekhez új regressziók készültek és sikeresen lefutottak.

A köztes, új commit miatt automatikusan cancelled futások nem tesztbizonyítékok. A fenti eredmény a megnevezett implementációs SHA-hoz tartozik. E dokumentációs eredményrögzítés külön commit; az aktuális HEAD végső CI-jét a PR Checks és a PR-leírás mutatja.

A #21 és a main változatlan, nincs merge vagy publikálás. A kézi Android/Chrome, valódi képernyőolvasó és mért kontraszt vizsgálat nem történt meg; a fenti terv nyitott kézi feladat marad. A SharedPreferences pillanatképvédelem nem többfolyamatos ACID-garancia, és a widgetteszt nem helyettesíti a fizikai készülék vizsgálatát.
