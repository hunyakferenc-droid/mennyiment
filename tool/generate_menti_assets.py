#!/usr/bin/env python3
"""Reproducible original Menti 2.2 vector layers, thumbnails and typed catalog.
Family revision: nine independent immutable raster cores + registered vector layers.
No legacy bitmap is edited; all layers use the same 320 × 400 artboard.
Run from the repository root. SVGs are Flutter SVG compatible (no filters/fonts).
"""
import json
import base64
import math
import re
import subprocess
from pathlib import Path

ROOT = Path('assets/images/menti_2_2')
OPTIONS = []
SVG = {}
DEFS = '''<defs>
<linearGradient id="skin" x2=".8" y2="1"><stop stop-color="#ffe79a"/><stop offset=".48" stop-color="#ffbc38"/><stop offset="1" stop-color="#ec7917"/></linearGradient>
<linearGradient id="purple" x2=".8" y2="1"><stop stop-color="#bd8afa"/><stop offset=".45" stop-color="#783ac3"/><stop offset="1" stop-color="#41146d"/></linearGradient>
<linearGradient id="gold" x2="1" y2="1"><stop stop-color="#fff4b5"/><stop offset=".45" stop-color="#ffd35b"/><stop offset="1" stop-color="#c38416"/></linearGradient>
<linearGradient id="dark" x2="1" y2="1"><stop stop-color="#41434f"/><stop offset="1" stop-color="#15151f"/></linearGradient>
<radialGradient id="iris"><stop stop-color="#160d0c"/><stop offset=".6" stop-color="#663119"/><stop offset="1" stop-color="#be803f"/></radialGradient>
</defs>'''

def path(d, fill, stroke='#492d38', width=2, extra=''):
    return f'<path d="{d}" fill="{fill}" stroke="{stroke}" stroke-width="{width}" stroke-linecap="round" stroke-linejoin="round" {extra}/>'
def ellipse(cx,cy,rx,ry,fill,stroke='none',width=2):
    return f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="{fill}" stroke="{stroke}" stroke-width="{width}"/>'
def rect(x,y,w,h,r,fill,stroke='none',width=2):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{fill}" stroke="{stroke}" stroke-width="{width}"/>'
def crown(x,y,s=1):
    return f'<g transform="translate({x} {y}) scale({s})">'+path('M0 0 L8 10 L16 -5 L24 10 L32 0 L28 22 L4 22 Z','url(#gold)','#9b5d16',1.5)+''.join(ellipse(a,b,2.5,2.5,'#ffef9b') for a,b in [(0,0),(16,-5),(32,0)])+'</g>'
def star(x,y,s=1,color='#ffe09b'):
    return f'<g transform="translate({x} {y}) scale({s})">'+path('M0 -10 L3 -3 L10 0 L3 3 L0 10 L-3 3 L-10 0 L-3 -3 Z',color,'none')+'</g>'
# Fixed, generated source retained in Git. Reproduction never calls an image API.
FAMILY_MATERIALS = json.loads(Path('tool/menti_family_fits.json').read_text())
for material in FAMILY_MATERIALS.values():
    if not (ROOT/material['asset']).exists():
        raise SystemExit('Missing immutable family material: '+material['asset'])
# Thumbnails use the actual context-aware renderer; vector files retain stable paths.
# All assets share a lighting direction. These gradients use explicit SVG units.
DEFS += '''<defs>
<radialGradient id="eyeWhite" cx=".3" cy=".23" r=".85"><stop stop-color="#fffef8"/><stop offset=".55" stop-color="#fff6e2"/><stop offset=".85" stop-color="#e0c5a1"/><stop offset="1" stop-color="#9b603d"/></radialGradient>
<radialGradient id="brownEye" cx=".38" cy=".34" r=".66"><stop stop-color="#29140b"/><stop offset=".55" stop-color="#47200c"/><stop offset=".78" stop-color="#b76a24"/><stop offset=".9" stop-color="#6b3518"/><stop offset="1" stop-color="#25130f"/></radialGradient>
<linearGradient id="mouth" x1="0" y1="0" x2="0" y2="1"><stop stop-color="#190e0d"/><stop offset="1" stop-color="#6c251b"/></linearGradient>
<linearGradient id="teeth" x1="0" y1="0" x2="0" y2="1"><stop stop-color="#fffdf3"/><stop offset="1" stop-color="#d8b6a1"/></linearGradient>
<radialGradient id="lip" cx=".3" cy=".2" r=".9"><stop stop-color="#ffa7a0"/><stop offset=".6" stop-color="#eb675f"/><stop offset="1" stop-color="#9b3032"/></radialGradient>
<linearGradient id="hairShine" x1="0" y1="0" x2=".9" y2="1"><stop stop-color="#e1a575"/><stop offset=".22" stop-color="#934e2d"/><stop offset=".6" stop-color="#4a2218"/><stop offset="1" stop-color="#21131c"/></linearGradient>
<linearGradient id="cap" x1=".1" y1="0" x2=".9" y2="1"><stop stop-color="#c084f1"/><stop offset=".28" stop-color="#8e33d1"/><stop offset=".65" stop-color="#57108b"/><stop offset="1" stop-color="#280a49"/></linearGradient>
<linearGradient id="charcoal" x1=".15" y1="0" x2=".9" y2="1"><stop stop-color="#5b535b"/><stop offset=".22" stop-color="#302c37"/><stop offset=".6" stop-color="#1d1a23"/><stop offset="1" stop-color="#0d0b12"/></linearGradient>
</defs>'''

CROPS = {
 'family': (15, 5, 290, 380), 'age': (42, 74, 238, 158),
 'style': (28, 202, 264, 104), 'face': (58, 151, 204, 78),
 'eyes': (52, 92, 216, 81), 'hair': (5, 0, 310, 209),
 'headwear': (0, 0, 320, 126), 'outfit': (22, 198, 276, 110),
 'glasses': (47, 96, 226, 84), 'neck': (86, 196, 150, 66),
 'held': (4, 217, 312, 92), 'detail': (57, 132, 210, 75),
 'back': (21, 193, 280, 126), 'accent': (28, 221, 264, 92),
 'background': (0,0,320,400), 'aura': (0,0,320,400), 'reaction': (0,0,320,400),
}

def premium_outfit(id):
    category=id.removesuffix('-alt');alt=id.endswith('-alt')
    colors={'basic':'#27232e','party':'#713c89','sport':'#287361','business':'#334860','festival':'#a3596e','legendary':'#44216e','street':'#505e77','cozy':'#a87957','explorer':'#566a4b','creative':'#487985'}
    c=colors[category]
    if alt:
        c={'basic':'#352b49','party':'#9a4774','sport':'#35648c','business':'#63506b','festival':'#b17a3f','legendary':'#202940','street':'#6c4c5c','cozy':'#9d627a','explorer':'#6d603d','creative':'#b27e49'}[category]
    defs=f'<defs><linearGradient id="outfit-{id}" x1=".1" y1="0" x2="1" y2="1"><stop stop-color="{c}"/><stop offset=".45" stop-color="{c}"/><stop offset="1" stop-color="#16131f"/></linearGradient></defs>'
    fabric=f'url(#outfit-{id})';b=defs
    # Padded, squat wraparound silhouette follows the immutable Menti material core.
    if category!='basic':
        b+=path('M87 218 Q106 205 126 213 Q160 226 195 212 Q217 209 234 222 L244 263 Q239 284 221 287 L99 287 Q81 280 77 260 Z',fabric,'#201b26',1)
        b+=path('M90 272 Q159 289 231 273 L226 298 Q187 309 167 294 L159 285 L148 300 Q123 310 87 297 Z','url(#charcoal)','#2e2630',1)
    if category in ['basic','street','explorer']:
        b+=path('M87 217 L124 208 Q134 212 148 225 L135 285 Q104 290 80 276 Q72 246 87 217 Z M194 208 Q214 209 235 223 Q248 254 237 278 L185 285 L173 225 Z',fabric,'#17121f',1)
        b+=path('M125 213 L142 229 L132 281 M193 212 L179 229 L187 281','none','url(#gold)',3)
        b+=path('M91 250 L120 244 L118 256 L89 263 M201 247 L231 253','none','#807079',1.5)
        b+=path('M91 222 Q78 235 80 249 M231 224 Q242 237 240 250','none','#83747d',1)
        b+=path('M103 270 L119 266 M203 266 L222 270','none','#080710',2)
    if category=='business':
        b+=path('M129 216 Q159 230 193 216 L175 270 L150 270 Z','url(#teeth)','#938080',1)
        b+=path('M156 226 L166 226 L175 253 L163 264 L151 252 Z','url(#cap)','#44204d',1)
        b+=path('M126 214 L111 237 L137 238 L124 250 L145 279 M195 214 L210 238 L185 238 L201 252 L181 279','none','#758090',1.5)
    if category=='sport':
        b+=path('M95 225 L111 219 L113 275 M222 226 L206 220 L206 276','none','#e2dfbb',4)
        b+=rect(136,239,48,29,6,'url(#teeth)')+path('M153 246 L167 246 L158 260','none','#2c5b54',4)
    if category=='party':b+=''.join(star(x,y,s,'#f4d5a5') for x,y,s in [(113,240,.6),(205,250,.7),(149,275,.4),(184,229,.45)])+path('M104 222 Q159 253 218 222','none','#be99d7',2)
    if category=='festival':b+=path('M100 224 L119 279 M125 222 L141 283 M155 225 L161 285 M189 222 L186 284 M216 225 L205 280','none','#e6b363',4)+path('M92 266 Q160 282 232 265','none','#693867',5)
    if category=='legendary':b+=path('M93 224 L124 215 L145 274 L163 286 L180 274 L197 215 L228 225','none','url(#gold)',5)+crown(145,240,.95)+path('M99 266 L129 275 M196 275 L225 266','none','#d3abeb',2)
    if category=='cozy':
        b+=path('M124 216 Q158 239 196 216 M87 246 Q158 263 236 246 M87 273 Q159 286 231 272','none','#e4c0a5',5)
        b+=''.join(path(f'M{x} 250 L{x+7} 260 L{x} 269','none','#725649',1.5) for x in range(102,219,14))
    if category=='creative':b+=path('M125 227 L117 279 Q158 294 203 280 L193 227 Z','#d9bd91','#aa8c69',1)+rect(142,251,41,23,4,'#a98768')+path('M148 246 L142 230 M159 246 L160 224 M170 246 L181 230','none','#684e82',3)
    # Fine cloth seams and specular edge detail; no long human legs or narrow wrists.
    b+=path('M90 296 L139 300 M179 300 L224 295','none','#c9b3ad',3)
    if alt:b+=path('M85 238 L94 242 M229 240 L239 236','none','#c5a2dd',5)+rect(155,273,13,8,2,'url(#gold)')
    else:b+=crown(204,228,.48)
    return b

def _registered(folder, id, body):
    if folder == 'bases':
        # Actual anatomy lives in nine independent raster checkpoints, not tiny marks.
        patch = ''
        if id == 'girl-young':
            patch = path('M121 231 Q160 240 200 231 L205 265 Q160 276 116 265 Z','url(#charcoal)','#29212e',1)
        return f'<metadata>independent-material:{id}</metadata>'+patch
    if folder in ['families','ages']:
        source = ('bases/'+id+'-young.svg') if folder == 'families' else ('bases/neutral-'+id+'.svg')
        return SVG[source]
    if folder == 'headwear' and id == 'crown-cap':return ''
    if folder == 'outfits':return premium_outfit(id)
    if folder in ['faces','eyes','hair','headwear','outfits','styles','accessories','accents']:
        if folder == 'eyes':
            return premium_eyes(id)
        if folder == 'faces':
            return premium_face(id)
        if folder in ['outfits','styles','accents'] or (folder == 'accessories' and id in ['chain','scarf','bow','notebook','flower','spark-wand','backpack','cape']):
            transform='translate(-80 90) scale(1.5 .6)'
        elif folder == 'headwear':
            top=1 if id in ['party-hat','party-crown','beret'] else -2 if id=='headphones' else -5 if id=='hood' else -10
            transform=f'translate(-48 {top}) scale(1.3 .95)'
        else:
            transform='translate(-48 7) scale(1.3 1.05)'
        body=body.replace('url(#purple)','url(#cap)').replace('url(#dark)','url(#charcoal)')
        # Replace flat material swatches with directional, individual gradients.
        colors=sorted(set(re.findall(r'fill="(#[0-9a-fA-F]{6})"',body)))
        gradients=''
        for n,color in enumerate(colors):
            r,g,b=(int(color[i:i+2],16) for i in (1,3,5))
            def shade(f):return '#'+''.join(f'{min(255,int(v*f)):02x}' for v in (r,g,b))
            key=folder+'-'+id+'-mat'+str(n)
            gradients+=f'<linearGradient id="{key}" x1=".1" y1="0" x2=".8" y2="1"><stop stop-color="{shade(1.42)}"/><stop offset=".35" stop-color="{color}"/><stop offset="1" stop-color="{shade(.5)}"/></linearGradient>'
            body=body.replace(f'fill="{color}"',f'fill="url(#{key})"')
        if folder=='hair' and id=='girl-crop':
            body=path('M77 159 L77 76 Q76 22 159 24 Q240 23 243 79 L241 174 L219 182 L219 78 Q176 104 106 77 L105 180 L81 173 Z','url(#hairShine)')+path('M108 53 Q159 31 213 54','none','#dca77a',2)
        if folder=='hair' and id=='neutral-crop':
            body=path('M82 104 Q68 56 98 38 Q137 13 169 34 Q202 15 234 47 L237 99 L215 78 Q197 95 173 75 Q144 109 108 84 Z','url(#hairShine)')+path('M104 60 Q129 37 156 45 M173 49 Q198 35 218 59','none','#cfa172',3)
        if folder=='hair':
            body=re.sub(r'fill="url\(#[a-z0-9-]+-mat[0-9]+\)"','fill="url(#hairShine)"',body)
            body+=path('M115 50 Q135 37 153 43 M178 41 Q201 37 215 55','none','#d3986f',1.3)
        if folder=='headwear' and id=='crown-cap':
            body+=path('M114 29 Q97 43 96 67 M204 29 Q223 44 225 66','none','#bc75e8',1.2)
            body+=path('M105 83 Q166 68 229 85','none','#da9df5',1.3)
        if folder=='accessories' and id in ['chain','scarf','bow']:transform='translate(-80 108) scale(1.5 .6)'
        return f'<defs>{gradients}</defs><g transform="{transform}">{body}</g>'
    if folder=='backgrounds':
        colors={'amber':'#7c4027','violet':'#51316c','ocean':'#284f66','forest':'#2b5149','rose':'#6b3b52','midnight':'#252a4d'}
        c=colors[id]
        return f'<defs><radialGradient id="room" cx=".45" cy=".35" r=".8"><stop stop-color="{c}"/><stop offset="1" stop-color="#11101d"/></radialGradient><radialGradient id="floor"><stop stop-color="{c}" stop-opacity=".75"/><stop offset="1" stop-color="{c}" stop-opacity="0"/></radialGradient></defs>'+rect(0,0,320,400,28,'url(#room)')+ellipse(160,374,154,26,'url(#floor)')
    if folder=='auras':
        colors={'sunrise':'#ffbd5e','violet':'#b68ee7','ocean':'#70c4e0','forest':'#8bc29d','starlight':'#ffe7a1','rose':'#e99fbe'}
        c=colors[id]
        glow=''.join(ellipse(160,179,143+n*2,164+n*2,'none',c,1) for n in range(3))
        return '<g opacity=".22">'+glow+'</g>'+''.join(star(x,y,sz,c) for x,y,sz in [(25,84,.35),(294,123,.25),(284,299,.35)])
    return body

def premium_eyes(id):
    widths={'round':(31,35),'wide':(35,38),'relaxed':(32,27),'sharp':(32,29)}
    rx,ry=widths[id];b=''
    for x in [113,207]:
        y=134
        b+=ellipse(x,y+3,rx+4,ry+4,'#c37632')+ellipse(x,y,rx+2,ry+2,'#8d4c27')
        b+=ellipse(x,y,rx,ry,'url(#eyeWhite)')
        b+=ellipse(x+4,y+3,20,26 if id in ['round','wide'] else 21,'url(#brownEye)','#3a1c10',1.2)
        for n in range(30):
            a=n*math.pi/15
            b+=path(f'M{x+4+16*math.cos(a):.2f} {y+3+20*math.sin(a):.2f} L{x+4+19*math.cos(a):.2f} {y+3+23*math.sin(a):.2f}','none','#d48a40',.45)
        b+=ellipse(x+4,y+3,12,18 if id in ['round','wide'] else 14,'#110c0d')
        b+=ellipse(x-4,y-9,8,9,'#fffef5')+ellipse(x+14,y+14,3.5,4,'#fff1d3')
        b+=path(f'M{x-rx+3} {y-ry+7} Q{x} {y-ry-7} {x+rx-4} {y-ry+8}','none','#f9d9a2',1.4)
        browY=86 if id!='sharp' else 88
        b+=path(f'M{x-27} {browY} Q{x} {browY-14} {x+25} {browY+3}','none','url(#hairShine)',8)
        b+=path(f'M{x-24} {browY-2} Q{x} {browY-12} {x+18} {browY}','none','#ab713f',1)
        if id=='relaxed':b+=path(f'M{x-rx} {y-12} Q{x} {y-22} {x+rx} {y-12}','none','#b66e30',6)
        if id=='sharp':b+=path(f'M{x-rx+2} {y-ry+1} L{x+rx} {y-ry+12}','none','#a45c29',5)
    return b

def premium_face(id):
    b=ellipse(160,162,9,5,'#e68b31')+path('M152 162 Q160 168 168 161','none','#bd6a26',1.2)
    if id=='cheerful':
        b+=path('M101 174 Q159 208 220 173 Q207 225 160 223 Q119 222 101 174 Z','url(#mouth)','#ad5520',2)
        b+=path('M110 181 Q160 204 210 180 L202 192 Q161 212 118 192 Z','url(#teeth)','none')
        b+=path('M136 217 Q152 201 176 213 Q187 219 175 221 L148 222 Z','url(#lip)','none')
        b+=path('M101 173 Q96 173 94 179 M220 172 Q226 172 228 177','none','#d48632',3)
    elif id=='calm':b+=path('M114 189 Q160 214 205 189','none','#a04e23',4)+path('M119 191 Q161 212 201 191','none','#ffe4a1',1)
    elif id=='playful':
        b+=path('M111 185 Q160 214 212 178 Q205 221 171 219 Z','url(#mouth)','#b16629',1)
        b+=path('M163 204 Q194 196 188 217 Q176 234 163 220 Z','url(#lip)','#c8645d',1)
    elif id=='confident':b+=path('M112 197 Q165 205 213 180','none','#9c4b21',4)+path('M211 179 L222 182','none','#c6752b',2)
    elif id=='sleepy':b+=ellipse(160,199,15,18,'url(#mouth)','#c67930')+ellipse(160,207,9,5,'url(#lip)')
    else:b+=path('M122 200 Q162 183 201 198','none','#93451d',4)+path('M118 186 L125 181 M197 182 L204 187','none','#c67730',2)
    return b

def save(folder,id,body):
    if folder!='previews':body=_registered(folder,id,body)
    p=f'{folder}/{id}.svg'; SVG[p]=body
    target=ROOT/p;target.parent.mkdir(parents=True,exist_ok=True)
    target.write_text(f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="320" height="400" viewBox="0 0 320 400">{DEFS}{body}</svg>\n')
    return p

def add(field,id,hu,en,folder,body,level=1):
    p=save(folder,id,body)
    OPTIONS.append(dict(field=field,id=id,hu=hu,en=en,asset=p,level=level))

# Nine distinct bases, same registration points for all swappable parts.
for family in ['boy','girl','neutral']:
    for age in ['young','adult','veteran']:
        rx={'boy':76,'girl':69,'neutral':80}[family]
        ry={'young':77,'adult':81,'veteran':79}[age]
        body=ellipse(160,383,94,9,'#100e24',width=0)
        body+=path('M116 308 L112 365 Q127 375 143 365 L155 314 M166 314 L178 366 Q194 375 207 364 L204 308','url(#skin)')
        body+=path('M110 352 Q126 345 145 356 L146 379 Q105 389 84 380 Q82 368 110 352 M179 355 Q199 345 213 356 L239 372 Q244 384 181 381 Z','url(#purple)')
        body+=path('M87 375 Q114 382 145 372 L146 381 Q110 390 84 381 M181 373 Q211 379 238 372 L240 380 Q213 389 181 382','#faf5ee','#ded4e6')
        body+=path('M112 360 L136 364 M109 366 L136 370 M188 361 L213 365 M189 367 L219 371','none','#fff',3)
        body+=path('M109 209 Q83 214 74 245 L70 278 Q83 291 96 277 L111 245 M210 209 Q237 212 247 247 L251 277 Q239 291 225 277 L211 244','url(#skin)')
        body+=path('M112 203 Q160 185 208 203 L214 313 Q161 336 106 313 Z','url(#dark)')
        body+=ellipse(87,123,13,20,'url(#skin)')+ellipse(233,123,13,20,'url(#skin)')
        body+=ellipse(160,123,rx,ry,'url(#skin)','#b45b20',2)
        body+=ellipse(128,78,28,13,'#ffe7a2')
        body+=ellipse(109,143,14,7,'#f59744')+ellipse(210,143,14,7,'#f59744')
        if family=='girl': body+=ellipse(85,145,5,7,'url(#gold)')+ellipse(235,145,5,7,'url(#gold)')
        if family=='neutral': body+=path('M91 158 Q91 184 114 192 M229 158 Q229 184 206 192','none','#dc8129',3)
        if age=='adult': body+=path('M98 149 L105 153 M215 153 L222 149','none','#b96c29',2)+ellipse(160,149,6,4,'#dc8129')
        if age=='veteran': body+=path('M96 139 L105 141 M95 145 L104 146 M215 141 L224 139 M216 146 L225 145 M119 171 Q127 178 135 174 M185 174 Q193 178 201 171','none','#ac602c',2)
        save('bases',f'{family}-{age}',body)
    add('family',family,{'boy':'Fiú','girl':'Lány','neutral':'Semleges'}[family],family.title(),'families',SVG[f'bases/{family}-young.svg'])
for age,hu,en in [('young','Fiatalos','Young'),('adult','Felnőttes','Adult'),('veteran','Veterán','Veteran')]:
    add('age',age,hu,en,'ages',SVG[f'bases/neutral-{age}.svg'])

mouths={
'cheerful':path('M124 159 Q160 187 198 158 Q185 202 159 197 Q137 196 124 159','#512021')+path('M130 164 Q160 180 190 164 L185 175 Q160 187 136 175','#fff9e9','none')+ellipse(160,190,14,4,'#ed777d'),
'calm':path('M133 171 Q160 185 188 170','none','#653025',4),
'playful':path('M132 168 Q163 191 191 162 Q187 195 170 194 L167 182','#5e282b')+path('M166 181 Q186 177 183 192 Q171 207 165 191','#ef8493'),
'confident':path('M130 174 Q159 181 191 164','none','#633027',4)+path('M188 162 L196 166','none','#633027',2),
'sleepy':ellipse(161,177,10,13,'#60312a')+ellipse(162,183,6,3,'#e79682'),
'determined':path('M135 176 Q162 163 187 174','none','#633027',4)+path('M126 153 L132 149 M190 149 L197 153','none','#c56825',2)}
for id,hu,en in [('cheerful','Vidám','Cheerful'),('calm','Nyugodt','Calm'),('playful','Játékos','Playful'),('confident','Magabiztos','Confident'),('sleepy','Álmos','Sleepy'),('determined','Elszánt','Determined')]:
    add('face',id,hu,en,'faces',mouths[id])
for id,hu,en,rx,ry in [('round','Kerek','Round',26,31),('wide','Tágra nyílt','Wide',29,33),('relaxed','Laza','Relaxed',27,21),('sharp','Éles tekintet','Sharp',27,25)]:
    b=''
    for x in [125,194]:
        b+=ellipse(x,124,rx,ry,'#fff8e9','#6b3b28',2)+ellipse(x+2,127,17,ry-7,'url(#iris)','#6c3b1e')+ellipse(x+3,128,10,ry-12,'#140d11')+ellipse(x-3,117,6,7,'#fff')+ellipse(x+10,135,2.5,2.5,'#ffeecb')
        if id=='relaxed': b+=path(f'M{x-rx} 116 Q{x} 102 {x+rx} 116','none','#784126',6)
        if id=='sharp': b+=path(f'M{x-rx} 96 L{x+rx} 104','none','#583021',7)
        else:b+=path(f'M{x-23} 88 Q{x} 75 {x+20} 87','none','#583021',6)
    add('eyes',id,hu,en,'eyes',b)

hair_shapes=[
('crop','Rövid','Crop','M89 94 Q80 44 119 38 L129 27 L146 38 L164 24 L178 38 L201 29 Q238 44 232 95 L208 70 Q182 91 154 65 Q122 90 108 70 Z'),
('waves','Hullámos','Waves','M85 105 Q61 57 103 43 Q103 15 140 35 Q158 6 181 35 Q220 13 225 50 Q257 71 235 108 L219 74 Q191 85 173 61 Q149 86 131 65 Q105 96 100 102 Z'),
('curls','Göndör','Curls','M83 103 Q55 78 81 57 Q68 28 99 29 Q102 6 130 24 Q151 2 170 24 Q199 2 211 28 Q247 20 239 51 Q267 70 239 100 L217 76 Q201 91 184 75 Q165 94 147 76 Q124 98 107 76 Z'),
('braid','Fonott','Braid','M88 105 Q66 53 105 35 Q164 4 216 43 Q247 66 230 111 L216 74 Q158 60 105 78 L99 156 Q121 165 99 177 Q119 188 98 200 Q113 216 94 229 L80 216 Q65 193 78 179 Q63 157 81 147 Z'),
('bob','Bob','Bob','M81 153 L79 82 Q78 24 159 25 Q243 25 242 83 L241 164 L215 171 L215 77 Q159 101 104 76 L106 171 Z'),
('crest','Taréj','Crest','M91 98 L91 62 L117 67 L132 22 L148 38 L164 5 L181 37 L202 24 L210 66 L230 63 L230 99 L210 78 Q157 90 110 77 Z')]
for fi,family in enumerate(['boy','girl','neutral']):
    for hi,(id,hu,en,d) in enumerate(hair_shapes):
        colors=['#5c3021','#7a3e26','#392b39','#682d49','#442c31','#73503c']
        color=colors[(hi+fi*2)%len(colors)]
        b=path(d,color,'#382332',2)
        if family=='girl': b+=path('M91 86 Q61 133 83 176 L94 156 Q79 122 102 86',color)+ellipse(93,149,6,5,'#d9a2ee')
        if family=='neutral': b+=path('M96 65 L122 47 M107 72 L133 54','none','#c7a8d0',4)
        if family=='boy': b+=path('M120 53 L136 43 M155 48 L168 37','none','#bc7851',3)
        add('hair',f'{family}-{id}',hu,en,'hair',b)

hats={
'crown-cap':path('M81 81 Q73 16 154 15 Q232 12 239 78 L232 97 Q158 66 81 93 Z','url(#purple)')+path('M99 78 Q177 59 241 85 L256 100 Q189 82 101 94 Z','url(#purple)')+crown(148,33,.95)+path('M115 27 Q94 46 96 70 M204 27 Q225 41 227 66','none','#c893ef',2),
'sport-cap':path('M83 82 Q78 19 157 19 Q231 17 236 81 L234 94 L84 94 Z','#f9f2e3')+path('M157 20 L157 79 M83 80 L237 80','none','#8a57c8',3)+path('M103 79 Q187 58 253 96 L251 109 Q169 86 102 95 Z','url(#purple)'),
'beanie':path('M87 90 L89 55 Q93 17 161 15 Q222 17 231 59 L232 91 Z','#e7aa69')+rect(82,76,154,29,10,'#b86954')+rect(144,81,28,20,3,'#f7e2b3')+crown(151,86,.4),
'headphones':path('M76 116 L72 77 Q73 13 159 12 Q245 12 247 78 L243 117','none','#413342',14)+path('M77 77 Q77 22 159 21 Q238 22 243 78','none','#a16de6',7)+rect(66,87,24,55,12,'url(#purple)','#e2c38a')+rect(231,87,24,55,12,'url(#purple)','#e2c38a'),
'party-crown':path('M88 63 L88 23 L119 49 L157 8 L193 49 L230 23 L228 76 Q159 51 88 76 Z','url(#gold)')+''.join(ellipse(x,y,5,5,'#b376e8') for x,y in [(89,23),(157,8),(230,23)]),
'hood':path('M72 162 Q44 41 106 22 Q160 0 214 22 Q273 47 249 162 L228 169 L224 65 Q158 35 95 65 L94 168 Z','url(#dark)')+path('M89 158 Q68 66 102 41 M230 158 Q252 62 213 39','none','#a66bdf',6),
'none':path('M143 29 Q160 21 179 29','none','#ffcf77',3),
'party-hat':path('M102 74 L159 3 L217 76 Z','#ae71de')+path('M122 49 L192 49 M139 27 L175 27','none','#ffd66d',6)+ellipse(159,9,8,8,'url(#gold)'),
'cowboy':path('M75 76 Q88 90 102 72 L110 26 Q135 39 160 26 Q192 40 213 25 L224 73 Q239 91 251 72 Q254 108 218 99 Q159 77 102 100 Q65 112 75 76 Z','#9f704e')+path('M105 64 Q161 77 220 63','none','#5e4050',9)+crown(149,62,.6),
'beret':path('M83 66 Q51 33 102 21 Q182 -8 231 31 Q261 56 224 75 L91 84 Z','#587b66')+path('M99 75 Q157 58 220 70','none','#294d42',8)+path('M156 20 L161 9','none','#294d42',6)}
for id,hu,en in [('crown-cap','Koronás sapka','Crown cap'),('sport-cap','Sportsapka','Sport cap'),('beanie','Kötött sapka','Beanie'),('headphones','Fejhallgató','Headphones'),('party-crown','Ünnepi korona','Party crown'),('hood','Kapucni','Hood'),('none','Fejfedő nélkül','No headwear'),('party-hat','Csúcsos kalap','Party hat'),('beret','Barett','Beret'),('cowboy','Cowboykalap','Cowboy hat')]:
    add('headwear',id,hu,en,'headwear',hats[id],3 if id=='beret' else 1)

outfits=[('basic','Alap szett','Classic set','#252634'),('party','Buli','Party','#673887'),('sport','Sport','Sport','#267b69'),('business','Üzleti','Business','#29435d'),('festival','Fesztivál','Festival','#b55b67'),('legendary','Legendás','Legendary','#37215e'),('street','Utcai','Street','#66517d'),('cozy','Kuckózós','Cozy','#c78e64'),('explorer','Felfedező','Explorer','#677649'),('creative','Alkotó','Creative','#548e9b')]
for oi,(id,hu,en,color) in enumerate(outfits):
    for variant in range(2):
        option=id if variant==0 else f'{id}-alt'
        fill=color if variant==0 else ['#282d3a','#513665','#295c59','#535e72','#935c41','#262036','#46616d','#b27b88','#506c63','#b87d4d'][oi]
        b=path('M112 203 L134 194 Q160 212 186 194 L209 203 Q233 216 235 250 L219 259 L209 234 L214 307 Q160 326 106 307 L111 235 L99 258 L81 250 Q87 218 112 203 Z',fill)
        b+=path('M110 304 Q162 319 212 304 L209 345 L169 345 L160 321 L151 345 L110 345 Z','url(#dark)')
        b+=path('M109 335 L148 338 M173 338 L210 335','none','#e8d8ca',5)
        if id in ['basic','street','explorer']:
            b+=path('M135 196 L153 223 L143 302 M185 196 L167 223 L176 306','none','#ddb34c',3)+path('M133 234 L115 242 L117 259 L137 251 M185 234 L205 242 L202 260 L183 251','none','#978463',2)
        if id=='business':
            b+=path('M135 194 L160 215 L185 194 L173 261 L151 261 Z','#f7eee1')+path('M156 215 L164 215 L169 246 L160 258 L151 246 Z','url(#purple)')+path('M134 196 L126 222 L146 225 L133 239 L153 298 M186 196 L195 222 L175 225 L187 239 L169 298','none','#99a3af',2)
        if id=='sport': b+=path('M106 212 L118 204 L120 293 M202 211 L194 205 L194 293','none','#eee5b5',6)+rect(138,233,44,35,8,'#e8e5bd')+path('M155 241 L164 241 L159 260','none','#2a5f55',5)
        if id=='party': b+=path('M113 206 Q159 248 209 206','none','#bfa4de',3)+''.join(star(x,y,.4) for x,y in [(126,243),(194,260),(149,285),(187,222)])
        if id=='festival': b+=path('M116 209 L130 299 M135 214 L147 306 M159 219 L163 309 M182 213 L182 306 M201 210 L197 300','none','#e5b972',4)+path('M111 287 L207 287','none','#523a74',8)
        if id=='legendary': b+=path('M108 206 L126 197 L145 291 L161 309 L179 291 L194 196 L213 207','none','#e1b452',8)+crown(145,231,1.0)+path('M113 274 L137 281 M185 281 L207 274','none','#b68ada',3)
        if id=='cozy': b+=path('M127 200 Q158 228 192 200 M113 241 L209 241 M110 276 L212 276','none','#f2d8bc',7)+''.join(path(f'M{x} 249 L{x+6} 261 L{x} 272','none','#8b5d59',2) for x in range(119,201,12))
        if id=='creative': b+=path('M133 210 L126 289 Q159 305 193 290 L185 210 Z','#e9d7b4')+rect(143,249,38,26,4,'#b48b70')+path('M152 238 L149 219 M162 239 L163 211 M172 238 L180 219','none','#704480',4)
        if variant: b+=path('M94 238 L107 242 M214 240 L228 235','none','#c6a0dd',7)+rect(154,280,14,11,2,'url(#gold)')
        else: b+=crown(180,215,.48)
        level={'business':2,'festival':3,'legendary':5,'explorer':2,'creative':2}.get(id,1)
        add('outfit',option,hu+(' · extra' if variant else ''),en+(' · extra' if variant else ''),'outfits',b,level)

styles=[('classic','Klasszikus','Classic'),('street','Utcai','Street'),('sporty','Sportos','Sporty'),('business','Elegáns','Business'),('party','Bulis','Party'),('festival','Fesztivál','Festival'),('cozy','Meghitt','Cozy'),('legendary','Legendás','Legendary')]
for i,(id,hu,en) in enumerate(styles):
    motifs=[crown(150,266,.65),path('M130 273 L160 252 L190 273 L160 286 Z','#a27ad3'),path('M145 267 L157 274 L178 250','none','#a9e1b4',5),path('M147 270 L160 253 L173 270 L160 283 Z','url(#gold)'),star(160,270,1.5,'#e5bbf7'),path('M139 270 Q149 246 159 270 Q170 291 182 266','none','#efba7b',4),path('M145 268 Q150 255 160 267 Q171 253 177 267 Q177 276 160 287 Q145 278 145 268','#f1c9bf'),crown(143,260,1.0)]
    add('style',id,hu,en,'styles',motifs[i],{'business':2,'festival':3,'legendary':5}.get(id,1))

accessories={
'glasses': [('none','Szemüveg nélkül','No glasses',''),('round-glasses','Kerek szemüveg','Round glasses',ellipse(125,125,30,33,'none','#774bb4',4)+ellipse(194,125,30,33,'none','#774bb4',4)+path('M154 122 L164 122 M94 121 L83 116 M224 121 L235 116','none','#774bb4',4)),('sunglasses','Napszemüveg','Sunglasses',path('M90 105 L154 108 L150 137 Q124 154 99 134 Z M166 108 L229 105 L220 135 Q193 151 170 137 Z','#242339','#b38ccf',3)+path('M154 115 L166 115 M107 112 L132 139 M183 111 L208 137','none','#7d679b',3))],
'neck':[('none','Nyakdísz nélkül','No neck accessory',''),('chain','Aranylánc','Gold chain',path('M130 196 Q160 240 191 196','none','#a56c26',9)+path('M130 195 Q160 235 191 195','none','#f8d781',5)+ellipse(160,223,10,11,'url(#gold)')+crown(154,219,.4)),('scarf','Sál','Scarf',path('M124 195 Q160 210 195 194 L195 213 Q160 232 123 214 Z M176 216 L194 212 L202 258 L181 259 Z','#d58579')+path('M129 201 Q160 217 189 202','none','#ffd4a4',3)),('bow','Csokornyakkendő','Bow tie',path('M139 206 L158 215 L181 205 L181 225 L159 218 L139 226 Z','url(#purple)')+ellipse(160,216,5,5,'url(#gold)'))],
'held':[('none','Szabad kéz','Empty hands',''),('notebook','Jegyzetfüzet','Notebook',rect(56,242,34,48,5,'#5a468d','#eadca6')+path('M64 244 L64 287 M71 254 L84 254 M71 263 L84 263','none','#e6c9ef',2)),('flower','Virág','Flower',path('M245 285 L245 232','none','#5b9d67',4)+path('M245 260 Q227 242 228 263 Z','#83ba77')+''.join(ellipse(245+dx,230+dy,8,9,'#c696e1') for dx,dy in [(0,-9),(8,-3),(5,8),(-5,8),(-8,-3)])+ellipse(245,230,5,5,'#ffe197')),('spark-wand','Csillagpálca','Star wand',path('M244 280 L251 221','none','#d8bc80',5)+star(251,214,1.5))],
'detail':[('none','Arcdísz nélkül','No face detail',''),('freckles','Szeplők','Freckles',''.join(ellipse(x,y,1.5,1.5,'#a85b32') for x,y in [(107,148),(114,151),(119,146),(204,146),(210,151),(216,148)])),('star','Csillagjel','Star mark',star(218,150,.6,'#b085d7')),('moon','Holdjel','Moon mark',path('M104 141 Q88 151 106 161 Q96 149 108 146 Z','#f8dfa2'))],
'back':[('none','Hátidísz nélkül','No back accessory',''),('backpack','Hátizsák','Backpack',rect(80,208,162,78,24,'#b07950','#e5ba75',3)+path('M92 220 L92 275 M229 220 L229 275','none','#654544',5)),('cape','Köpeny','Cape',path('M117 197 L78 319 Q159 348 241 317 L205 197 Z','url(#purple)')+path('M91 309 L121 225 M229 310 L202 225','none','#bd94d7',3))]}
for field,items in accessories.items():
    for id,hu,en,b in items:
        # Even the no-accessory thumbnail has its own unobtrusive visual asset.
        if not b:b=path('M151 391 L169 391','none','#bca995',1)
        add(field,id,hu,en,'accessories',b if id!='none' else b,2 if id in ['cape','spark-wand'] else 1)
        if id=='none':
            # Separate files per slot; avoid collisions in assets and previews.
            OPTIONS[-1]['asset']=save('accessories',field+'-none',b)

palette=[('gold','Arany','Gold','#f2cc71'),('violet','Lila','Violet','#b88ae9'),('blue','Kék','Blue','#88c8ef'),('mint','Menta','Mint','#94d7b4'),('rose','Rózsa','Rose','#f0a8ba'),('orange','Narancs','Orange','#efa471')]
for id,hu,en,c in palette:
    add('accent',id,hu,en,'accents',path('M88 241 L100 245 M219 245 L232 240 M115 326 L143 330 M180 330 L205 326','none',c,5)+ellipse(160,287,3,3,c))
for i,(id,hu,en,c) in enumerate([('amber','Borostyán','Amber','#9c572d'),('violet','Lila alkony','Violet dusk','#5c3d85'),('ocean','Óceán','Ocean','#2c6981'),('forest','Erdő','Forest','#356b5b'),('rose','Rózsakert','Rose garden','#985d77'),('midnight','Éjfél','Midnight','#303553')]):
    b=f'<defs><radialGradient id="bg"><stop stop-color="{c}"/><stop offset="1" stop-color="#141828"/></radialGradient></defs>'+rect(0,0,320,400,32,'url(#bg)')
    b+=ellipse(160,191,131,148,'none',c,2)+ellipse(160,191,116,132,'none',c,1)
    if i%3==0:b+=path('M0 312 Q161 234 320 312 M0 333 Q160 270 320 333','none',c,2)
    elif i%3==1:b+=''.join(star(x,y,.3,c) for x,y in [(36,53),(279,145),(264,30),(44,263),(280,303)])
    else:b+=path('M0 337 Q79 299 160 337 Q241 374 320 337 M0 353 Q79 315 160 353 Q241 390 320 353','none',c,3)
    add('background',id,hu,en,'backgrounds',b)
for i,(id,hu,en,c) in enumerate([('sunrise','Napfény','Sunrise','#ffd174'),('violet','Lila fény','Violet glow','#b78bea'),('ocean','Hullám','Wave','#8cd4e5'),('forest','Lombok','Leaves','#99c49a'),('starlight','Csillagfény','Starlight','#ffe8b0'),('rose','Rózsafény','Rose glow','#f1b7cb')]):
    b=ellipse(160,180,112,127,'none',c,2)
    if i%3==0:b+=''.join(path(f'M{x} {y} L{x+dx} {y-15}','none',c,3) for x,y,dx in [(42,97,-7),(275,90,8),(32,189,-9),(286,190,10)])
    elif i%3==1:b+=''.join(star(x,y,s,c) for x,y,s in [(40,110,.8),(277,78,.5),(275,241,.7)])
    else:b+=path('M43 258 Q15 188 42 129 M279 260 Q308 191 279 129','none',c,4)+''.join(ellipse(x,y,6,12,c) for x,y in [(39,159),(34,202),(283,161),(288,205)])
    add('aura',id,hu,en,'auras',b)
reactions=[('proud','Büszke','Proud'),('motivating','Bátorító','Motivating'),('funny','Vicces','Funny'),('sleepy','Álmos','Sleepy'),('calming','Megnyugtató','Calming'),('celebrating','Ünneplő','Celebrating'),('focused','Fókuszált','Focused')]
for i,(id,hu,en) in enumerate(reactions):
    shapes=[crown(264,159,.6),path('M270 155 L282 169 L299 140','none','#a4dfbd',4),star(280,159,1.1,'#d7aff0')+star(264,188,.5),path('M269 141 L287 141 L270 157 L288 157 M279 173 L292 173 L280 186 L293 186','none','#b9a2dc',3),path('M269 150 Q280 139 292 150 M273 161 Q280 154 288 161','none','#a5d5bf',3),''.join(star(x,y,s) for x,y,s in [(33,69,.8),(283,71,.7),(274,174,1),(48,231,.5)]),ellipse(280,155,13,13,'none','#b6d4f0',2)+ellipse(280,155,5,5,'#b6d4f0')]
    add('reaction',id,hu,en,'reactions',shapes[i])

# Each option has a composed, dedicated image preview, not a stock icon.
def standard():
    return [SVG['backgrounds/amber.svg'],SVG['auras/sunrise.svg'], SVG['bases/boy-young.svg'], SVG['outfits/basic.svg'],SVG['styles/classic.svg'],SVG['hair/boy-crop.svg'],SVG['faces/cheerful.svg'],SVG['eyes/round.svg'],SVG['headwear/crown-cap.svg']]
for o in OPTIONS:
    if o['field']=='family':
        o['asset']='identities/'+o['id']+'-young.png'
        SVG[o['asset']]='<metadata>'+o['asset']+'</metadata>'
    if o['field']=='age':
        o['asset']='identities/boy-'+o['id']+'.png'
        SVG[o['asset']]='<metadata>'+o['asset']+'</metadata>'
    if o['field']=='headwear' and o['id']=='crown-cap':o['asset']='core/crown-cap.png'
SVG['core/crown-cap.png']=''
for opt in OPTIONS:
    layers=standard();f=opt['field'];a=opt['asset']
    idx={'background':0,'aura':1,'family':2,'age':2,'outfit':3,'style':4,'hair':5,'face':6,'eyes':7,'headwear':8}.get(f)
    if idx is not None: layers[idx]=SVG[a]
    elif f=='back':layers.insert(2,SVG[a])
    else:layers.append(SVG[a])
    if f=='style':layers[3]=SVG['outfits/'+{'classic':'basic','sporty':'sport'}.get(opt['id'],opt['id'])+'.svg']
    if f=='hair':layers.pop(8) # previews must actually show the whole hairstyle
    # Duplicate defs inside one SVG are unnecessary: each layer body references common defs.
    preview=f"{f}-{opt['id']}"
    save('previews',preview,''.join(layers[2:]))
    opt['preview']=f'previews/{preview}.svg'

# Typed Dart catalog and generated ARB labels share one source of truth.
def key(s):return ''.join(w.title() for w in s.replace('-',' ').split())
dart=["// Generated by tool/generate_menti_assets.py. Do not edit by hand.","import '../l10n/generated/app_localizations.dart';",'',
'''class MentiVisualOption {
  const MentiVisualOption(this.field, this.id, this.asset, this.preview, this.level);
  final String field;
  final String id;
  final String asset;
  final String preview;
  final int level;
  String get rewardId => '$field:$id';
  String label(AppLocalizations s) => switch ('$field:$id') {''']
for o in OPTIONS:dart.append(f"    '{o['field']}:{o['id']}' => s.avatar{key(o['field'])}{key(o['id'])},")
dart += ["    _ => id,",'  };','}', '', 'class MentiVisualCatalog {',"  static const root = 'assets/images/menti_2_2/';",'  static const previewCrops = <String, List<double>>{'+','.join("'"+k+"': ["+','.join(map(str,v))+']' for k,v in CROPS.items())+'};', '  static const options = <MentiVisualOption>[']
for o in OPTIONS:dart.append(f"    MentiVisualOption('{o['field']}', '{o['id']}', '{o['asset']}', '{o['preview']}', {o['level']}),")
dart+=['  ];', '''  static List<MentiVisualOption> forField(String field, {String? family}) =>
      options.where((o) => o.field == field && (field != 'hair' || family == null ||
          o.id.startsWith('$family-'))).toList();
  static MentiVisualOption resolve(String field, String id, {String? family}) {
    final choices = forField(field, family: family);
    return choices.firstWhere((o) => o.id == id, orElse: () => choices.first);
  }
}''']
Path('lib/menti_identity/menti_visual_catalog.dart').write_text('\n'.join(dart)+'\n')
for locale in ['hu','en']:
    p=Path(f'lib/l10n/app_{locale}.arb');data=json.loads(p.read_text())
    for o in OPTIONS:data[f"avatar{key(o['field'])}{key(o['id'])}"]=o[locale]
    p.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
Path('docs/2.2-menti-asset-catalog-hu.md').write_text('# Menti 2.2 – vektorréteg-katalógus\n\n'
  'Kilenc önálló család/kor raster anyagalap, közös sapka és regisztrált SVG-rétegek; változatlan legacy PNG-k. Közös 320×400 koordinátarendszer; '
  'tömzsi, gömbölyded Menti-arányok; 2D raster + vektor, nem valódi 3D modell. '
  'Narancs test, barna szem, lila koronás sapka és fekete/arany alapruha. '
  'A családok sziluettje, hajai és életkorrajzolata eltér. '
  'A haj teljes megjelenéséhez fejfedő nélkül érdemes előnézni.\n\n'
  'Generátor: `python3 tool/generate_menti_assets.py`. A kimenet verziókezelt, '
  'a kliens futásidőben nem generál assetet. Réteg és saját összeállított thumbnail '
  'minden opcióhoz; teljes kombinációs képkészlet nincs. 9 család/kor alapréteg.\n\n'
  '| Mező | ID | Magyar név | Szint | Réteg |\n|---|---|---|---|---|\n'+
  ''.join(f"| {o['field']} | {o['id']} | {o['hu']} | {o['level']} | `{o['asset']}` |\n" for o in OPTIONS)+
  '\nKézi grafikai ellenőrzés: mindhárom család, minden kor, fejfedő nélküli hajak, '
  'szemüveg/sál/ruha takarások, 64/160/320 px, sötét/világos környezet. '
  'További kézzel finomított illusztrációk és művészeti review később bővíthetik a készletet.\n')
print(f'{len(OPTIONS)} stable options; {len(list(ROOT.rglob("*.svg")))} SVG layers; {len(list(ROOT.rglob("*.png")))} PNG checkpoints')
