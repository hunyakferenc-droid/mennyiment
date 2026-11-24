# MennyiMent? 3.3.0+46 – Android/Play előkészítés

Alap: #50, e75e1ed6e2b852600e9833453931dd2d23ed45e4. A korábbi PR és munkafák megmaradnak.
Ez fejlesztési dosszié, nem benyújtott Play Console nyilatkozat vagy publikált kiadás.

## Ami már kész volt

A 2.3.1-es Play-dosszié, az Adatok és biztonság/Névjegy/Súgó nézetek, az export/import,
a külső release-aláírási konfiguráció és a hiányzó/debug aláírást elutasító Gradle-őr.
A #50-ből megmarad a HU/EN kezdőlap, nyolc saját REVIEW-videó, Ritmus, Mozgáskártyák,
hétnapos kihívás, külön saját/próbaadatok és a helyi rekordok. Ezek nem újrafejlesztések.

## Konkrét hiányok javítása

- A kezdőlapi REVIEW Android-neve most MennyiMent? REVIEW, saját R-jelölésű ikonnal;
  a normál MennyiMent? neve/ikonja/azonosítója változatlan.
- A kedvenccsillag korábban a mentés sikerétől függetlenül átváltott. Most snapshot,
  írási őr, perzisztálás és visszaolvasás után frissül. Íráshiba, dupla koppintás,
  külső eltérés, ismeretlen típus és régi dinamikus stringlista célzott tesztet kapott.
  A meglévő mennyiment_favorites_v1 kulcs és azonosítók megmaradnak.
- A virtuális próbaóra explicit REVIEW-jogosultsághoz kötött; normál használatban
  egy testMode paraméter önmagában sem aktiválja. REVIEW-ban menet közben is léptethető,
  így a befejezéskori nap várakozás nélkül ellenőrizhető. Rendszerórát nem állít át.
- Külön, rögzített Git-commit archívumban készülhet ALÁÍRATLAN release AAB-jelölt. A normál
  aláírási őr változatlan; nincs debug-aláírásos release, kulcslétrehozás vagy rejtett kész státusz.

## Változatok

| Változat | Alkalmazásazonosító | Kísérleti klub / nyolc videó / virtuális próbaóra |
| --- | --- | --- |
| Normál Android és Play AAB-jelölt | com.example.mennyiment | Nincs bekapcsolva; a korábbi REVIEW-határ megmarad |
| Kezdőlapi REVIEW | com.example.mennyiment.review | Elérhető; saját helyi Android-sandbox |

Nem történik automatikus adatátvitel a két Android-azonosító között. A meglévő
export/import a felhasználó tudatos művelete. A normál videó-jóváhagyási jelzők kikapcsoltak.
Nincs új média, kreditköltés, háttérszolgáltatás, analitika vagy jutalmazási szabály.

## Eredmények kezelése

A tényleges CI, forráscommit, hash-ek és képek az átadási jelentésben és a friss
artifactok build-info/verification állományaiban szerepelnek. Korábbi tesztszám nem új eredmény.
Az Android-emulátoros eredmény nem fizikai telefonos próba. A CI-n belül azonos kulccsal
újraépített #50 baseline nem azonos a korábban terjesztett #50 APK-val.

Részletek: [kipróbálás](kiprobalas-hu.md), [Console-jegyzet](play-console-hu.md),
[adatvédelmi tervezet](privacy-draft-hu-en.md), [áruházi szövegek](store-listing-hu-en.json),
[tulajdonosi lista](owner-checklist-hu.md), [aláíratlan AAB](ALÁÍRATLAN-AAB-HU.md).
