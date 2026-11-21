# 3.1.0+44 – megvalósítás és ellenőrzési kapuk

Alap: #48, ede0c07f4489601913d9b641f17857032f4a074c, zöld CI ellenőrizve.
Külön munkafa/ág: feature/menti-home-fitness-review; a #48 és előzményei változatlanok.

Újrahasznosított részek: közös eseménybusz, reakciótervező, egy dekóderre korlátozott
lejátszó, láthatóság/életciklus-kezelés, szigorú karakter–reakció katalógus, nyolc meglévő
H264-jelölt, normál kezdőlap, Studio és mentési útvonalak.

A külön tool/menti_home_review.dart belépési pont injektálja a REVIEW-katalógust.
Normál main.dart alapértelmezésben nem kap REVIEW-katalógust vagy klubútvonalat.
A nyolc jelölt tulajdonosi/azonossági/jogi/háttér-jóváhagyási jelzői változatlanul hamisak.
A buildelő izolált git-archívumban tartja meg a normál teljes eszközlistát, és csak ott
adja hozzá a nyolc videót. Android-ID: com.example.mennyiment.review.

A munkamenet állapota memóriában él; üdvözlés egyszer, a visszaállítás miatti
felület-újraépítéskor sem ismétlődik. Koppintás 600 ms-on belül összevonva.
A nyitott szerkesztő/napi bejelentkezés alatt keletkező események közül a meglévő
tervező szerinti legfontosabb kerül bemutatásra a visszatéréskor; tokenek ismétlése
kiszűrve. A mentési folyamatok nem változnak. Az alkoholtartalom/mennyiség nem
reakcióbemenet, a játék nem küld eseményt és semmit nem perzisztál.
A saját karakter cseréje törli a régi karakter függő eseményét és leállítja a klipet.
Hiányzó konkrét reakcióhoz nem helyettesítünk másik mozdulatot vagy másik karaktert.

A Ritmus öt köre 3,4,5,6,7 műveletet mutat; hibánál ugyanaz a sor próbálható újra.
Bemutató közben nincs játékosi értékelés; gombbal/Space/Enter léptethető, időkorlát nélkül.
A játék csak gombokat értékel, nincs kamera/szenzor/mozgáskövetés. Az eredmény
csak a játék állapotában él, visszalépés/újratöltés után elveszik.

Ellenőrzések: a friss futások eredményeit és pontos commitját az átadási jelentés
rögzíti; a korábbi 1223 teszt és 65 Chrome-próba történeti kiindulás, nem új eredmény.
A meglévő Studio/normál Chrome és natív próbák megmaradtak, melléjük új home-klub
próbák kerültek. Nincs golden-tolerancia vagy régi tartalmi állítás gyengítve.
Fizikai telefonos ellenőrzés mindaddig nyitott, amíg ténylegesen meg nem történik.
