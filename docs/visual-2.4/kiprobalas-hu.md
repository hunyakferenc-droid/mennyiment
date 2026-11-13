# MennyiMent? 2.4.0+35 – rövid kipróbálás

## Kész Web ZIP Windowson, Python nélkül

1. A teljes ZIP-et bontsd ki egy mappába. Az INDITAS.cmd fájlt a kibontott mappából indítsd.
2. Chrome-ban mindig http://127.0.0.1:7357, ugyanabban a böngészőprofilban. A kiszolgáló ablakát hagyd nyitva. Python, Node és Flutter nem kell.
3. Az indító környezeti hibánál érthető üzenetet ad; a böngészőadatokat nem törli. Más host, port vagy profil más helyi tárolót jelenthet.

## Flutter-forrásból

A megfelelő ág teljes forrásában a tool/windows/FORRAS_INDITAS.cmd indító használható. Flutter 3.47.7 kell a PATH-ban; az első függőségletöltés internetet igényelhet. Ez felépíti a webet, majd ugyanazon a 127.0.0.1:7357 címen indít. A kész Web ZIP-hez ezt ne használd.

## Mit nézz meg?

- Kezdőlap: a saját Mentid, a korhatármódhoz igazított fő művelet és a ténylegesen vállalt következő kaland. Naplóhiány vagy olvasási hiba ne jelentsen teljesítést.
- Napló: a keresés látszik, a részletes szűrők nyithatók/csukhatók. A feltételek megmaradnak; egy címke törlése csak azt a feltételt kapcsolja ki. A hiányzó ár nem 0 Ft.
- Kalandok: a kiemelt aktuális állomásról egy gomb visszavisz a mai küldetésekre. A teljesítés továbbra is megerősítést vagy tényleges mentett adatot kíván.
- Studio: ugyanazok a karakterek és ruhák; előnézet, kategóriák, Mentés és Visszavonás. Módosított űrlapból visszalépve maradjon meg az elvetési megerősítés.
- Beállítások: Segítség és saját adatok, majd Menti-élmény. A megszokott mentés/visszaállítás elérhető.
- HU/EN, nagy rendszerbetű, billentyűzet, visszagomb és újraindítás. Külön próbaadatokkal készíts tényleges JSON-fájlt, ellenőrizd a meglétét, majd próbáld az előnézetes importot és annak megszakítását is.

## Android debug APK

A ZIP kibontása után az app-debug.apk a technikai próba. Nem Play-kiadás. Az alkalmazásazonosító változatlan: com.example.mennyiment. Adatmegőrző normál frissítéshez megfelelő verziókód és azonos elfogadott aláírási identitás is kell. A CI debug-kulcsa futásonként eltérhet; a konkrét ujjlenyomat a csomag build-info.txt fájljában és a fejlesztési jelentésben szerepel.

Aláírásütközés miatt meglévő appot ne távolíts el. Használj webes próbát vagy külön tesztkészüléket, és őrizd meg a saját fájlos mentésedet. Kiadási kulcsot ez a csomag nem készít. Fizikai telefonos, emulátoros, 16 KB-runtime- és valódi Windows-eredményt csak a jelentésben megjelölt tényleges próba bizonyít.
