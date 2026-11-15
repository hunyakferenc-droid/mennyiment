# Menti Beta – forrásból ellenőrzött felmérés, 2026-11-15

Alap: #44 `624228aa21e774ab457084c2329e422025309173`, 2.8.0+40. #42/#43/#44 nyitott draft; távoli HEAD-ek változatlanok. Új munkafa/ág: `feature/menti-beta`, 2.9.0+41. A projekt márkaelőírása és roadmapje elolvasva. A roadmap 6.5-ös hiánylistája történeti: a működő funkciókat nem építjük újra.

## Meglévő rendszer

- 18 teljes Menti-kinézet, három család × hat szett, stabil azonosítók, eredeti PNG-k és thumbnailök. XP-küszöbökből tartós megszerzés, kiadás nélküli feloldás, régi Studio-mód megőrzése.
- 14 reakciótípus; közös eseménytervező/controller/player és egy natív dekóder tulajdonosa. A normál katalógus üres. A három REVIEW-klip kizárólag boy-festival-v1 jelölt, 540×720, kb. 5,04 s, néma H.264; jóváhagyásuk továbbra is false. Új generálás, jogi vagy karakterazonossági jóváhagyás nincs.
- Snapshothoz kötött naplóírás, teljes bejegyzésszerkesztő, keresés/szűrés, hiányzó/nem érvényes/0/tört ár megkülönböztetése, statisztikai és pénzügyi frissítés.
- Közérzetnapló, napi önellenőrzés, személyes célok, kalandok, egyszeri XP-események. Alkoholfogyasztásért nem jár XP. Üres naplóból nem következtetünk alkoholmentességre.
- Verziózott fájlos export/import, előnézet, megerősítés, snapshot- és visszaállítási tranzakcióvédelem; korábbi profilok és ismeretlen mezők megőrzése.
- Helyi SharedPreferences; nincs fiók/felhőszinkron, bizonyított titkosítás vagy új engedély. HU/EN, offline font és assets. 1176 meglévő teszt a kiinduló állapotban; ezek történeti eredmények, új futást külön rögzítünk.

## Rangsorolt valódi hiányok és javításuk

| Szint | Bizonyított probléma / rés | Intézkedés |
|---|---|---|
| P0 | A 2.8 REVIEW a normál app csomagnevét használja, lecserélheti a felületét | Csak az izolált REVIEW munkafában `com.example.mennyiment.review`, explicit eredeti MainActivity, külön címke és R ikonjelzés; APK-ellenőrző paraméterezett, normál ID/aláírás változatlan |
| P1 | A lejátszás előtti aszinkron görgetés után a Leállítás/karakterváltás/tiltás ellenére elindulhatott egy kérés | Előnézeti műveleti sorszám; leállítás, kapcsoló, választás és háttér érvényteleníti; 6 HU/EN regresszió |
| P1 | A jelöltek gomb változtatja a karaktert, de a dropdown FormField megtarthatja régi belső értékét | A formmező kulcsa a kiválasztott stabil kinézetazonosítóhoz kötött; váltás-visszatérés tesztelve |
| P1 | Nincs valódi Windows/Android CI-lefedés | Kész artifactből CMD/PowerShell 5.1 + Chrome Windows-futó; API 35 x86_64 emulátor, natív integration_test és párhuzamos telepítésellenőrzés |
| P2 | Onboarding a teljes karakter átöltöztetéséhez a régi Studióra irányít | HU/EN szöveg a teljes Menti-gyűjteményre, XP önreflexiós szerepére és nem költő feloldására pontosítva |
| P1 | Windows alapértelmezett Segoe UI nincs a webes fontcsomagban; a valódi Windows-képen hibás térközök látszanak | A már meglévő, licencelt offline Roboto explicit közös család. A Windows-regresszió a javítás előtt Segoe UI-val elbukott; Android/Linux is ellenőrzött |
| P2 | Offline indító MP4-et általános binárisként szolgál ki, nosniff mellett | Szabályos video/mp4 MIME; Windows-próba HEAD ellenőrzéssel |

## Kockázatok és ellenőrzés

A REVIEW új Android-ID-je szándékosan külön, üres helyi adattár; nem migrálja és nem olvassa a normál adatait. A külön webes ZIP továbbra is ugyanazon 127.0.0.1:7357 hoston csak olvassa a már ott tárolt választást. A kettőt nem állítjuk azonos tárolási viselkedésűnek.

Az integrációs teszt kizárólag frissen létrehozott CI-emulátoron futhat; nem clear-eli a tárat. A teszt saját szintetikus bejegyzéseket hoz létre a valódi natív plugineken át. Az Android-fájl round-trip a valódi fájlrendszert és az export/import szolgáltatást ellenőrzi; a rendszer fájlválasztó párbeszédét nem helyettesíti készülékes kézi ellenőrzésként.

Helyben nincs `/dev/kvm`, Android-emulátor bináris vagy csatlakoztatott adb-eszköz. A távoli CI-emulátor eredményét kizárólag tényleges futás alapján jelentjük. Fizikai telefon és kézi Windows-próba nincs. A végső jelentés pontos commitot és minden CI-gate eredményét külön tartalmazza.
