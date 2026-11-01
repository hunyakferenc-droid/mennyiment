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
OUT=ROOT/'docs/images/menti-families'
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
    paths+=[f"identities/{val['family']}-{val['age']}.png",f"bases/{val['family']}-{val['age']}.svg",'outfits/'+val['outfit']+'.svg','styles/'+val['style']+'.svg','accents/'+val['accent']+'.svg','hair/'+val['hair']+'.svg','faces/'+val['face']+'.svg','eyes/'+val['eyes']+'.svg']
    for field in ['detail','neck','headwear','glasses','held']:
        id=val.get(field,'none')
        if id!='none':paths+=[('core/crown-cap.png' if field=='headwear' and id=='crown-cap' else ('headwear/' if field=='headwear' else 'accessories/')+id+'.svg')]
    return paths

FIT_SPEC=json.loads((ROOT/'tool/menti_family_fits.json').read_text())
def fit_for(v,path):
    key=v.get('family','boy')+'-'+v.get('age','young')
    group=None
    if path.startswith(('faces/',)):group='mouth'
    if path.startswith(('eyes/',)):group='eyes'
    if path.startswith(('hair/','headwear/')) or path=='core/crown-cap.png':group='head'
    if path.startswith(('outfits/','styles/','accents/')):group='body'
    if path.startswith('accessories/'):
        id=path.split('/')[-1].replace('.svg','')
        group='eyes' if id in ['round-glasses','sunglasses','freckles','star','moon'] else 'body'
    if group is None:return [1,1,0,0,0,0]
    fit=FIT_SPEC[key]['fits'][group].copy()
    if path.startswith('accessories/') and path.split('/')[-1].replace('.svg','') in ['notebook','flower','spark-wand']:fit[0]=min(1,max(.85,fit[0]))
    return fit
def compose(v,prefix='p'):
    parts=[]
    for i,path in enumerate(layers(v)):
        if path.startswith('identities/'):
            part=raster(ASSETS/path,0,0,320,400)
        elif path=='core/crown-cap.png':part=raster(ASSETS/path,34,0,268,112)
        else:part=namespace(svg_body(ASSETS/path),prefix+str(i)+'-')
        sx,sy,dx,dy,px,py=fit_for(v,path)
        parts.append(f'<g transform="matrix({sx} 0 0 {sy} {px*(1-sx)+dx} {py*(1-sy)+dy})">'+part+'</g>')
    return ''.join(parts)
def render(name,w,h,body):
    src=TMP/(name+'.svg');src.write_text(NS+f'width="{w}" height="{h}" viewBox="0 0 {w} {h}"><rect width="{w}" height="{h}" fill="#151220"/>'+body+'</svg>')
    subprocess.run(['inkscape',str(src),'--export-type=png','--export-filename='+str(OUT/(name+'.png'))],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)


family_names={'boy':'Fiú','girl':'Lány','neutral':'Semleges'}
age_names={'young':'Fiatalos','adult':'Felnőttes','veteran':'Veterán'}
cases=[]
for headwear,name in [('none','nine-uncovered'),('crown-cap','nine-classic')]:
    body=''
    for row,family in enumerate(['boy','girl','neutral']):
        for col,age in enumerate(['young','adult','veteran']):
            v=profile(family,age,headwear=headwear)
            x=col*340;y=row*440
            body+=label(x+12,y+24,family_names[family]+' · '+age_names[age],14)
            body+=f'<g transform="translate({x+10} {y+36})">'+compose(v,f'{name}{row}{col}-')+'</g>'
            cases.append({'name':family+'-'+age+'-'+headwear,'visual':v,'layers':['assets/images/menti_2_2/'+p for p in layers(v)]})
    render(name,1020,1320,body)
variants=[profile(),profile(age='veteran',outfit='sport',style='sporty',headwear='sport-cap',face='confident'),
 profile('girl',hair='girl-bob',outfit='street',style='street',glasses='round-glasses',background='rose'),
 profile('girl','veteran','cozy',hair='girl-braid',headwear='beanie',style='cozy',neck='scarf',background='rose'),
 profile('neutral',outfit='festival',hair='neutral-curls',headwear='headphones',style='festival',held='notebook',background='ocean'),
 profile('neutral','veteran','legendary',hair='neutral-waves',headwear='party-crown',style='legendary',back='cape',held='flower',background='violet')]
body='';legacy_cases=[]
for i,v in enumerate(variants):
    x=(i%3)*340;y=(i//3)*440
    name=family_names[v['family']]+' · '+age_names[v['age']]+' · '+v['outfit']
    body+=label(x+10,y+24,name,12)+f'<g transform="translate({x+10} {y+36})">'+compose(v,'wear'+str(i)+'-')+'</g>'
    legacy_cases.append({'name':name,'visual':v,'layers':['assets/images/menti_2_2/'+p for p in layers(v)]})
render('outfits-and-accessories',1020,880,body)
(ROOT/'test/fixtures/menti_family_render_cases.json').write_text(json.dumps(cases,ensure_ascii=False,indent=2)+'\n')
(ROOT/'test/fixtures/menti_brand_render_cases.json').write_text(json.dumps(legacy_cases,ensure_ascii=False,indent=2)+'\n')
print('Nine complete characters, nine classic characters, six equipped identities')
