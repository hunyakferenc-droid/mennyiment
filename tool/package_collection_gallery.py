"""Package actual, source-bound synthetic screenshots and reference comparisons."""
from pathlib import Path
import hashlib, html, json, zipfile
ROOT=Path(__file__).resolve().parents[1]
SOURCE='5fbcafdffebcc34e280bb9b03ca4d4babb9a83db'
folder=ROOT/'docs/images/menti-collection'
catalog=json.loads((ROOT/'docs/collection/catalog-provenance.json').read_text())
escape=html.escape
family={'boy':'Fiú','girl':'Lány','neutral':'Semleges'}
style={'base':'alap','party':'buli','festival':'fesztivál','sport':'sport','business':'üzleti','legendary':'legendás'}
images=sorted(folder.glob('*.png'))
index={'applicationSource':SOURCE,'version':'2.6.0+38','images':[{'file':p.name,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size} for p in images], 'physicalPhone':False, 'newGraphicOwnerApproval':False}
(ROOT/'docs/collection/evidence/image-index.json').write_text(json.dumps(index,ensure_ascii=False,indent=2)+'\n')

def page(thumb_prefix,evidence_prefix):
 cards=''.join(f'<article><a href="{thumb_prefix}{Path(r["thumbnail"]).name}"><img loading="lazy" src="{thumb_prefix}{Path(r["thumbnail"]).name}" alt="{r["reference"]}: {family[r["family"]]} · {style[r["style"]]}"></a><h3>{i:02}. {r["reference"]} · {family[r["family"]]} · {style[r["style"]]}</h3><p>{"Ingyenes kezdő" if r["minXp"]==0 else "200 XP · végleges feloldás"}</p><small>{"Eredeti, változatlan RGBA" if r["procedure"].startswith("unchanged") else "Referencia alapján kivágott származtatott jelölt"}</small></article>' for i,r in enumerate(catalog,1))
 sections=[]
 for prefix,title in [('comparison-','Eredeti referencia → Flutter sötét/világos felületen'),('journey-','Új felhasználó, lány Menti, tényleges XP-feloldás'),('matrix-','320/360/390/430 px · HU/EN · 100% és 200%'),('flow-','Mentés, nagyító, főoldal, profil, kaland és fájlos visszaállítás')]:
  items=''.join(f'<figure><a href="{p.name}"><img loading="lazy" src="{p.name}" alt="{escape(p.stem)}"></a><figcaption>{escape(p.stem)}</figcaption></figure>' for p in images if p.name.startswith(prefix))
  sections.append(f'<details><summary>{title}</summary><div class="screens">{items}</div></details>')
 return f'''<!doctype html><html lang="hu"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Menti-gyűjtemény · 2.6.0+38</title><style>
 :root{{color-scheme:dark}}*{{box-sizing:border-box}}body{{margin:0;background:#100c16;color:#f7f1fa;font:16px/1.55 system-ui,Segoe UI,sans-serif}}main{{max-width:1200px;margin:auto;padding:24px}}h1{{font-size:clamp(26px,5vw,42px);line-height:1.15}}h2,summary{{color:#ffca70}}a{{color:#ffd78d}}code{{overflow-wrap:anywhere}}.grid{{display:grid;grid-template-columns:repeat(auto-fit,minmax(230px,1fr));gap:16px}}article{{background:#21182b;border:1px solid #6d507e;border-radius:18px;padding:16px}}article img{{width:100%;height:300px;object-fit:contain}}article h3{{margin:8px 0;font-size:18px}}small{{color:#d4c5db}}details{{margin:24px 0;border-top:1px solid #6d507e;padding-top:16px}}summary{{cursor:pointer;font-size:22px;font-weight:650}}.screens{{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:20px;margin-top:20px}}figure{{margin:0;padding:12px;background:#21182b;border-radius:14px}}figure img{{width:100%;height:auto;max-height:850px;object-fit:contain;object-position:top}}figcaption{{overflow-wrap:anywhere;font-size:13px;margin-top:8px}}p{{max-width:85ch}}.note{{border-left:4px solid #ffca70;padding:10px 18px;background:#21182b}}
 </style><main><h1>Menti-gyűjtemény · 2.6.0+38</h1><p>15 ingyenes kezdő és 3, 200 XP-vel végleg feloldható teljes kinézet. Az XP nem fogy el a feloldáskor. A régi Studio visszaváltható.</p><p>Alkalmazásforrás: <code>{SOURCE}</code>. Valódi Flutter-render és Chrome 157 képek, elkülönített szintetikus tesztadatokkal. A böngészős képek mobilos nézetméretek; fizikai telefonos próba nem történt.</p><p class="note">Az F/L/S besorolás és az eredeti referenciák változatlanok. Az AI-segített kivágás származtatott jelölt, nem automatikusan újra jóváhagyott grafika. A sötét/világos összehasonlító lapok ellenőrző felületek, nem választható karakterhátterek.</p><p>Ez képgaléria. A kipróbálható alkalmazás Web ZIP-je és APK-ja a <a href="https://github.com/hunyakferenc-droid/mennyiment/pull/42">#42 draft PR ellenőrzött CI-futásából</a> tölthető le. Az egyes képre kattintva teljes méretet kapsz.</p><h2>Számozott katalógus</h2><div class="grid">{cards}</div>{''.join(sections)}<h2>Ellenőrzési bizonyítékok</h2><p><a href="{evidence_prefix}complete-verification.json">10 HU/EN folyamatpróba</a> · <a href="{evidence_prefix}collection-journey-verification.json">4 új onboarding/XP-próba</a> · <a href="{evidence_prefix}collection-matrix-verification.json">16 kijelző-/szövegméret-eset, 32 kép</a> · <a href="{evidence_prefix}image-index.json">Képek SHA-256 leltára</a></p><p>Valódi Windows, Android-emulátor, fizikai Android és telefonos TalkBack még kézi ellenőrzést igényel. A teljes regresszió és a csomagok végleges forráscommitja a PR leírásában szerepel.</p></main></html>'''

(folder/'galeria.html').write_text(page('../../../assets/images/menti_complete/thumbs/','../../collection/evidence/'))
zip_path=folder/'menti-collection-gallery-5fbcafd.zip'
with zipfile.ZipFile(zip_path,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
 z.writestr('galeria.html',page('thumbs/','evidence/'))
 for p in images:z.write(p,p.name)
 for r in catalog:z.write(ROOT/r['thumbnail'],'thumbs/'+Path(r['thumbnail']).name)
 for p in sorted((ROOT/'docs/collection/evidence').glob('*.json')):z.write(p,'evidence/'+p.name)
 z.write(ROOT/'docs/collection/kiprobalas-hu.md','KIPROBALAS-HU.md')
 z.write(ROOT/'docs/collection/catalog-provenance.json','KATALOGUS-EREDET.json')
 z.writestr('LELTAR-HU.md',(ROOT/'docs/collection/kepes-leltar-hu.md').read_text().replace('../images/menti-collection/','').replace('catalog-provenance.json','KATALOGUS-EREDET.json'))
manifest={'applicationSource':SOURCE,'gallery':str(zip_path.relative_to(ROOT)),'bytes':zip_path.stat().st_size,'sha256':hashlib.sha256(zip_path.read_bytes()).hexdigest(),'screenshotsAndInspectionSheets':len(images),'catalogThumbnails':len(catalog),'containsApplicationBuild':False,'openAfterExtraction':'galeria.html'}
(ROOT/'docs/collection/gallery-package.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(manifest,ensure_ascii=False))
