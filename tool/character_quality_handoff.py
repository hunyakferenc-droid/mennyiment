"""Package a small, unedited selection from the verified full Chrome evidence."""
import argparse
import hashlib
import html
import json
from pathlib import Path
import shutil
import struct

p = argparse.ArgumentParser()
p.add_argument('gallery', type=Path)
p.add_argument('before_ui', type=Path)
p.add_argument('after_ui', type=Path)
p.add_argument('output', type=Path)
p.add_argument('--guard-before', type=Path)
a = p.parse_args()
data = json.loads((a.gallery / 'manifest.json').read_text())
before = json.loads((a.before_ui / 'character-flows.json').read_text())
after = json.loads((a.after_ui / 'character-flows.json').read_text())
assert before['runtimeErrors'] == after['runtimeErrors'] == []
assert after['sourceCommit'] == data['afterCommit']
assert len(before['checks']) == 2 and len(after['checks']) == 6
a.output.mkdir(parents=True, exist_ok=True)
selected = {'headwear-party-hat.png', 'ensemble-none.png', 'ensemble-flower.png'}
selected.update('reaction-' + r + '.png' for r in ['proud', 'motivating', 'celebrating', 'funny', 'focused', 'calming', 'sleepy'])
selected.update('sunglasses-reaction-' + r + '.png' for r in ['proud', 'focused', 'calming'])
selected.update('hair-braid--headwear-' + r + '.png' for r in ['none', 'beanie', 'hood'])
images = []
rows = []
for name in sorted(selected):
    pair = []
    for stage in ['before', 'after']:
        c = next(c for c in data['images'] if c['stage'] == stage and c['file'] == name)
        src = a.gallery / stage / name
        raw = src.read_bytes()
        assert hashlib.sha256(raw).hexdigest() == c['sha256']
        dst = stage + '-' + name
        shutil.copyfile(src, a.output / dst)
        images.append({**c, 'file': dst})
        pair.append((stage, dst))
    rows.append((name, pair))
outfits = [c for c in data['images'] if c['stage'] == 'after'
           and c['file'].startswith('outfit-') and '--' not in c['file']]
assert len(outfits) == 20
for c in outfits:
    raw = (a.gallery / 'after' / c['file']).read_bytes()
    assert hashlib.sha256(raw).hexdigest() == c['sha256']
    dst = 'after-' + c['file']
    shutil.copyfile(a.gallery / 'after' / c['file'], a.output / dst)
    images.append({**c, 'file': dst})
    rows.append((c['file'] + ' · kilenc karakteres ruhatábla', [('after', dst)]))
if a.guard_before:
    old = json.loads((a.guard_before / 'after/captures.json').read_text())
    name = 'hair-braid--headwear-hood.png'
    c = next(c for c in old['captures'] if c['file'] == name)
    new = next(c for c in data['images'] if c['stage'] == 'after' and c['file'] == name)
    assert c['profiles'] == new['profiles']
    raw = (a.guard_before / 'after' / name).read_bytes()
    assert hashlib.sha256(raw).hexdigest() == c['sha256']
    dst = 'chrome157-intermediate-before-' + name
    shutil.copyfile(a.guard_before / 'after' / name, a.output / dst)
    images.append({**c, 'stage': 'intermediate-before', 'file': dst, 'note': 'Cross-browser regression found during stabilization; this was not the handed-off +35 build.'})
    rows.append(('Chrome 157 arcvédelem · köztes hibás jelölt és végleges javítás', [('before', dst), ('after', 'after-' + name)]))
for locale in ['hu', 'en']:
    for kind in ['reaction', 'zoom']:
        pair = []
        for stage, folder, metadata in [('before', a.before_ui, before), ('after', a.after_ui, after)]:
            name = f'studio-{stage}-{kind}-{locale}-390.png'
            raw = (folder / name).read_bytes()
            assert struct.unpack('>II', raw[16:24]) == (390, 844)
            shutil.copyfile(folder / name, a.output / name)
            images.append({'stage': stage, 'file': name, 'sourceCommit': metadata['sourceCommit'], 'sha256': hashlib.sha256(raw).hexdigest(), 'width': 390, 'height': 844, 'fixture': 'Mira: girl/adult/business/beanie/round-glasses/scarf/notebook; personal calm/round, draft proud; HU/EN, reduced motion'})
            pair.append((stage, name))
        rows.append((f'Studio {kind} · {locale.upper()} · 390 px', pair))
for src in sorted(a.after_ui.glob('*after-*.png')):
    if any(i['file'] == src.name for i in images):
        continue
    shutil.copyfile(src, a.output / src.name)
    images.append({'stage': 'after', 'file': src.name, 'sourceCommit': after['sourceCommit'], 'sha256': hashlib.sha256(src.read_bytes()).hexdigest()})
manifest = {'beforeCommit': data['beforeCommit'], 'afterCommit': data['afterCommit'], 'beforeUiCommit': before['sourceCommit'], 'images': images, 'note': 'Selected unedited Chrome evidence. Full gallery and actually reviewed configurations are separate. Synthetic data; no physical phone.'}
(a.output / 'comparison.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
body = ''.join('<article><h2>' + html.escape(title) + '</h2><div>' + ''.join(f'<figure><figcaption>{stage}</figcaption><a href="{name}"><img loading="lazy" src="{name}" alt="{html.escape(title)} {stage}"></a></figure>' for stage, name in pair) + '</div></article>' for title, pair in rows)
(a.output / 'index.html').write_text('''<!doctype html><html lang="hu"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><link rel="icon" href="data:,"><title>Menti – előtte és utána</title><style>body{font:16px/1.5 system-ui;background:#100c16;color:#f0e8f3;margin:20px}a{color:#ffc477}h2{font-size:20px}article{border-top:1px solid #594169;margin-top:24px}article>div{display:flex;gap:16px;flex-wrap:wrap}figure{margin:0;width:386px;max-width:100%}img{width:100%;height:auto}code{overflow-wrap:anywhere}</style><h1>Menti 2.4.1+36 – javítások képekben</h1><p>Eredeti Chrome-képek, azonos konfiguráció és méret, offline megnyitható galéria. Nem telefonos felvételek. Egy kontaktlapon kilenc eredeti karakter: sorokban fiú, lány, semleges; oszlopokban fiatal, felnőtt, idősebb. Kattints a teljes 720×960-as képre a nagyításhoz.</p><p>A hét reakció három tartós arccsoportot használ; a napszemüveg szándékosan takarja a szemet. A Studio-képpárok azonos próbaadatokkal, HU/EN nyelven készültek.</p><p>Javított forrás: <code>''' + data['afterCommit'] + '''</code></p><p><a href="comparison.json">Konfigurációk és SHA-256 jegyzék</a></p>''' + body + '</html>\n')
print('Packaged', len(images), 'original PNGs;', sum(len(pair) == 2 for _, pair in rows), 'matched pairs; 20 outfit tables')
