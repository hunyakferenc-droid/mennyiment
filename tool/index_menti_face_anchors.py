from pathlib import Path
import numpy as np,json
from PIL import Image
from scipy import ndimage
rows=[('boy','young',130,320,[327,162,182,101],[322,231,184,86]),('boy','adult',700,285,[893,119,165,103],[890,189,160,83]),('boy','veteran',1295,300,[1466,129,196,104],[1474,194,182,87]),('girl','young',190,300,[411,150,161,105],[416,216,151,77]),('girl','adult',710,284,[920,122,163,100],[927,191,151,72]),('girl','veteran',1260,294,[1451,124,172,102],[1456,192,163,76]),('neutral','young',150,279,[331,132,180,106],[355,211,139,60]),('neutral','adult',690,270,[888,105,172,109],[905,196,135,60]),('neutral','veteran',1235,278,[1447,117,178,107],[1463,201,140,61])]
result={}
for fam,age,origin,neck,eye,mouth in rows:
 for clean in [False,True]:
  a=np.array(Image.open(f'assets/images/menti_2_2/reference/{fam}{"-hairless" if clean else ""}.png'))[:,:1942];r,g,b,alpha=[a[:,:,i].astype(float) for i in range(4)]
  yy,xx=np.mgrid[:809,:1942]
  x,y,w,h=eye;area=(xx>=x-15)&(xx<x+w+15)&(yy>=y-15)&(yy<y+h+8)
  whites=(r>185)&(g>175)&(b>155)&(alpha>100)&area
  labs,n=ndimage.label(whites);parts=[]
  for k in range(1,n+1):
   ys,xs=np.where(labs==k)
   if len(xs)>90: parts.append((len(xs),[int(xs.min()-3),int(ys.min()-3),int(xs.max()-xs.min()+7),int(ys.max()-ys.min()+7)],float(xs.mean())))
  selected=[]
  for right in [False,True]:
   candidates=[p for p in parts if (p[2]>x+w/2)==right]
   p=max(candidates,key=lambda p:p[0]);bx,by,bw,bh=p[1]
   related=[p]
   for q in candidates:
    qx,qy,qw,qh=q[1]
    overlap=max(0,min(by+bh,qy+qh)-max(by,qy))
    gap=max(0,max(bx,qx)-min(bx+bw,qx+qw))
    if overlap>=min(bh,qh)*.6 and gap<20: related.append(q)
   boxes=[p[1] for p in related];x0=min(v[0] for v in boxes);y0=min(v[1] for v in boxes)
   selected.append([x0,y0,max(v[0]+v[2] for v in boxes)-x0,max(v[1]+v[3] for v in boxes)-y0])

  mx,my,mw,mh=mouth
  area=(xx>=mx-10)&(xx<mx+mw+10)&(yy>=my)&(yy<my+mh+10)
  white=(r>185)&(g>175)&(b>150)&(alpha>100)&area
  labs,n=ndimage.label(white);teeth=[]
  centerY=sum(v[1]+v[3]/2 for v in selected)/2
  for k in range(1,n+1):
   ys,xs=np.where(labs==k)
   if len(xs)>35 and xs.max()-xs.min()>1.7*(ys.max()-ys.min()+1) and ys.mean()>centerY+14:
    teeth.append((xs.max()-xs.min(),[int(xs.min()),int(ys.min()),int(xs.max()-xs.min()+1),int(ys.max()-ys.min()+1)]))
  if teeth:
   _,(tx,ty,tw,th)=max(teeth)
   mb=[tx-5,ty-4,tw+10,int(th+max(15,tw*.28)+8)]
  else: mb=mouth
  skin=(r>140)&(g>65)&(r>g*1.1)&(g>b*1.6)&(alpha>100)&(xx>=origin)&(xx<origin+520)&(yy<neck-10)
  labs,n=ndimage.label(skin);sz=ndimage.sum(skin,labs,range(n+1));sz[0]=0;k=int(np.argmax(sz));ys,xs=np.where(labs==k)
  skull=[int(xs.min()),int(ys.min()),int(xs.max()-xs.min()+1),int(max(mb[1]+mb[3]+15,ys.max())-ys.min()+1)]
  key=f'{fam}-{age}{"-clean" if clean else ""}'
  result[key]={'leftEye':selected[0],'rightEye':selected[1],'mouth':mb,'skull':skull}
  print(key,selected,mb,skull)
Path('test/fixtures/menti_face_anchors_222.json').write_text(json.dumps(result,indent=2)+'\n')
with open('lib/menti_identity/menti_face_anchors.dart','w') as f:
 f.write("// Measured from existing source pixels by tool/index_menti_face_anchors.py.\nimport 'dart:ui';\nclass MentiFaceAnchors {\n static const values=<String,Map<String,Rect>>{\n")
 for key,data in result.items():
  f.write(f" '{key}':{{"+','.join(f"'{n}':Rect.fromLTWH({','.join(map(str,v))})" for n,v in data.items())+'},\n')
 f.write(' };\n}\n')
