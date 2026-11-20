"""Read-only gate for existing girl/neutral source-matched REVIEW candidates."""
import json,hashlib,subprocess
from pathlib import Path
root=Path(__file__).resolve().parents[1]
folder=root/'tool/menti_animation_studio/review_assets'
j=json.loads((folder/'catalog.json').read_text());assert j['previewOnly'] is True and j['status']=='reviewRequired'
assert len(j['clips'])==2
assert {(c['lookId'],c['reaction']) for c in j['clips']}=={('girl-base-v1','thinking'),('neutral-base-v1','welcome')}
for c in j['clips']:
 assert all(c[k] is False for k in ['rightsVerified','identityVerified','backgroundApproved','ownerApproved'])
 assert c['approvedBy']=='' and c['approvedAt']=='' and c['audio'] is False
 assert c['sourceInputPngExactMatch'] is True
 png=root/c['sourcePng'];assert png==root/f"assets/images/menti_complete/{c['lookId'][:-3]}.png"
 assert hashlib.sha256(png.read_bytes()).hexdigest()==c['sourcePngSha256']
 p=folder/Path(c['asset']).name;assert hashlib.sha256(p.read_bytes()).hexdigest()==c['sha256'] and p.stat().st_size==c['bytes']<=6*1024*1024
 v=json.loads(subprocess.check_output(['ffprobe','-v','error','-show_streams','-show_format','-of','json',str(p)]));assert len(v['streams'])==1
 x=v['streams'][0];assert x['codec_name']=='h264' and x['pix_fmt']=='yuv420p' and (x['width'],x['height'])==(540,720)
 assert abs(float(v['format']['duration'])*1000-c['durationMs'])<100 and c['durationMs']<=8000
assert json.loads((root/'assets/menti_life/catalog.json').read_text())['clips']==[]
assert 'tool/menti_animation_studio' not in (root/'pubspec.yaml').read_text()
print('2 source-PNG hash-matched own-character Studio candidates; 5 combined REVIEW; 0 approved/production; no new generation')
