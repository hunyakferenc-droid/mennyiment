"""Offline release gate: unchanged originals and explicitly approved local videos.
No remote URL fetch, approval inference, transcoding or source-image mutation.
"""
import hashlib
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def read(path):
    return json.loads((ROOT / path).read_text(encoding='utf-8'))

def need(condition, message):
    if not condition:
        raise SystemExit(message)

pngs = read('docs/menti-life/png-audit.json')
need(len(pngs) == 18 and len({p['id'] for p in pngs}) == 18, '18 unique PNGs required')
for p in pngs:
    need(hashlib.sha256((ROOT / p['asset']).read_bytes()).hexdigest() == p['sha256'],
         f"Original PNG changed: {p['id']}")
cat = read('assets/menti_life/catalog.json')
need(cat['version'] == 1, 'Unknown catalog')
ids = set()
for c in cat['clips']:
    need(c['id'] not in ids, 'Duplicate clip ID')
    ids.add(c['id'])
    need(c['lookId'] in {p['id'] for p in pngs}, 'Unknown look')
    need(re.fullmatch(r'assets/menti_life/clips/[a-zA-Z0-9_-]+\.(mp4|webm)', c['asset']), 'Local reviewed asset required')
    need(all(c.get(k) is True for k in ['rightsVerified', 'identityVerified', 'backgroundApproved']), 'Approval required')
    need(c.get('approvedBy', '').strip() and c.get('approvedAt'), 'Named dated approval required')
    data = (ROOT / c['asset']).read_bytes()
    need(len(data) == c['bytes'] <= 6*1024*1024, 'Media byte limit/mismatch')
    need(hashlib.sha256(data).hexdigest() == c['sha256'], 'Media hash mismatch')
    info = json.loads(subprocess.check_output(['ffprobe', '-v', 'error', '-show_streams', '-show_format', '-of', 'json', str(ROOT / c['asset'])]))
    videos = [s for s in info['streams'] if s['codec_type'] == 'video']
    need(len(videos) == 1 and not any(s['codec_type'] == 'audio' for s in info['streams']) and c.get('audio') is False, 'Silent single video required')
    v = videos[0]
    need(v['width'] == c['width'] <= 720 and v['height'] == c['height'] <= 960, 'Dimensions mismatch/limit')
    need(abs(v['width']/v['height']-.75) < .01, '3:4 aspect required')
    need(abs(float(info['format']['duration'])*1000-c['durationMs']) < 500 and c['durationMs'] <= 8000, 'Duration mismatch/limit')
ledger = read('docs/menti-life/media-inventory.json')
need(len({x['jobId'] for x in ledger['items']}) == 13, 'Expected inventoried 13 unique jobs')
for x in ledger['items']:
    need(x['status'] == 'reviewRequired' and x['runtimeAsset'] is None, 'Candidate must not silently become approved')
print(f"18 original PNG hashes intact; {len(cat['clips'])} approved local clips; 13 unapproved source jobs inventoried")
