# Lány és semleges alap Menti – 3.0.1+43 REVIEW-bírálat

Alap: #46 zöld `89ee48fa53323fb3149a01ba176032ec8654ff5a`, CI 44785251715. Külön ág: feature/menti-base-animation-review. A korábbi PR és csomagok változatlanok.

18 kész jelölt ténylegesen letöltve, hash-elve, teljes adatfolyamként dekódolva. Minden job bemeneti PNG-jének teljes bájtsorozata egyezik a saját eredeti girl-base / neutral-base képpel. Mindegyiknél eredeti PNG + eleje/negyede/közepe/háromnegyede/vége összehasonlítás készült. A három újonnan kiválasztott klip további 20 időbeli mintaképe is átnézett (01/02/05-motion20.jpg). Ez mintavett vizuális vizsgálat, nem minden képkockára kiterjedő tulajdonosi jóváhagyás. Új generálás és kreditköltés nincs.

## Első kör: üdvözlés, kacsintás, gondolkodás

Lány: welcome (új), wink (új), thinking (meglévő). Semleges: welcome (meglévő), wink (új), thinking: PNG (forrás levágja a lábakat). A három fiú-fesztivál REVIEW-videó változatlan. Összesen 8 REVIEW, 244 hiányzó, 0 jóváhagyott a 252 hozzárendelésből.

Csak a külön REVIEW-csomagba kerülnek. A forrás beégetett lila/fehér/fekete/szürke hátterei megmaradnak, képaránytartó fekete levélszegéllyel; nincs kivágás, háttércsere, karakterrajzolás vagy alap-PNG módosítás. A lány üdvözlő mozgás nyugalmi póza eltér a PNG-től, ezt nem rejtjük el. Minden tulajdonosi, karakterazonossági, háttér- és jogi approval false marad.

## Tényleges döntések

| # | Karakter / reakció | Job | Döntés, konkrét megfigyelés |
|---|---|---|---|
| 1 | girl / welcome | `d3080242-c4c1-4321-8b74-4d37e05fbc67` | **selected-review**: Jól felismerhető integetés, teljes alak és ruházat; lila beégetett forrásháttér, módosult nyugalmi póz. A joy leltárcímke hibás: prompt és mozdulat alapján welcome. [Képek](frames/01-comparison.jpg) |
| 2 | girl / wink | `59dc7f08-d30f-4f1b-926a-59909de391ea` | **selected-review**: Egy szem jól felismerhető kacsintása, teljes alak, eredeti haj/sapka/ruha; fehér forrásháttér. [Képek](frames/02-comparison.jpg) |
| 3 | girl / thinking | `2ce3052d-63b1-411d-bf31-b5ec7d87218f` | **retained-review**: Meglévő saját gondolkodás: felfelé nézés, szemöldök és fejmozdulat; teljes alak, fekete háttér. Nem cseréljük le. [Képek](frames/03-comparison.jpg) |
| 4 | neutral / welcome | `79e32807-6863-468c-bd92-63e03c7cbf4c` | **retained-review**: Meglévő saját integetés: teljes alak, sapka/fejhallgató/ruha megmarad; szürke háttér. Nem cseréljük le. [Képek](frames/04-comparison.jpg) |
| 5 | neutral / wink | `7b27c79a-0111-47d0-920c-ff225f21852c` | **selected-review**: Egy szem kacsintása, finom fejbillentés, teljes cipők és ruházat; fehér forrásháttér. [Képek](frames/05-comparison.jpg) |
| 6 | neutral / thinking | `1846e7eb-74a7-4cd0-a0fd-5eb0bbe57c3e` | **rejected**: Az alsó test és lábak levágva a széles forrásban. A reakció felismerhető, de teljeskinézetes összehasonlításhoz nem megfelelő; thinking saját PNG marad. [Képek](frames/06-comparison.jpg) |
| 7 | girl / joy | `aab0ec1a-6b14-47cc-a1f5-a10c06c95514` | **deferred**: Teljes alak, vidám fej-/szem-/szájmozgás; a végpóz mosolya eltér a referenciától. Nem az első kör három reakciója; nincs bekötés vagy jóváhagyás. [Képek](frames/07-comparison.jpg) |
| 8 | girl / applause | `6bffec42-14ed-4751-8c57-9f05e2cff2d5` | **rejected**: Tapsolás felismerhető, de az alsó test/cipők végig a képen kívül. [Képek](frames/08-comparison.jpg) |
| 9 | neutral / breathing | `6d4ce078-4f57-4f79-8a05-5e6926cdde5f` | **rejected**: Légzés/arcmozgás mellett az alsó test és cipők le vannak vágva. [Képek](frames/09-comparison.jpg) |
| 10 | girl / breathing | `cb62d02d-6142-464b-beca-9c938e2634d1` | **deferred**: Teljes alak, kis száj-/fejmozdulat; a légzés mint önálló reakció nem egyértelmű a mintákban. Első körön kívüli, nincs bekötés. [Képek](frames/10-comparison.jpg) |
| 11 | neutral / surprise | `5ab6fd6d-69ba-4175-ba7c-409a99a08584` | **rejected**: Meglepett arc felismerhető, de a teljes alsó test hiányzik a széles képből. [Képek](frames/11-comparison.jpg) |
| 12 | girl / surprise | `cf12b79e-5df8-46de-83e2-1dda07d0c251` | **rejected**: Meglepett arc/kézmozdulat, de az alsó test és lábak levágva. [Képek](frames/12-comparison.jpg) |
| 13 | neutral / encouragement | `f16ba0be-f2ea-45ee-985b-a1013663b964` | **rejected**: Pozitív kézmozdulat felismerhető, de a széles keret levágja az alsó testet. [Képek](frames/13-comparison.jpg) |
| 14 | girl / encouragement | `95b6c6de-681d-4a10-a79e-d1f16d329b4e` | **rejected**: Arc és bátorító hüvelykujj, de a térd/cipő a képen kívül marad. [Képek](frames/14-comparison.jpg) |
| 15 | neutral / congratulation | `13a3bf3d-b9e7-40ef-b588-3e150eb83ae3` | **deferred**: Teljes alak és taps, ruházat felismerhető; első körön kívüli gratuláció, további mozgás-/háttérbírálatra félretéve. [Képek](frames/15-comparison.jpg) |
| 16 | girl / congratulation | `3ffe0363-649e-48a9-b360-676b23087041` | **deferred**: Teljes alak, taps és pozitív arc; első körön kívüli gratuláció, nincs automatikus bekötés. [Képek](frames/16-comparison.jpg) |
| 17 | neutral / joy | `249b64ec-5058-4bb8-85ad-f73115b499c0` | **deferred**: Teljes alakú öröm/ugrás; végén eltérő nyitott karpóz, első körön kívül. Visszatérés és teljes mozgás külön bírálatra vár. [Képek](frames/17-comparison.jpg) |
| 18 | girl / joy | `c5590acc-c141-41d0-8553-bb28a2649bf7` | **rejected**: Ugrás közben csillagalakúra változó pupillák és erősen módosult arckifejezés; a szigorúan eredeti arcot őrző első körbe nem kerül. [Képek](frames/18-comparison.jpg) |

## Ellenőrzési kapu

A meglévő Studio/lejátszó/katalógus marad. A nyolcklipes csomagolást pontos név/hash/forrásazonosító védi; a normál app nem kap videót. HU/EN natív próba mind az öt saját alapklipre: Play → valódi képkocka → új dekóderes Restart → Stop/PNG → új Play → váltás a másik családra lejátszás közben. Mind a 14 slot elérhetősége pontosan ellenőrzött; hiánynál nincs idegen videó. A régi hat fiú-lejátszási állítás megmarad.

A friss eredményt kizárólag az új forráscommit CI-je után szabad sikeresnek nevezni. A korábbi 1214 teszt és 62 Windows-ellenőrzés történeti alap. Fizikai telefon, gyenge eszköz, OEM-fájlválasztó és korábbi telefonos APK-ról frissítés külön kézi próba. A debug CI-kulcs változhat: ütközésnél őrizd meg a telepítést/adatot, használd a webes REVIEW-t. Nincs main merge vagy publikálás.
