# MennyiMent? – GitHub Issue → Codex terv (1. automatizálási lépcső)

Ez az első lépcső **nem ír kódot és nem készít PR-t automatikusan**. A cél az, hogy egy telefonról leadott és általad jóváhagyott Issue alapján az OpenAI Codex GitHub Action önállóan készítsen magyar, olvasható fejlesztési tervet. A terv GitHub Actions artifactként érhető el.

## Előfeltételek

1. A GitHub repository Settings → Secrets and variables → Actions alatt hozz létre **OPENAI_API_KEY** repository secretet az OpenAI API-fiókod kulcsával. A ChatGPT-előfizetés önmagában nem ugyanaz, mint az API-hozzáférés; az API-futtatás külön számlázható.
2. A repositoryban hozz létre egy **codex-approved** nevű issue-labelt. A label elnevezése pontosan ezt kövesse.
3. Ellenőrizd az Actions jogosultságokat, az OpenAI API-keretet és a GitHub Actions használati keretét.

**API-kulcsot soha ne írj issue-ba, chatbe, commitba vagy workflow-fájlba.** Csak a GitHub titkos beállításában tárold.

## Használat telefonról

1. Issues → New issue → „🚀 Új MennyiMent? fejlesztési ötlet”.
2. Írd le a kívánt működést és a megőrzendő adatokat, majd hozd létre az Issue-t.
3. **Csak átolvasás és jóváhagyás után** add hozzá a `codex-approved` labelt, a `hunyakferenc-droid` GitHub-fiókból.
4. Actions → „Codex Issue Planning (approved only)” → legutóbbi futás → Artifacts → `codex-plan-issue-N`. A 14 napig megőrzött állományban lesz a magyar terv.
5. Ha megfelelő, külön fejlesztési feladatot lehet kiadni a Codexnek, külön ággal, tesztekkel és jóváhagyott PR-rel.

## Korlátok és biztonság

- Csak az `issues:labeled` eseményre indul, akkor, ha a label pontosan `codex-approved`, és a címkézést a `hunyakferenc-droid` fiók végzi. Nem reagál minden új Issue-ra.
- `contents: read`, a checkoutban `persist-credentials: false`, Codex `:read-only` profil, `drop-sudo` biztonsági stratégia.
- A workflow a `main` ágat olvassa, és nem módosítja a tárolót. Az Issue szövege nem megbízható adat: külön fájlban, elkülönítve adjuk a modellnek.
- A generált terv hibás vagy pontatlan lehet, ezért ellenőrzés szükséges.
- Nincs automatikus hibajavítás, kódírás, PR-nyitás, merge vagy deploy. Ezek egy későbbi, külön jóváhagyott, izolált írási folyamat részei lehetnek.
- A workflow nem futtatható addig sikeresen, amíg nincs beállítva az API-kulcs és a label.
- A bevezetés előtt a teljes workflow kódját és biztonságát ellenőrizni kell.
