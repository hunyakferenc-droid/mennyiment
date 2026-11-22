# Mi kell még az első Play belső teszthez?

- Igazoltan megfelelő feltöltőkulcs és a Console upload-tanúsítványával ellenőrzött aláírt AAB.
  Az ALÁÍRATLAN jelölt nem ezt bizonyítja. Kulcsot/jelszót ne küldj chatbe vagy Gitbe.
- Fióktípus, létrehozási dátum, hozzáférések, személyazonosság-/eszközigazolás és App Signing-állapot.
  A repository secrets-listát a jelenlegi GitHub-integráció 403-mal megtagadta; nem állítjuk,
  hogy minden nem látható secret hiányzik. A meglévő workflow nem használ feltöltőkulcs-secretet.
- Csomagnév tulajdonosi/Console-ellenőrzése: com.example.mennyiment. Nem lett automatikusan átírva.
- Adatkezelő neve és elérhetősége, jóváhagyott nyilvános privacy weboldal, alkalmazáson belüli
  elérhetőségének véglegesítése, támogatási kapcsolat. Ezekhez nem találtunk jóváhagyott adatot.
- IARC, célközönség, alkoholutalások, esetleges egészségfunkció-nyilatkozat és aktuális App content-feladatok.
- HU/EN áruházi szöveg és valódi normál Android-képek jóváhagyása; végső áruházi ikon/feature graphic.
- Belső tesztelők listája és opt-in folyamat a Console-ban. A személyes fiók 12 tesztelő/14 napos
  zárt tesztfeltétele nem azonos a belső teszt indításával.
- Fizikai Android: telepítés, valódi billentyűzet, visszagomb, háttér/folyamatleállítás,
  mentés/visszaállítás rendszer-fájlválasztója, offline használat és megfelelő kulcsú frissítés.
- 16 KB-os tényleges runtime-próba és Android 16 készülékes vizsgálat. A statikus AAB/ELF-ellenőrzés nem ez.

A #48 és #50 eredeti CI-APK-jai azonos com.example.mennyiment.review azonosítót,
de eltérő tanúsítványt használnak. Ezekre az új build csak az adott eredeti kulccsal
aláírva lehet adatmegőrző frissítés. A tanúsítvány nem tartalmazza a visszaállítható magánkulcsot.
A CI-n belül ugyanazzal a kulccsal újraépített #50 → 3.3 útvonal külön bizonyíték;
nem jelenti a régi, eredeti APK-k kulcsainak helyreállítását vagy a jövőbeli CI-k kulcsfolytonosságát.

Nem történt main merge, Play-feltöltés, szerződéselfogadás, fizetés vagy felhasználói adattörlés.
