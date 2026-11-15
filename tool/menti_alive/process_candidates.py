"""Reproducible, non-generative, silent review candidates. Originals stay intact.
Opaque H264 studio-card alternative: preserve the baked background, no chroma key,
no segmentation or recoloring. The manifest is NEVER a production approval.
"""
import argparse, hashlib, json, subprocess
from pathlib import Path

root=Path(__file__).resolve().parents[2]
a=argparse.ArgumentParser();a.add_argument('--sources',type=Path,required=True);args=a.parse_args()
choices={'welcome':'f4285f42-f007-4682-9e33-80596995e5ec','wink':'b67e7b8f-cb74-4293-9783-8acd0cd95102','congratulation':'19e7b417-b349-41c8-aaaf-04aea914fe4f'}
ledger=json.loads((root/'docs/menti-alive/media-inventory.json').read_text());byid={x['jobId']:x for x in ledger['items']}
out=root/'tool/menti_alive/review_assets';out.mkdir(exist_ok=True);clips=[]
for reaction,job in choices.items():
 source=args.sources/(job+'.mp4');record=byid[job]
 assert hashlib.sha256(source.read_bytes()).hexdigest()==record['sha256']
 name=f'alive-review-{reaction}-v1.mp4';target=out/name
 command=['ffmpeg','-nostdin','-v','error','-i',str(source),'-map','0:v:0','-an','-sn','-dn','-vf','scale=540:720:flags=lanczos,fps=24,setsar=1','-c:v','libx264','-profile:v','main','-level','3.1','-preset','medium','-crf','20','-pix_fmt','yuv420p','-movflags','+faststart','-map_metadata','-1','-threads','2','-y',str(target)]
 subprocess.run(command,check=True)
 probe=json.loads(subprocess.check_output(['ffprobe','-v','error','-show_streams','-show_format','-of','json',str(target)]))
 v=next(s for s in probe['streams']if s['codec_type']=='video');duration=round(float(probe['format']['duration'])*1000)
 assert not any(s['codec_type']=='audio'for s in probe['streams'])
 assert v['width']==540 and v['height']==720 and duration<=8000 and target.stat().st_size<=6*1024*1024
 clips.append({'id':'alive-review-'+reaction,'lookId':'boy-festival-v1','reaction':reaction,'asset':'assets/menti_life/clips/'+name,'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'bytes':target.stat().st_size,'durationMs':duration,'width':v['width'],'height':v['height'],'version':1,'status':'reviewRequired','previewOnly':True,'rightsVerified':False,'identityVerified':False,'backgroundApproved':False,'ownerApproved':False,'approvedBy':'','approvedAt':'','audio':False,'sourceJobId':job,'sourceSha256':record['sha256'],'backgroundTreatment':'opaque studio card; source background preserved; no segmentation','processing':'scale Lanczos 540x720; 24fps; H264 Main 3.1 CRF20 yuv420p; audio stripped; faststart'})
 record['processingStatus']='reviewCandidatePrepared';record['reviewAsset']=str(target.relative_to(root));record['processedSha256']=clips[-1]['sha256']
(out/'catalog.json').write_text(json.dumps({'version':1,'previewOnly':True,'status':'reviewRequired','clips':clips},indent=2)+'\n')
(root/'docs/menti-alive/media-inventory.json').write_text(json.dumps(ledger,ensure_ascii=False,indent=2)+'\n')
print([(c['reaction'],c['bytes'],c['sha256'])for c in clips])
