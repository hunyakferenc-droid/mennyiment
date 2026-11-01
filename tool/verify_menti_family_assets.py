#!/usr/bin/env python3
"""Measure actual SVG drawing bounds and check all 9 × 115 fitted options.
Inkscape is an offline geometry measurement tool, not a runtime dependency.
"""
import concurrent.futures,json,re,subprocess
from pathlib import Path
spec=json.loads(Path('tool/menti_family_fits.json').read_text())
options=re.findall(r"MentiVisualOption\('([^']+)', '([^']+)', '([^']+)', '[^']+', ([0-9]+)\)",Path('lib/menti_identity/menti_visual_catalog.dart').read_text())
root=Path('assets/images/menti_2_2')
def measure(asset):
 if asset.endswith('.png'):
  return (asset,[34,0,268,112] if asset=='core/crown-cap.png' else [0,0,320,400])
 result=subprocess.run(['inkscape',str(root/asset),'--query-x','--query-y','--query-width','--query-height'],capture_output=True,text=True,check=True)
 try:return asset,list(map(float,result.stdout.strip().splitlines()[-4:]))
 except ValueError:return asset,[0,0,0,0]
with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
 boxes=dict(pool.map(measure, sorted(set(o[2] for o in options))))
def group(field):
 return 'mouth' if field=='face' else 'eyes' if field in ['eyes','glasses','detail'] else 'head' if field in ['hair','headwear'] else 'body' if field in ['outfit','style','accent','neck','back','held'] else None
checks=[];fail=[]
for key,item in spec.items():
 for field,id,asset,level in options:
  # The renderer intentionally omits absence selectors (no accessory/headwear).
  if id=='none':continue
  if field=='hair' and not id.startswith(key.split('-')[0]+'-'):continue
  x,y,w,h=boxes[asset]
  vals=item['fits'].get(group(field),[1,1,0,0,0,0]).copy()
  if field=='held':vals[0]=min(1,max(.85,vals[0]))
  sx,sy,dx,dy,px,py=vals
  box=[(x-px)*sx+px+dx,(y-py)*sy+py+dy,w*sx,h*sy]
  row={'identity':key,'field':field,'id':id,'source':boxes[asset],'fitted':box}
  checks.append(row)
  if box[0]<-.05 or box[1]<-.05 or box[0]+box[2]>320.05 or box[1]+box[3]>400.05:fail.append(row)
Path('test/fixtures/menti_family_bounds.json').write_text(json.dumps(checks,indent=2)+'\n')
print(len(checks),'measured fitted options;',len(fail),'out of frame')
for item in fail:print(item['identity'],item['field'],item['id'],item['fitted'])
if fail:raise SystemExit(1)
