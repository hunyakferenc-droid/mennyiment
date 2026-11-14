# Menti Life 2.7.0+39 – műszaki és médiaátadás

Alap: #42 draft PR, `93f298b80c5f5ae7fb31f557663e5d00dcd431b5`. A gyűjtemény, a 18 karakter, a Studio, a napló, a kalandok, az XP és a korhatárszabályok már elkészültek; ezeket a csomag felhasználja. Az eredeti PNG-k változatlan SHA-256 lenyomatait a `png-audit.json` tartalmazza.

## Elkészült rendszer és jelenlegi médiakorlát

A Flutter-motor 18 változatlan CompleteLook.id × 14 reakció párosítását támogatja. A gyártási katalógusban jelenleg **0 jóváhagyott klip** található. Emiatt a kiadott csomag minden karaktert saját eredeti PNG-jével jelenít meg, a reakciópróbák pedig inaktívak. Másik kinézet videójára nincs helyettesítés, mesterséges pislogás vagy újragenerált karakterkép.

A `media-inventory.json` a ténylegesen elért 13 Higgsfield-generálás pontos azonosítóját, forrás-URL-jét, referenciaazonosítóját, lenyomatát és formátumát rögzíti. Mindegyik ugyanahhoz a fiú fesztivál-referenciához kapcsolódik; a másik 17 kinézethez nem találtunk klipet. A referencia vizuális egyezése jelöltbesorolás, nem tulajdonosi jóváhagyás. Kezdő/középső/záró képkockák technikai átnézése történt mind a 13 klipnél. Ez nem teljes mozgásminőség-jóváhagyás.

A videók tényleges mérete 834×1112, H.264/yuv420p, kb. 5,04 másodperc, átlátszóság nélkül. Lilás stúdióhátterük nem az alkalmazás jóváhagyott háttere. A `61454a63-00e0-4145-8b96-77a3a0b2bfed` légzésjelölt AAC hangsávot is tartalmaz. A motor helyi médiakerete legfeljebb 720×960, 8 másodperc és 6 MiB; a jelöltek jelenleg felbontásban is meghaladják a keretet. Nem alakítottuk át őket jóváhagyott assetté.

A Higgsfield hivatalos jogi feltételeinek feltárását HTTP 403 akadályozta (`license-review.json`). A felhasználási jog, tulajdonosi hozzájárulás, karakterazonosság és háttérkezelés jóváhagyása hiányzik. Új generálás vagy fizetős művelet nem történt. A forrás-URL-ek csak dokumentációban szerepelnek, futásidőben nem töltünk le videót.

## Lejátszás és biztonságos visszaesés

A helyi katalógus verziót, kinézetet, reakciót, médiaverziót, SHA-256-ot, méretet és névvel/dátummal rögzített jóváhagyást vár. Az ismeretlen katalógus, hibás fájl, eltérő hash, inicializálási/lejátszási hiba visszaállítja az eredeti PNG-t. A fájl megnyitása előtt méret- és hash-ellenőrzés történik; inicializálás után a tényleges videóméret és hossz is ellenőrzött. Csak helyi assetútvonal engedélyezett.

Egy globális soros dekóderbérlet biztosítja, hogy egyszerre egy lejátszó legyen, a legnagyobb látható, mentett karakterhez tartozó felületen. Más felületek PNG-k. Karakterváltás, útvonalváltás, képernyőről kigörgetés, háttérbe kerülés, animációtiltás és csökkentett mozgás megszakítja a lejátszást. A későn befejeződő inicializálás generációs azonosítóval érvényteleníthető. Sikertelen erőforrás-felszabadítás után nem indul második dekóder.

A hangerő inicializáláskor és minden indításkor 0; ismétlés és háttérlejátszás nincs. Inicializálás/fájlellenőrzés 4–4 s, indítás 2 s határidővel; a lejátszást hossz+1 s biztonsági időzítő is lezárja. Gyenge eszközön vagy hibánál statikus visszaesés van, automatikus újrapróbálási hurok nincs.

Az átmeneti mérés az utolsó 20 indítás fájlméretét és inicializálási idejét tárolja memóriában. A width×height×4 szám csak egy RGBA-képkocka becsült mérete, nem az alkalmazás tényleges RAM-fogyasztása. Nincs analitika, külső küldés, háttérszolgáltatás vagy új rendszerengedély.

## Események és elsőbbség

| Megerősített esemény | Reakció | Prioritás |
|---|---|---:|
| Megnyitás látható mentett teljes karakterrel | Üdvözlés | 10 |
| Sikeresen mentett naplózás | Semleges mosoly | 10 |
| Napi önellenőrzés | Bátorítás | 30 |
| Meglévő kalandfeladat teljesítése | Bátorítás | 40 |
| Esti önellenőrzés | Pihenés | 50 |
| Valódi XP-szintátlépés | Gratuláció | 60 |
| Új kinézet tartós megszerzése | Öröm | 65 |
| Valóban teljesült vállalt cél/állomás | Mérföldkő | 70 |
| Önkontroll-esemény motorbemenete | Nyugodt légzés | 80 |
| Nehéz napként elmentett önellenőrzés | Együttérzés | 90 |

A motor a többi reakciót kézi előnézethez vagy későbbi, valódi eseményhez ismeri; nem talál ki teljesítést. Az önkontroll külön motorbemenete jelenleg nem kap új termékfolyamatot. A napló eseménye nem jutalom és nem ad XP-t. A meglévő XP-számítás változatlan; migráció/újratöltés nem indít visszamenőleges ünneplést.

Automatikus gyakoriság: ritka 120 s, normál 30 s, gyakori 10 s. Magasabb prioritású sürgős megszakítás kivételt képez, de az eseményazonosító szerinti duplikációszűrés alól nem. Kézi próba kifejezett műveletként megkerüli a gyakoriságot. Alacsonyabb prioritás és elavult esemény eldobódik; nincs sorba gyűjtött, később váratlanul lejátszott esemény.

## Tárolás, felület és visszaállítás

Az egyetlen új tartós kulcs a megjelenítési beállítás: `mennyiment_life_settings_v1` (version 1, enabled, frequency). Nem második napló, nem profil- vagy XP-migráció. Ismeretlen mezők megmaradnak; hibás/ismeretlen verzió írásvédett. Mentés: pillanatkép-ellenőrzés → perzisztálás → visszaolvasás → felület. Sikertelen vagy párhuzamos írás nem mutat hamis sikert. A meglévő fájlos export/import ezt a kulcsot is kezeli, régi mentés nem törli.

A Beállításokból és a mentett gyűjteményből elérhető HU/EN Menti Life nézet a tényleges karaktert és a tényleges médiakészletet mutatja. A Studio és a korábbi összeállításra visszaváltás megmarad. Kiskorú mód és jutalmazás nem változik.

## Fejlesztői dekóderpróba

A `tool/menti_life_decoder_probe.dart` külön, explicit célpont. A tesztábrás MP4 nem Menti-kép, nem gyártási katalógus és nem része a normál web/APK csomagnak. Csak a valódi videódekóder és a némítás ellenőrzését szolgálja; eredménye nem karaktervideó-jóváhagyás.

A friss ellenőrzések, forráscommit és letöltések külön átadási jelentésben szerepelnek. A 2.6-os 1111 teszt történeti alap, nem a 2.7 automatikus eredménye.
