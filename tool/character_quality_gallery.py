"""Verify unedited Chrome images and assemble a standalone, offline gallery."""
import argparse
import hashlib
import html
import json
from pathlib import Path
import re
import struct

p = argparse.ArgumentParser()
p.add_argument('folder', type=Path)
p.add_argument('--check', action='store_true')
a = p.parse_args()
f = a.folder
stages = {}
manifest = []
for stage in ['before', 'after']:
    data = json.loads((f / stage / 'captures.json').read_text())
    assert re.fullmatch(r'[a-f0-9]{40}', data['sourceCommit'])
    assert not data['errors'] and not data['externalRequests']
    assert data['renderedConfigurations'] == len(data['captures']) * 9
    assert len({c['file'] for c in data['captures']}) == len(data['captures'])
    stages[stage] = {c['file']: c for c in data['captures']}
    assert all(len(c['profiles']) == 9 for c in data['captures'])
    for c in data['captures']:
        assert c['sourceCommit'] == data['sourceCommit'] and len(c['identities']) == 9
        raw = (f / stage / c['file']).read_bytes()
        assert raw[:8] == b'\x89PNG\r\n\x1a\n'
        assert struct.unpack('>II', raw[16:24]) == (c['width'], c['height']) == (720, 960)
        assert hashlib.sha256(raw).hexdigest() == c['sha256']
        manifest.append({'stage': stage, **c})
assert len(stages['before']) == 249, 'Incomplete baseline matrix'
assert len(stages['after']) == 778, 'Incomplete single/pair matrix'
for name, b in stages['before'].items():
    assert b['query'] == stages['after'][name]['query']
pairs = json.loads((f / 'after/pairwise.json').read_text())
assert pairs['rows'] == 529 and pairs['identities'] == 9
face_guard = json.loads((f / 'after/face-guard.json').read_text())
assert face_guard['mismatches'] == [] and face_guard['identityHeadwearPairs'] == 81
assert face_guard['protectedRegions'] == 243 and face_guard['checkedPixels'] > 0
assert face_guard['sourceCommit'] == next(iter(stages['after'].values()))['sourceCommit']
summary = {'beforeCommit': next(iter(stages['before'].values()))['sourceCommit'],
           'afterCommit': next(iter(stages['after'].values()))['sourceCommit'],
           'matchedSheets': len(stages['before']), 'afterSheets': len(stages['after']),
           'renderedBeforeConfigurations': len(stages['before']) * 9,
           'renderedAfterConfigurations': len(stages['after']) * 9,
           'distinctResolvedBeforeConfigurations': len({json.dumps(p, sort_keys=True) for c in stages['before'].values() for p in c['profiles']}),
           'distinctResolvedAfterConfigurations': len({json.dumps(p, sort_keys=True) for c in stages['after'].values() for p in c['profiles']}),
           'targetedPairwise': pairs, 'faceGuard': face_guard, 'images': manifest,
           'visualApproval': 'Rendering and pair coverage are verified; human-reviewed configuration IDs are listed separately in the handoff.'}
if a.check:
    assert json.loads((f / 'manifest.json').read_text()) == summary
else:
    (f / 'manifest.json').write_text(json.dumps(summary, ensure_ascii=False, indent=2) + '\n')
    rows = []
    for name, current in stages['after'].items():
        group = name.split('-')[0].split('.')[0]
        query = html.escape(json.dumps(current['query'], ensure_ascii=False, sort_keys=True))
        content = ''
        for stage, label in [('before', 'Előtte'), ('after', 'Utána')]:
            if name in stages[stage]:
                content += f'<figure><figcaption>{label}</figcaption><a href="{stage}/{name}"><img loading="lazy" src="{stage}/{name}" alt="{label}: {html.escape(name)}"></a></figure>'
        rows.append(f'<article data-group="{group}"><h2>{html.escape(name)}</h2><code>{query}</code><div class="pair">{content}</div></article>')
    options = ''.join(f'<option>{html.escape(g)}</option>' for g in sorted({n.split('-')[0].split('.')[0] for n in stages['after']}))
    (f / 'index.html').write_text('''<!doctype html><html lang="hu"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><link rel="icon" href="data:,"><title>Menti – karakterjavítás</title><style>body{background:#100c16;color:#f0e8f3;font:16px/1.5 system-ui;margin:20px}a{color:#ffc477}h2{font-size:18px}code{display:block;overflow-wrap:anywhere}article{border-top:1px solid #594169;margin-top:24px;padding-top:12px}figure{margin:0;max-width:var(--size,386px)}img{display:block;width:100%;height:auto}.pair{display:flex;flex-wrap:wrap;gap:16px}select,input{font:inherit;padding:12px;margin:5px;max-width:90%;background:#30213b;color:white;border:1px solid #80638e;border-radius:8px}header{max-width:1050px}</style><header><h1>Menti 2.4.1+36 – eredeti Chrome-renderképek</h1><p>A teljes galéria két ZIP-ből áll: az Előtte és Utána csomagot ugyanabba a mappába bontsd ki, majd ezt az index.html fájlt nyisd meg. Nincs külső erőforrás vagy feltöltés.</p><p>249 azonos konfigurációjú előtte–utána kilenckarakteres képpár; további 529 célzott páronkénti konfiguráció. Ezek renderelt részhalmazok, nem teljes kombinációs vagy automatikus grafikai jóváhagyás. Minden kép változtatás nélküli böngészőfelvétel, elkülönített renderharnessből, nem fizikai telefonról.</p><p>A három sor: fiú, lány, semleges; oszlopok: fiatal, felnőtt, idősebb. A normál nézet karakterenként kb. 120 px; az eredeti képre kattintva nagyíthatsz.</p><p>Alap: <code>''' + summary['beforeCommit'] + '</code>Javítás: <code>' + summary['afterCommit'] + '''</code></p><p><a href="manifest.json">Pontos konfigurációk, méretek, források és SHA-256</a> · <a href="after/pairwise.json">Páronkénti lefedés</a> · <a href="KIPROBALAS-HU.md">Magyar kézi ellenőrzőlista</a></p><label>Csoport<select id="group"><option value="">Mind</option>''' + options + '''</select></label><label>Keresés<input id="search" type="search"></label><label>Méret<select id="size"><option value="386">Normál mobilméret</option><option value="720">Nagyítva</option></select></label></header><main>''' + '\n'.join(rows) + '''</main><script>const filter=()=>{for(const a of document.querySelectorAll('article'))a.hidden=(group.value&&a.dataset.group!==group.value)||!a.textContent.toLowerCase().includes(search.value.toLowerCase())};const group=document.getElementById('group'),search=document.getElementById('search');group.onchange=filter;search.oninput=filter;document.getElementById('size').onchange=e=>document.documentElement.style.setProperty('--size',e.target.value+'px');</script></html>\n''', encoding='utf-8')
print(f"Verified {summary['matchedSheets']} matched before/after sheets, {len(manifest)} original PNGs; {summary['renderedAfterConfigurations']} after configurations. Visual review is separate.")
