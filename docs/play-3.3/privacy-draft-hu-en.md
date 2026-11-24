# Adatkezelési tájékoztató tervezete / Privacy notice draft

**Nem jóváhagyott, nem publikált tájékoztató.** A tulajdonosi mezők nem találgatással kitöltött adatok.
Verziókör: a 3.3.0+46 auditált normál Android-változata. A webes hostot külön kell vizsgálni.

## Magyar tervezet

Adatkezelő: **[ADATKEZELŐ NEVE ÉS SZÜKSÉGES ADATAI]**.
Kapcsolat: **[JÓVÁHAGYOTT KAPCSOLAT]**. Nyilvános tájékoztató: **[JÓVÁHAGYOTT HTTPS URL]**.

A MennyiMent? helyi, önbevalláson alapuló naplózást és önreflexiót segít. A felhasználó
italnevet, mennyiséget, alkoholfokot, árat és időpontot rögzíthet; közérzet/alvás/tünetek
és szabad szövegek, célok, keretek, félretett összegek, kedvencek és napi válaszok is
lehetnek a helyi adatok között. A Menti neve, megjelenése, XP, feloldások, kalandok,
nyelv, korcsoport-mód és egyéb beállítások szintén helyben tárolódnak. A korcsoport
választása önbevallás; nem igazolóokmányon alapuló életkorhitelesítés.

Nincs alkalmazásbeli fiók, saját felhőszinkron vagy megvalósított szerveres naplófeltöltés.
Az auditált kódban/függőségekben nincs beépített reklám- vagy analitikai szolgáltatás.
E megállapítások az adott verzióra vonatkoznak; nem független biztonsági tanúsítványok.
A helyi SharedPreferences nem külön alkalmazásszintű adattitkosítás. A tárolás korlátai
miatt fontos adatokról a felhasználó készítsen a meglévő exportfelületen mentést.

A JSON-export nem titkosított. A rendszer-fájlválasztóval kiválasztott külső/felhős
fájlszolgáltatóhoz saját adatkezelési feltételek és internetigény tartozhatnak. Az
Android/OEM rendszermentése és készülékek közötti átvitele a készülék beállításaitól
függően helyi appadatokat is másolhat; ezt az app nem nevezi saját felhőszinkronnak.
Ezért nem állítjuk, hogy minden lehetséges rendszerbeállítás mellett minden másolat
kizárólag az eredeti készüléken marad.

A felhasználó a meglévő felületeken kezeli a bejegyzéseit és fájlos mentéseit. Ez a
kiadás nem hoz létre új globális adattörlést vagy szerveres törlési portált. Külső
másolatok kezelését és az érintetti megkeresések eljárását az adatkezelőnek kell
véglegesítenie. **[JÓVÁHAGYANDÓ JOGALAPOK, MEGŐRZÉSI/MEGKERESÉSI ELJÁRÁS, SZÜKSÉGES JOGI ADATOK]**.

A napló és közérzet önbevallás; hiányzó bejegyzés nem igazolt alkoholmentes nap,
hiányzó ár nem nulla. Nincs diagnózis, vezetési alkalmassági értékelés vagy biztonságos
alkoholadag-ajánlás. A kommunikáció felnőttekre irányul; a meglévő korhatárkorlátozások
megmaradnak. **[CÉLKÖZÖNSÉG ÉS JOGI FELÜLVIZSGÁLAT JÓVÁHAGYÁSA]**.

A külön REVIEW alkalmazásban a klub rekordja, teljesítési dátumai és elkülönített
virtuális próbaeredményei is helyi adatok. Mozgásérzékelés nincs; a kártyák a gombos
visszajelzést értékelik. Ezek a kísérleti funkciók a normál Play-jelöltben nem aktívak.

## English draft

Controller: **[CONTROLLER NAME AND REQUIRED DETAILS]**.
Contact: **[APPROVED CONTACT]**. Public notice: **[APPROVED HTTPS URL]**.

MennyiMent? supports a local, self-reported journal and personal reflection. Local
records may include drink names, quantities, alcohol percentage, prices and times;
wellbeing, sleep, symptoms and free text; goals, budgets, amounts set aside,
favorites and daily responses. Menti names and appearance, XP, unlocks, adventures,
language, self-declared age-group mode and other preferences are also stored locally.
The age-group choice is not identity-document-based age verification.

There is no in-app account, implemented cloud synchronization or application-operated
journal upload service. The audited version contains no integrated advertising or
analytics service. These findings apply to this version and are not an independent
security certification. SharedPreferences is not a separate application encryption
layer. Users should export important data through the existing backup interface.

JSON exports are not encrypted. A file provider selected through the system picker
may be a cloud provider with its own terms and internet requirements. Android/OEM
backup or device transfer may also copy application data according to device settings;
this is not an app-operated synchronization service. We therefore do not guarantee
that every copy remains solely on the original device under all system settings.

Users manage entries and backup files through existing interfaces. This version adds
no global data-erasure feature or server deletion portal. The controller must finalize
procedures for requests and externally stored copies. **[LEGAL BASIS, RETENTION AND
REQUEST-HANDLING PROCEDURE, AND REQUIRED LEGAL DETAILS TO BE APPROVED]**.

Journal and wellbeing records are self-reported. No entry does not prove an alcohol-free
day, and a missing price is not zero. The app provides no diagnosis, fitness-to-drive
assessment or safe alcohol-dose advice. Communication is aimed at adults and existing
age restrictions remain. **[TARGET AUDIENCE AND LEGAL REVIEW TO BE APPROVED]**.

The separate REVIEW app additionally stores local club records, completion dates and
isolated virtual-day test results. It does not sense body movements; cards evaluate
button confirmations. These experimental features are not active in the normal Play candidate.
