"""Reject incomplete Play evidence archives before upload; standard library only."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct
import subprocess

p = argparse.ArgumentParser()
p.add_argument('--folder', type=Path, default=Path(__file__).resolve().parents[1] / 'docs/images/menti-2.3.1-play')
a = p.parse_args()
folder = a.folder
report = json.loads((folder / 'verification.json').read_text(encoding='utf-8'))
manifest = json.loads((folder / 'image-manifest.json').read_text(encoding='utf-8'))
candidates = json.loads((folder / 'store-candidates.json').read_text(encoding='utf-8'))
source = report['sourceCommit']
assert re.fullmatch(r'[0-9a-f]{40}', source)
assert source == manifest['sourceCommit'] == candidates['sourceCommit']
assert len(report['checks']) == 34 and report['runtimeErrors'] == []
assert all(r['reloading'] or r['closing'] for r in report['failedRequests'])
assert len(manifest['images']) == 60 and len(candidates['candidates']) == 10
names = set()
for entry in manifest['images']:
    name = entry['file']
    assert name not in names and entry['sourceCommit'] == source
    names.add(name)
    file = folder / name
    if not file.is_file():
        raise SystemExit('Missing evidence image: ' + name)
    data = file.read_bytes()
    assert len(data) == entry['bytes'] and hashlib.sha256(data).hexdigest() == entry['sha256'], name
    if file.suffix == '.png':
        assert data[:8] == b'\x89PNG\r\n\x1a\n'
        width, height = struct.unpack('>II', data[16:24])
        assert width in (320, 360, 390, 430) and height == 844, name
    else:
        assert file.suffix == '.jpg' and data[:2] == b'\xff\xd8'
        # Native Chromium JPEGs use baseline SOF0; inspect, never rewrite pixels.
        at = 2
        while data[at:at + 2] != b'\xff\xc0':
            assert data[at] == 255 and data[at + 1] != 218, name
            at += 2 + struct.unpack('>H', data[at + 2:at + 4])[0]
        height, width = struct.unpack('>HH', data[at + 5:at + 9])
        assert (width, height) == (1080, 1920) and data[at + 9] == 3, name
assert len([n for n in names if n.endswith('.png')]) == 50
for c in candidates['candidates']:
    assert c['file'] in names and c['sourceCommit'] == source
    assert c['sha256'] == hashlib.sha256((folder / c['file']).read_bytes()).hexdigest()
    assert all(0 < len(c['alt'][lang]) <= 140 for lang in ('hu', 'en'))
assert (folder / 'index.html').is_file()
root = Path(__file__).resolve().parents[1]
if folder.resolve() == (root / 'docs/images/menti-2.3.1-play').resolve():
    tracked = subprocess.check_output(['git', 'ls-files', '--', 'docs/images/menti-2.3.1-play'], cwd=root, text=True)
    missing = [name for name in names if 'docs/images/menti-2.3.1-play/' + name not in tracked.splitlines()]
    if missing:
        raise SystemExit('Evidence image is not tracked by Git: ' + ', '.join(sorted(missing)))
print('Play evidence verified: all 60 image hashes, 50 mobile PNGs, 10 native 1080x1920 JPEGs, 34 checks and HU/EN alt text.')
