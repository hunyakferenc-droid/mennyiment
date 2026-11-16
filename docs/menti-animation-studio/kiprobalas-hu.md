# Menti Animation Studio 3.0.0+42 – REVIEW

Kész web ZIP: bontsd ki külön mappába, indítsd az INDITAS.cmd fájlt, Chrome-ban nyisd meg a http://127.0.0.1:7357 címet. Python és Flutter nem szükséges. Az előző kiszolgálót Ctrl+C-vel állítsd le; a port és a böngészőprofil maradjon ugyanaz. Böngészőadatot ne törölj.

A Studio lány Mentivel indul, ha nincs mentett aktív kinézet. A karaktercsaládok sorrendje lány, semleges, fiú. Válassz családot, majd a hat kinézet egyikét. A 18×14-es leltár a jóváhagyott, elkészült de jóváhagyásra váró és hiányzó médiát külön jelzi. Jelenleg 0 jóváhagyott, 3 fiú-fesztivál jelölt és 249 hiányzó hozzárendelés van. Lány/semleges kész videó nincs; helyettük az eredeti saját PNG jelenik meg.

Mind a 14 reakció kártyája megtekinthető. Elérhető jelöltnél Lejátszás, Újraindítás és Leállítás; eredeti PNG és animáció összehasonlítása. Hiányzó videó gombja nem indít más karakterhez tartozó klipet. A rendszer mozgáscsökkentése érvényes. Gyenge készüléken kapcsold ki a videóelőnézetet: nincs aktív videódekóder. A mérések helyi inicializálási idők, nem teljes RAM- vagy készülékbenchmark.

Az Események kipróbálása kizárólag megjelenítési szimuláció: naplómentés, XP, szintlépés, karakter/kiegészítő feloldása, kihívás és bátorítás. Nem ír naplót, XP-t vagy feloldást. A hiányzó reakció PNG-re esik vissza. A normál alkalmazás kizárólag jóváhagyott médiát választhat; most 0 aktivált videó.

Android: normál com.example.mennyiment, külön REVIEW com.example.mennyiment.review. A REVIEW címe Menti Studio REVIEW, ikonja R jelzéses. Saját üres adattár; a normál mentett karaktert sem olvassa át. A debug APK-k aláírása eltérhet a korábbitól: frissítéshez egyező tanúsítvány kell. Eltérésnél őrizd meg a régi telepítést és az adatokat; ne töröld az alkalmazást. A debug nem Play-kiadás.

Forrás: Flutter 3.47.7, Git, Chrome; normál webhez tool\windows\FORRAS_INDITAS.cmd. Studio forrásbuildhez Python is kell: python tool/build_menti_alive_preview.py --studio --platform web --output C:\dev\menti-studio (üres célmappa, tiszta commitolt Git-munkafa). A kész ZIP-hez Python nem kell.
