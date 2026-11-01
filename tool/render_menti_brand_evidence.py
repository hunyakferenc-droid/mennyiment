#!/usr/bin/env python3
"""Actual production layer composites, NOT UI screenshots or mood mockups.
Requires Inkscape on PATH. Run from repo root after generate_menti_assets.py.
The two PNG inputs are immutable art checkpoints; no image API is called here.
"""
import hashlib
import json
import subprocess
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
ASSETS=ROOT/'assets/images/menti_2_2'
OUT=ROOT/'docs/images/menti-2.2-e'
OUT.mkdir(parents=True,exist_ok=True)
TMP=ROOT/'.dart_tool/menti-brand-evidence'
TMP.mkdir(parents=True,exist_ok=True)
NS='<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '

def svg_body(path):
    raw=path.read_text()
    return raw[raw.index('>')+1:raw.rindex('</svg>')]
def namespace(body,prefix):
    import re
    body=re.sub(r'id="([^"]+)"',lambda m:f'id="{prefix}{m[1]}"',body)
    return body.replace('url(#','url(#'+prefix)
def raster(path,x,y,w,h):return f'<image xlink:href="{path.as_posix()}" x="{x}" y="{y}" width="{w}" height="{h}" preserveAspectRatio="none"/>'
def label(x,y,text,size=15):return f'<text x="{x}" y="{y}" fill="#eee7f3" font-family="DejaVu Sans" font-size="{size}">{text}</text>'

def profile(family='boy',age='young',outfit='basic',hair=None,headwear='crown-cap',**extra):
    return dict(family=family,age=age,outfit=outfit,hair=hair or family+'-crop',headwear=headwear,**extra)
def layers(v):
    val={'family':'boy','age':'young','outfit':'basic','style':'classic','hair':'boy-crop','face':'cheerful','eyes':'round','headwear':'crown-cap','accent':'gold','background':'amber','aura':'sunrise',**v}
    paths=['backgrounds/'+val['background']+'.svg','auras/'+val['aura']+'.svg']
    if v.get('back','none')!='none':paths+=['accessories/'+v['back']+'.svg']
    paths+=['core/menti-body.png',f"bases/{val['family']}-{val['age']}.svg",'outfits/'+val['outfit']+'.svg','styles/'+val['style']+'.svg','accents/'+val['accent']+'.svg','hair/'+val['hair']+'.svg','faces/'+val['face']+'.svg','eyes/'+val['eyes']+'.svg']
    for field in ['detail','neck','headwear','glasses','held']:
        id=val.get(field,'none')
        if id!='none':paths+=[('core/crown-cap.png' if field=='headwear' and id=='crown-cap' else ('headwear/' if field=='headwear' else 'accessories/')+id+'.svg')]
    return paths

def compose(v,prefix='p'):
    parts=[]
    for i,path in enumerate(layers(v)):
        if path=='core/menti-body.png':parts.append(raster(ASSETS/path,0,0,320,400))
        elif path=='core/crown-cap.png':parts.append(raster(ASSETS/path,34,0,268,112))
        else:parts.append(namespace(svg_body(ASSETS/path),prefix+str(i)+'-'))
    return ''.join(parts)
def render(name,w,h,body):
    src=TMP/(name+'.svg');src.write_text(NS+f'width="{w}" height="{h}" viewBox="0 0 {w} {h}"><rect width="{w}" height="{h}" fill="#151220"/>'+body+'</svg>')
    subprocess.run(['inkscape',str(src),'--export-type=png','--export-filename='+str(OUT/(name+'.png'))],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)

classic=profile()
body=label(24,27,'Eredeti Menti (legacy PNG)')+label(354,27,'Elutasított 2.2 vektor')+label(684,27,'2.2-E: új réteges classic')
body+=raster(ROOT/'assets/images/menti_open.png',20,55,300,400)
body+='<g transform="translate(340 55)">'+namespace(svg_body(ROOT/'tool/menti_brand_reference/outfit-basic.svg'),'old-')+'</g>'
body+='<g transform="translate(670 55)">'+compose(classic,'classic-')+'</g>'
body+=label(24,485,'Rétegkompozitok: nem UI-képernyőfotók. A személyes művészeti jóváhagyás még szükséges.',13)
render('reference-classic-comparison',1010,510,body)

variants=[('Fiú · fiatal · classic',profile()),('Fiú · veterán · sport',profile(age='veteran',outfit='sport',style='sporty',headwear='sport-cap',face='confident')),
 ('Lány · fiatal · utcai',profile('girl',hair='girl-bob',outfit='street',style='street',headwear='crown-cap',glasses='round-glasses',background='rose')),
 ('Lány · veterán · kuckózós',profile('girl','veteran','cozy',hair='girl-braid',headwear='beanie',style='cozy',neck='scarf',background='rose')),
 ('Semleges · fiatal · fesztivál',profile('neutral',outfit='festival',hair='neutral-curls',headwear='headphones',style='festival',background='ocean')),
 ('Semleges · veterán · legendás',profile('neutral','veteran','legendary',hair='neutral-waves',headwear='party-crown',style='legendary',background='violet'))]
body='';cases=[]
for i,(name,v) in enumerate(variants):
    x=(i%3)*340;y=(i//3)*440
    body+=label(x+12,y+24,name,13)+f'<g transform="translate({x+10} {y+36})">'+compose(v,'variant'+str(i)+'-')+'</g>'
    cases.append({'name':name,'visual':v,'layers':['assets/images/menti_2_2/'+p for p in layers(v)]})
render('six-characters',1020,880,body)
# Bare material core plus actual nine family/age overlays, no clothing/face disguises.
body=''
for i,(family,age) in enumerate((f,a) for f in ['boy','girl','neutral'] for a in ['young','adult','veteran']):
    x=(i%3)*240;y=(i//3)*325
    body+=label(x+16,y+23,family+' / '+age,13)+f'<g transform="translate({x+12} {y+35}) scale(.67)">'+raster(ASSETS/'core/menti-body.png',0,0,320,400)+namespace(svg_body(ASSETS/f'bases/{family}-{age}.svg'),f'base{i}-')+'</g>'
render('nine-bases',720,975,body)
# Twelve real before/after crops. Different framing is explicit: old/new anatomy differs.
old_crops={'eyes':(80,70,170,90),'face':(105,150,110,55),'hair':(60,0,200,180),'headwear':(60,0,210,110),'outfit':(70,190,180,160),'glasses':(80,70,170,90),'aura':(0,0,320,400)}
new_crops={'eyes':(52,92,216,81),'face':(58,151,204,78),'hair':(5,0,310,209),'headwear':(0,0,320,126),'outfit':(22,198,276,110),'glasses':(47,96,226,84),'aura':(0,0,320,400)}
refs=[('eyes','round'),('eyes','wide'),('face','cheerful'),('face','calm'),('hair','boy-crop'),('hair','girl-braid'),('headwear','crown-cap'),('headwear','beanie'),('outfit','basic'),('outfit','business'),('glasses','sunglasses'),('aura','forest')]
body=''
for i,(field,id) in enumerate(refs):
    x=(i%3)*380;y=(i//3)*230
    body+=label(x+10,y+22,field+' / '+id,13)+label(x+12,y+45,'2.2 előtte',11)+label(x+197,y+45,'2.2-E utána',11)
    oldbody=svg_body(ROOT/f'tool/menti_brand_reference/{field}-{id}.svg')
    v=profile(**({'family':'girl','hair':id,'headwear':'none'} if field=='hair' and id.startswith('girl') else {field:id,**({'headwear':'none'} if field=='hair' else {})}))
    for j,(content,crop) in enumerate([(oldbody,old_crops[field]),(compose(v,f'crop{i}-'),new_crops[field])]):
        cx,cy,cw,ch=crop
        body+=f'<svg x="{x+8+j*186}" y="{y+57}" width="176" height="161" viewBox="{cx} {cy} {cw} {ch}">'+namespace(content,f'cell{i}-{j}-')+'</svg>'
render('twelve-option-crops',1140,920,body)
(ROOT/'test/fixtures/menti_brand_render_cases.json').write_text(json.dumps(cases,ensure_ascii=False,indent=2)+'\n')
manifest={}
for p in sorted((ASSETS).rglob('*')):
    if p.is_file():manifest[str(p.relative_to(ROOT))]={'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
(ROOT/'docs/2.2-menti-brand-assets.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('4 production-asset proof images; 6 exact layer contracts; asset SHA256 manifest')
