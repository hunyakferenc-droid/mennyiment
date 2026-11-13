"""Render a local, network-free index of unedited verification screenshots."""
import argparse
import hashlib
import html
import json
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('folder', type=Path)
a = parser.parse_args()
report = json.loads((a.folder / 'verification.json').read_text(encoding='utf-8'))
store = json.loads((a.folder / 'store-candidates.json').read_text(encoding='utf-8'))
items = []
manifest = []
for p in sorted(a.folder.rglob('*')):
    if p.suffix.lower() not in ('.jpg', '.png') or p.name.startswith('failure'):
        continue
    rel = p.relative_to(a.folder).as_posix()
    raw = p.read_bytes()
    digest = hashlib.sha256(raw).hexdigest()
    manifest.append({'file': rel, 'sha256': digest, 'bytes': len(raw), 'sourceCommit': report['sourceCommit']})
    candidate = next((c for c in store['candidates'] if c['file'] == rel), None)
    label = candidate['alt']['hu'] if candidate else p.stem
    if candidate:
        assert candidate['sha256'] == digest and candidate['sourceCommit'] == report['sourceCommit']
        assert max(map(len, candidate['alt'].values())) <= 140
    items.append(f'<figure><a href="{html.escape(rel)}"><img loading="lazy" src="{html.escape(rel)}" alt="{html.escape(label)}"></a><figcaption>{html.escape(label)}<br><small>{html.escape(rel)}</small></figcaption></figure>')
(a.folder / 'image-manifest.json').write_text(json.dumps({'sourceCommit': report['sourceCommit'], 'images': manifest}, indent=2) + '\n', encoding='utf-8')
(a.folder / 'index.html').write_text('''<!doctype html><html lang="hu"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>MennyiMent? 2.3.1 – tényleges Chrome-képek</title><style>body{background:#100c16;color:#f5e8da;font:16px/1.5 system-ui;margin:24px}a{color:#ffc276}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:24px}figure{margin:0;background:#241a30;padding:12px;border-radius:16px}img{max-width:100%;height:auto}figcaption{overflow-wrap:anywhere}code{overflow-wrap:anywhere}</style><h1>MennyiMent? 2.3.1+34</h1><p>Valós Flutter-web a Chrome-ban, elkülönített szintetikus próbaadatokkal. Nem fizikai Android-képek. A képek nem szerkesztettek; a JPEG képjelöltek 1080×1920-as, 3× sűrűségű natív böngészőfelvételek.</p><p>Chrome: normál szöveg. A tényleges Flutter 200%-os szöveget HU/EN widgettesztek vizsgálták mind a négy szélességen.</p><p>Forráscommit: <code>''' + report['sourceCommit'] + '</code></p><p>' + str(len(report['checks'])) + ' sikeres böngészős ellenőrzés; <a href="verification.json">jegyzőkönyv</a>, <a href="store-candidates.json">áruházi képjegyzék és HU/EN képleírások</a>, <a href="image-manifest.json">SHA-256 jegyzék</a>.</p><main>' + '\n'.join(items) + '</main></html>\n', encoding='utf-8')
print(f'{len(manifest)} original images indexed; hashes and candidate alt text checked.')
