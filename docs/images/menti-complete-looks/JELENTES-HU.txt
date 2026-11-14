# MennyiMent? 2.5.0+37 – három teljes kinézetes kísérlet

2026. november 14. · Alkalmazásforrás: **`592d49a9a66c32ae1a10c60f66899bb4fa767636`** · Külön ág: `experiment/menti-complete-looks` · [#41 draft PR](https://github.com/hunyakferenc-droid/mennyiment/pull/41).

[Előtte–utána képek és a teljes képgaléria](kepek-hu.md).

Az alkalmazásban kipróbálható három teljes Menti-kinézet. A látvány **nem tulajdonosilag jóváhagyott**. Ezzel a három mintával a további karaktergyártás megáll a közös értékelésig.

## Mi volt kész és maradt meg?

A nyelvválasztás, onboarding, korhatár, italnapló és szerkesztője, statisztika, pénzügyek, célok, XP, feloldások, kalandok és fájlos mentés/visszaállítás a meglévő megoldás maradt. A korábbi szabad karakterkombinációt és rétegeinek illesztését nem fejlesztettük tovább ebben a kísérletben.

A #40 és `fix/menti-character-quality` változatlan: `0bdb09cab60061367e590447dbce29c64ac73deb`, 2.4.1+36. A régi képernyőképek alkalmazásforrása `3df8f66c7be59a92314694f738753ce9cc8755e7`; a későbbi #40 HEAD dokumentációs változás. A külön régi munkakönyvtár tiszta maradt. Nincs main merge, Play-feltöltés vagy publikálás.

## Mit valósít meg a csomag?

- Három valódi, eltérő teljes kép: `boy-base-v1`, `girl-base-v1`, `neutral-base-v1`. A stabil katalógus családot, képhivatkozást és most mindháromnál `free` feloldási feltételt tartalmaz. Nincs 90 ál-választás vagy átnevezett másolatsorozat.
- HU/EN galéria nagy előnézettel, kiválasztott állapottal, Mentéssel, Mégsével és mentetlen választást védő visszalépéssel. A régi Studio mellett galéria-belépő, aktív teljes módban három teljes választás látható. Nincsenek hatástalan szem-/ruha-/sapkaréteg-vezérlők az új módban.
- A főoldal, profil, galéria, nagyító és kalandtérkép ugyanazt az elmentett teljes képet használja. A régi összeállítás külön menthető módválasztással visszakapható.
- Külön, verziózott `mennyiment_complete_look_v1` állapot, automatikus átalakítás nélkül. Snapshot-ellenőrzés, egyszeres írás, megerősített perzisztálás után felületfrissítés. Sérült/ismeretlen állapotnál írásvédelem; nincs hamis siker. Az új választás a meglévő export/import része, nem második naplótár.
- Az alapok környezete közös, egyszerű levendula. Egyedi hátterek és háttérválasztás későbbi feladat. A közös **megjelenítési** vászon 3:4, azonos talpvonallal és karakter-magassággal; a natív forrásméretek eltérhetnek, a karaktert egyik irányban sem nyújtjuk el.
- A nagyító valódi, legfeljebb 3× kétujjas nagyítást ad. A kis előnézet felnagyításából eredő arc-elmosódást külön javítottuk: a nagyító nagyobb dekódolást kér, legfeljebb a natív felbontásig. A normál kártyák kis dekódolása megmaradt.
- A profiláttekintés a választott teljes kinézetet nevezi meg; a visszaváltás visszaállítja a régi család/ruha feliratát is. A gyors újranyitáskor Mentést takaró korábbi snackbar megjelenését javítottuk. Mozgáscsökkentésnél a kijelölési átmenet is nulla idejű; a teljes karakter állókép. Nincs állított pislogás, beszéd vagy PNG-arcdeformálás.

## Grafikai eredet és ténylegesen átnézett konfigurációk

A [számozott eredetileltár](referencialeltar-hu.md) 18 változatlan PNG-je rendelkezésre áll: F01–F06 fiú, L01–L06 lány, S01–S06 semleges, a tulajdonosi besorolás alapján. A három mostani minta kizárólag F01/L01/S01 forrásból készült. A további 15 referencia nem új galériaválasztás.

A lány alkalmazásbeli képe **bájtra azonos az eredeti L01 PNG-vel**. A fiú és semleges generatív háttéreltávolításból származtatott kísérleti kép; ezeknél nem állítunk pixelazonosságot. Az első, sapkát a képszélig vivő semleges változat elutasítva. Az eredeti és új arc, haj, ruha, kéz, nyaklánc, sapka és cipő a képgalériában összevethető. A régi alkalmazásrender kizárólag összehasonlítás, nem forrás.

Átnézés: mindhárom minta normál méretben, nagyobb előnézetben, kétujjas nagyítás után; fehér és sötét Flutter-ellenőrzőlapon; főoldalon, profilban és kalandtérképen. A teljes karakter, talp, kéz és sapka a normál képen látható. A nagyításnál a részlet nézetablakból való kilógása szándékos nagyítás, nem a forráskép levágása.

- Normál Chrome-képmátrix: 3 minta × HU/EN × 320/360/390/430 px = **24 konfiguráció**, 844 px magassággal.
- Flutter-widget mátrix: HU/EN × négy szélesség × **200% szöveg**, mindhárom választással; nagyító, megszakítás, billentyűzet miatti 300 px takarás, mentés, újratöltés és régi módra váltás.
- Kétujjas zoom: három minta, HU, 390 px, Chrome érintésemuláció. Ez nem Android-emulátor és nem fizikai telefon.

## Friss ellenőrzések

Minden alábbi alkalmazásellenőrzés forrása `592d49a9a66c32ae1a10c60f66899bb4fa767636`.

| Ellenőrzés | Tényleges eredmény |
| --- | --- |
| Analyzer | Sikeres, nincs jelzés, helyben és CI-n |
| Teljes `flutter test --concurrency=2` | **1057 sikeres**, a 25 új célzott tesztet is beleértve |
| Külön Budapest/DST részcsomag | **349 sikeres**, a teljes csomaggal átfedő ismételt részhalmaz |
| Lokalizáció + generált deklarációk | **916 egyező HU/EN kulcs**, nincs fordítatlan üzenet vagy generálási eltérés |
| Webbuild | Helyben és CI-n sikeres; a csomag helyi CanvasKitet/fontokat tartalmaz |
| Debug APK-build | Helyben és CI-n sikeres; alkalmazásazonosító és verzió ellenőrizve |
| Release-aláírás védelme | A hiányzó/debug aláírás elutasításának CI-próbája sikeres; release AAB nincs |
| Chrome – folyamatok és képek | **10 sikeres HU/EN alkalmazásfolyamat**, **24 normál méretkép**, **3 valódi érintésemulációs nagyítás**; nincs runtime-hiba vagy új külső kérés |

[Teljes sikeres CI-futás és napló](https://github.com/hunyakferenc-droid/mennyiment/actions/runs/43564321168).

Friss, ehhez a forráshoz tartozó letöltések (GitHub-bejelentkezés szükséges lehet; megőrzés 2026. november 28-ig):

- [Web ZIP](https://github.com/hunyakferenc-droid/mennyiment/actions/runs/43564321168/artifacts/14101538615) – kibontás után `INDITAS.cmd`; ZIP SHA-256: `124d69e4829691e5c0b207e70177a206b327c2c7708f7a6ee7a3122a7902a5ca`.
- [Debug APK-csomag ZIP](https://github.com/hunyakferenc-droid/mennyiment/actions/runs/43564321168/artifacts/14101863145) – az `app-debug.apk`, ellenőrzőösszeg, aláírási jegyzőkönyv és magyar útmutató együtt; ZIP SHA-256: `2b80a1ae1a2737015c4f3ada03ebe94546fd9121f04ccfdca23765add3f34912`.

A Web ZIP körülbelül 93,2 MB, az APK-csomag ZIP körülbelül 160,2 MB. Ezek debug/kísérleti csomagok, nem publikálásra kész kiadások.

A 349 tesztes célzott részcsomag a teljes tesztcsomaggal átfed; nem adjuk össze önálló új tesztként. Korábbi csomagok 651/727/1032 tesztje vagy régi Chrome-ellenőrzése nem ennek a kiadásnak az eredménye. Meglévő tartalmi állítás vagy golden-tolerancia nem gyengült; golden-referencia nem frissült.

A helyi teljes futás első próbája UTC-ben elbukott a Budapest DST-előfeltételen; nem sikeres eredmény. A helyi duplikált teljes futást erőforrás-megosztás miatt leállítottuk, a teljes csomagot a megfelelő időzónával a GitHub CI futtatja végig. A végső sikeres eredmény onnan származik. A korábbi `81007af` CI-futásban a teljes 1051 teszt sikerült, majd pub.dev-hálózati és NDK-letöltési hiba történt; ez nem a végső sikeres futás. A `592d49a` CI az első kötelező dependency-ellenőrzés után `--no-pub` kapcsolóval ugyanazokat a feloldott függőségeket használja, tesztkihagyás nélkül. A korai kivágási és képrögzítési próbák nem kész csomagként kerültek átadásra.

## Képméret és terhelés

A három PNG összesen **4 214 320 bájt**: fiú 1 283 066, lány 1 760 755, semleges 1 170 499 bájt. A natív RGBA memória képenként körülbelül 6,29 MB; a teljes natív érték felső becslés, nem a normál kártya tényleges cache-mérete. A normál megjelenítés a méret és eszközpixelsűrűség alapján kisebb képet dekódol; a nagyító legfeljebb háromszoros célt, a natív szélességig. Egyetlen teljes PNG van karakterenként, nincsenek mozgó arcrétegek vagy új futásidejű külső képletöltések.

Az önálló szoftveres dekódolási mérés három képen, 180/360/720/natív célszélességen rögzít olvasási időt, dekódolási időt és tényleges RGBA-méretet. Ez egy helyi Linux-mintavétel, nem Android FPS-, akkumulátor- vagy telefonos memóriaeredmény. A böngészős fájlbetöltési idők helyi HTTP-kiszolgálóra vonatkoznak. A nyers mérés és a fájlok SHA-256 lenyomata a galériacsomagban szerepel. A letöltött CI-webcsomag külön indulás → lány kiválasztása → mentés → újratöltés → tényleges profil próbaköre is sikeres. A helyi és CI-webbuild `main.dart.js` fájlja és további 347 fájlja bájtra egyezik; a különbség a build-jegyzőkönyv és a bootstrap/SW-metaadat. A 25 új célzott teszt a tárolási hibák, külső snapshot-eltérés, dupla mentés és export/import mellett a tényleges profilnézet helyes feliratát és visszaváltását is ellenőrzi. A képeken látható `girl adult`/`boy adult` nevek szintetikus tesztprofilnevek, nem felhasználói adatok.

## Kipróbálás és adatmegőrző frissítés

A [rövid magyar útmutató](kiprobalas-hu.md) külön kezeli a kész Web ZIP-et és a Flutter-forrást. Kész ZIP: teljes kibontás → `INDITAS.cmd` → **http://127.0.0.1:7357**. Nem kell Python. Ugyanazt a böngészőprofilt, hostot és portot használd; az indító nem töröl adatot. A PowerShell-kiszolgálót Linuxon ténylegesen használtuk, valódi Windows-gépet nem állítunk teszteltnek.

Galéria: további műveletek → Beállítások → Teljes Menti-kinézetek, vagy a régi Studio galéria ikonja. Választás → Mentés; újranyitáskor ugyanaz legyen. Mégse/visszalépés elvetési megerősítést ad. Korábbi összeállítás használata → Mentés visszahozza a régi Mentit.

Az alkalmazásazonosító továbbra is **`com.example.mennyiment`**, buildszám **37**, min SDK **24**, target SDK **36**. A debug APK nem publikálásra kész kiadás. Aláírt release AAB nem készült; a hiányzó/debug release-aláírást elutasító meglévő védelem megmaradt.

A hivatkozott **CI-APK** aláíró tanúsítványának SHA-256 lenyomata:
`c2aa6f45b0d1b171045961395e54315fc03dc4441b14a88d65d2446a31950af1`.

A helyi debugbuild külön tanúsítványa `bc7109b7016de67d7bad33c7fabbdf4ba56be793bd3ab1f05cff92155bacf6d7`; nem tévesztjük össze a letöltésként hivatkozott CI-APK-val. A csomagon belüli APK **242,504,816 bájt**, SHA-256: `f72d90b96828f753781c276c69a3d734a45b25a8438161edf339f4697ca04949`. Az aláírás, alkalmazásazonosító, ZIP-integritás, 16 KB ZIP-igazítás és a 64 bites ELF-illesztések újraellenőrzése sikeres; a `ci-apk-verification.json` tartalmazza a részleteket.

A régi, ellenőrzött 2.4.1 CI-APK tanúsítványa `e93201f1c6c3c414a01db7dda285a66313999eb96d6148456e1b3206998fde3d`. A külön CI-futások debugkulcsa nem folytonos. Ha a telefonon ez a korábbi aláírás van, eltérő új kulccsal nincs közvetlen adatmegőrző frissítés. A korábbi aláírókulccsal újraépítés szükséges; meglévő alkalmazás törlését nem javasoljuk. Nem készítettünk kiadási kulcsot és nem tettünk titkot a repóba.

## Amihez telefonos ellenőrzés kell

Nincs csatlakoztatott Android-eszköz az `adb devices` listában. Fizikai telepítés, adatmegőrző APK-frissítés, Android-rendszer-vissza, valódi billentyűzet, fájlválasztó, natív 16 KB futtatás és eszközös sebesség nem tesztelt; Android-emulátor sem futott.

1. Azonosítsd a telefonon levő APK aláírását és a korábbi kulcs elérhetőségét, mielőtt frissítenél. Előtte készíts és ellenőrizz exportot; ne töröld az alkalmazást.
2. HU/EN és nagy rendszerbetű: a három mintát válaszd, mentsd, indítsd újra. Ellenőrizd a főoldalt, profilt és kalandot.
3. Kétujjas nagyítás és görgetés; rendszer-visszával a mentetlen választás védelme.
4. Export/import valódi Android fájlválasztóval; régi módra visszatéréskor a régi profil, XP, feloldás és napló maradjon meg.
5. A fiú/semleges kivágást és a három mintát vizuálisan értékeld az eredetiek mellett. További kinézet és egyedi háttér csak e kapu után készül.
