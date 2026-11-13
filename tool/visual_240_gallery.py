"""Verify matched unedited screenshots and build an offline comparison gallery."""
import argparse
import hashlib
import html
import json
from pathlib import Path
import re
import struct
import subprocess

p = argparse.ArgumentParser()
p.add_argument('--folder', type=Path, default=Path(__file__).resolve().parents[1] / 'docs/images/menti-2.4-visual')
p.add_argument('--check', action='store_true')
a = p.parse_args()
f = a.folder
before = json.loads((f / 'before-captures.json').read_text())
after = json.loads((f / 'after-captures.json').read_text())
flows = json.loads((f / 'flows-verification.json').read_text())
assert re.fullmatch(r'[0-9a-f]{40}', before['sourceCommit']) and re.fullmatch(r'[0-9a-f]{40}', after['sourceCommit'])
assert before['errors'] == after['errors'] == flows['runtimeErrors'] == []
assert flows['externalRequests'] == [] and flows['sourceCommit'] == after['sourceCommit']
assert len(flows['checks']) == 40
assert len(before['captures']) == len(after['captures']) == 48
states = lambda d: {(x['locale'], x['width']): x['values'] for x in d['preferences']}
assert states(before) == states(after), 'Before/after application preferences differ'
key = lambda c: (c['screen'], c['locale'], c['width'], c['height'])
b = {key(c): c for c in before['captures']}
c = {key(c): c for c in after['captures']}
assert b.keys() == c.keys() and len(b) == 48
rows, pairs, image_files = [], [], set()
for k in b:
    pair = {'screen': k[0], 'locale': k[1], 'width': k[2], 'height': k[3]}
    for stage, capture in [('before', b[k]), ('after', c[k])]:
        file = f / capture['file']
        raw = file.read_bytes()
        assert raw[:8] == b'\x89PNG\r\n\x1a\n' and struct.unpack('>II', raw[16:24]) == (k[2], k[3])
        pair[stage] = {'file': capture['file'], 'sha256': hashlib.sha256(raw).hexdigest(), 'sourceCommit': before['sourceCommit'] if stage == 'before' else after['sourceCommit']}
        image_files.add(capture['file'])
    pairs.append(pair)
    rows.append(f'<article data-screen="{k[0]}" data-locale="{k[1]}" data-width="{k[2]}"><h2>{k[0]} · {k[1].upper()} · {k[2]} px</h2><div class="pair">' + ''.join(f'<figure><figcaption>{label}</figcaption><a href="{pair[stage]["file"]}"><img loading="lazy" src="{pair[stage]["file"]}" alt="{html.escape(label)}: {k[0]}, {k[1]}, {k[2]} px"></a></figure>' for stage, label in [('before', 'Előtte'), ('after', 'Utána')]) + '</div></article>')
for file in f.glob('flow-*.png'):
    raw = file.read_bytes()
    assert raw[:8] == b'\x89PNG\r\n\x1a\n'
    w, h = struct.unpack('>II', raw[16:24])
    assert w in (320, 360, 390, 430) and h == 844
    image_files.add(file.name)
assert len(image_files) == 152, (len(image_files), 'Expected 96 comparison and 56 actual flow images')
manifest = {'beforeCommit': before['sourceCommit'], 'afterCommit': after['sourceCommit'], 'pairs': pairs,
            'images': [{'file': n, 'sha256': hashlib.sha256((f / n).read_bytes()).hexdigest()} for n in sorted(image_files)]}
if a.check:
    assert json.loads((f / 'comparison.json').read_text()) == manifest
    root = Path(__file__).resolve().parents[1]
    if f.resolve() == (root / 'docs/images/menti-2.4-visual').resolve():
        tracked = set(subprocess.check_output(['git', 'ls-files', '--', 'docs/images/menti-2.4-visual'], cwd=root, text=True).splitlines())
        assert all('docs/images/menti-2.4-visual/' + n in tracked for n in image_files), 'An image is ignored or untracked'
else:
    (f / 'comparison.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
    options = lambda values: ''.join(f'<option value="{v}">{v}</option>' for v in values)
    (f / 'index.html').write_text('''<!doctype html><html lang="hu"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>MennyiMent? 2.4 – előtte és utána</title><style>body{font:16px/1.5 system-ui;background:#100c16;color:#f0e8f3;margin:24px}a{color:#ffc477}header{max-width:1000px}select{font:inherit;background:#30213b;color:white;border:1px solid #80638e;padding:12px;border-radius:10px;margin:4px}article{max-width:930px;border-top:1px solid #594169;margin:24px 0}h2{font-size:20px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:16px}figure{margin:0}figcaption{padding:8px}img{max-width:100%;height:auto;display:block}code{overflow-wrap:anywhere}</style><header><h1>MennyiMent? 2.4.0+35</h1><p>48 azonos méretű és ténylegesen egyező helyi adatállapotú előtte–utána képpár. Mindegyik a valódi Flutter-web alkalmazás változtatás nélkül rögzített Chrome-képe, elkülönített próbaadatokkal. Nem fizikai telefonos felvétel. A karaktergrafikák nem változtak.</p><p>Chrome: normál szöveg; a tényleges 200%-os szöveget és billentyűzetet HU/EN Flutter-widgettesztek ellenőrizték.</p><p>Alap: <code>''' + before['sourceCommit'] + '</code><br>Új alkalmazás: <code>' + after['sourceCommit'] + '</code></p><p><a href="comparison.json">Méretek és SHA-256 jegyzék</a> · <a href="flows-verification.json">40 tényleges folyamatellenőrzés</a></p><label>Képernyő <select id="screen"><option value="">Mind</option>' + options(['home', 'journal', 'missions', 'map', 'studio', 'settings']) + '</select></label><label>Nyelv <select id="locale"><option value="">Mind</option>' + options(['hu','en']) + '</select></label><label>Szélesség <select id="width"><option value="">Mind</option>' + options([320,360,390,430]) + '</select></label></header><main>' + '\n'.join(rows) + '''</main><script>for(const s of document.querySelectorAll('select'))s.onchange=()=>{for(const a of document.querySelectorAll('article'))a.hidden=['screen','locale','width'].some(k=>document.getElementById(k).value&&document.getElementById(k).value!==a.dataset[k]);};</script></html>\n''', encoding='utf-8')
print('Verified 48 equal-state image pairs, 152 original image hashes, 40 UI flows; no golden tolerance change.')
