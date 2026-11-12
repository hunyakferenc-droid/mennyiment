"""Check actual HU/EN key coverage after flutter gen-l10n (CI and local use)."""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
catalogs = {
    lang: json.loads((root / f"lib/l10n/app_{lang}.arb").read_text())
    for lang in ("hu", "en")
}
keys = {lang: {key for key in data if not key.startswith("@")}
        for lang, data in catalogs.items()}
if keys["hu"] != keys["en"]:
    raise SystemExit(f"HU/EN keys differ: {keys['hu'] ^ keys['en']}")
missing = json.loads((root / ".dart_tool/untranslated_messages.json").read_text())
if any(missing.values()):
    raise SystemExit(f"Untranslated messages: {missing}")
print(f"HU/EN: {len(keys['hu'])} matching keys; no untranslated messages")
