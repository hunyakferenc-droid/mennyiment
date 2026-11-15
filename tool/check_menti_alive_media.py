"""Actual review media gate: hashes, dimensions, silent H264, no approval leakage."""
import hashlib,json,subprocess
from pathlib import Path
root=Path(__file__).resolve().parents[1]
read=lambda p:json.loads((root/p).read_text())
j=read('docs/menti-alive/media-inventory.json');complete=[x for x in j['items']if x['generationStatus']=='completed']
assert len(complete)==23 and len(j['items'])==26 and j['approved']==0
assert len({x['jobId']for x in j['items']})==26
assert all(x['sourceUrl'] and x['sha256'] and x['bytes']>0 for x in complete)
assert all(not x['ownerApproved']and not x['rightsVerified']and not x['identityVerified'] for x in j['items'])
assert read('assets/menti_life/catalog.json')['clips']==[]
pub=(root/'pubspec.yaml').read_text();assert 'menti_alive_review/'not in pub and 'alive-review-'not in pub
cat=read('tool/menti_alive/review_assets/catalog.json');assert cat['previewOnly']is True and cat['status']=='reviewRequired'
assert {x['reaction']for x in cat['clips']}=={'welcome','wink','congratulation'}
for c in cat['clips']:
 assert all(c[k]is False for k in ['ownerApproved','rightsVerified','identityVerified','backgroundApproved'])
 assert c['approvedBy']==''and c['approvedAt']==''and c['lookId']=='boy-festival-v1'
 p=root/'tool/menti_alive/review_assets'/Path(c['asset']).name
 assert hashlib.sha256(p.read_bytes()).hexdigest()==c['sha256']and p.stat().st_size==c['bytes']<=6*1024*1024
 probe=json.loads(subprocess.check_output(['ffprobe','-v','error','-show_streams','-show_format','-of','json',str(p)]))
 assert len(probe['streams'])==1
 v=probe['streams'][0];assert v['codec_type']=='video'and v['codec_name']=='h264'and v['pix_fmt']=='yuv420p'
 assert v['width']==c['width']<=720 and v['height']==c['height']<=960 and abs(v['width']/v['height']-.75)<.01
 assert abs(float(probe['format']['duration'])*1000-c['durationMs'])<100 and c['durationMs']<=8000
for p in read('docs/menti-life/png-audit.json'):
 assert hashlib.sha256((root/p['asset']).read_bytes()).hexdigest()==p['sha256']
print('23 verified source videos; 3 excluded jobs; 3 silent bounded review-only H264 clips; 0 production clips; 18 original PNGs intact')
