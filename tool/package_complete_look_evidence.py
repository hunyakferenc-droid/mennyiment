"""Package actual screenshots without editing pixels; preserve original sources."""
import argparse, hashlib, json, shutil, zipfile, re
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--input',type=Path,required=True);p.add_argument('--output',type=Path,required=True);p.add_argument('--source',required=True);a=p.parse_args();assert re.fullmatch(r'[0-9a-f]{40}',a.source)
root=Path(__file__).resolve().parents[1];source=a.source
a.output.mkdir(parents=True,exist_ok=True);shots=a.output/'screenshots';shots.mkdir(exist_ok=True)
records=[]
for f in sorted(a.input.glob('*.png')):
    if 'failure' in f.name: continue
    shutil.copyfile(f,shots/f.name)
    records.append({'file':'screenshots/'+f.name,'bytes':f.stat().st_size,'sha256':hashlib.sha256(f.read_bytes()).hexdigest()})
for family in ['fiu','lany','semleges']:
    target=a.output/'originals'/family;target.mkdir(parents=True,exist_ok=True)
    shutil.copyfile(root/'docs/images/menti-complete-looks/originals'/family/'alap.png',target/'alap.png')
for f in sorted(a.input.glob('*verification.json')):shutil.copyfile(f,a.output/f.name)
shutil.copyfile(root/'docs/complete-looks/asset-metrics.json',a.output/'asset-metrics.json')
(a.output/'manifest.json').write_text(json.dumps({'applicationSource':source,'oldApplicationSource':'3df8f66c7be59a92314694f738753ce9cc8755e7','ownerApprovedNewAppearance':False,'physicalAndroid':False,'screenshots':records},ensure_ascii=False,indent=2)+'\n')
head='''<!doctype html><html lang="hu"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><link rel="icon" href="data:,"><title>Menti – három teljes kinézet összehasonlítása</title><style>body{margin:20px;background:#17121e;color:#f2eff6;font:16px/1.5 system-ui}h1{font-size:26px}h2{font-size:22px}a{color:#ffcc7a}header{max-width:1000px}code{overflow-wrap:anywhere}.triplet{display:grid;grid-template-columns:repeat(3,minmax(0,390px));gap:16px}figure{margin:0}img{display:block;width:100%;height:auto}figcaption{min-height:70px;margin:8px 0}.matrix{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,320px));gap:16px}details{margin:20px 0}summary{cursor:pointer;font-size:20px}article{padding-top:20px;border-top:1px solid #806a93}select{font:inherit;padding:8px;background:#30253d;color:white}small{display:block}@media(max-width:700px){.triplet{grid-template-columns:1fr;max-width:390px}}</style><header><h1>Három teljes Menti-kinézet – ellenőrző képgaléria</h1><p>Ez statikus képgaléria, nem az alkalmazás. Minden kép változtatás nélküli eredeti PNG vagy tényleges Flutter-/Chrome-renderfelvétel. Nincs tulajdonosi jóváhagyás az új alkalmazásbeli látványra.</p><p>Új alkalmazás: <code>f466e530987c71c9fb3cc6d113e1deb886e97eb7</code> · 2.5.0+37. Régi alkalmazás: <code>3df8f66c7be59a92314694f738753ce9cc8755e7</code> · 2.4.1+36; a #40 dokumentációs HEAD-je 0bdb09c.</p><p>Az összehasonlítás képernyői 390×844 px méretűek. A régi mentett ruha business/beanie/scarf; az új kép teljes alapkinézet. A profil azonos tesztállapotból indul, a régi ruhát nem alakítjuk át. A referenciák saját eredeti háttere nem az új alkalmazás háttere.</p><p><a href="manifest.json">Képek és SHA-256</a> · <a href="OLVASDEL-HU.txt">Kipróbálás</a></p></header>'''
parts=[head]
for family,hu,ref in [('boy','Fiú','fiu'),('girl','Lány','lany'),('neutral','Semleges','semleges')]:
    parts.append(f'<article><h2>{hu} alap</h2><div class="triplet">')
    for file,label in [(f'reference-{ref}-390.png','1. Eredeti tulajdonosi referencia – nem alkalmazásfelvétel'),(f'before-241-{family}-hu-390.png','2. Korábbi 2.4.1 alkalmazás – eredeti régi konfiguráció'),(f'matrix-{family}-hu-390.png','3. Új 2.5.0 alkalmazás – teljes alapkinézet')]:
        parts.append(f'<figure><figcaption>{label}</figcaption><a href="screenshots/{file}"><img loading="lazy" src="screenshots/{file}" alt="{hu}: {label}"></a></figure>')
    parts.append(f'</div><p><a href="originals/{ref}/alap.png">Teljes felbontású, változatlan eredeti</a></p><details><summary>{hu} – galéria, nagyító, profil és kaland</summary><div class="matrix">')
    for prefix,label in [('gallery','Galéria'),('enlarged','Nagyobb előnézet'),('profile','Profil'),('adventure','Kalandtérkép')]:
        file=f'{prefix}-{family}-base-v1-hu-390.png';parts.append(f'<figure><figcaption>{label} · {hu}</figcaption><a href="screenshots/{file}"><img loading="lazy" src="screenshots/{file}" alt="{label} · {hu}"></a></figure>')
    parts.append('</div></details></article>')
parts.append('<article><h2>Világos és sötét ellenőrző háttér</h2><p>Tényleges Flutter-widget render, 250 px karaktervásznak, fehér és sötét ellenőrző lap. Nem új háttérválasztó; az alkalmazás mindhárom alapja közös levendula környezetet használ.</p><a href="screenshots/flutter-light-dark.png"><img style="max-width:770px" src="screenshots/flutter-light-dark.png" alt="Mindhárom minta világos és sötét ellenőrző lapon"></a></article>')
parts.append('<article><h2>Kétujjas nagyítás – Chrome érintésemuláció</h2><p>Valódi nagyítási gesztus az alkalmazás nagyítójában. Nem fizikai telefonos próba. A nagyított részlet nézetablakból való kilógása a nagyítás szándékos eredménye; a normál karakterkép teljes.</p><div class="triplet">')
for f,hu in [('boy','Fiú'),('girl','Lány'),('neutral','Semleges')]:
    file=f'zoom-after-{f}-hu-390.png';parts.append(f'<figure><figcaption>{hu} · nagyítás után</figcaption><img loading="lazy" src="screenshots/{file}" alt="{hu} valódi gesztus után"></figure>')
parts.append('</div></article><article><h2>HU/EN · 320/360/390/430 px · normál szöveg</h2><p>24 tényleges Chrome-kezdőképernyő. A 200%-os szöveg, billentyűzet és galériavezérlők külön Flutter-widget mátrixban ellenőrizve; ezek a képek normál szöveggel készültek.</p><label>Szűrés <select id="locale"><option value="">Mindkét nyelv</option><option>hu</option><option>en</option></select> <select id="width"><option value="">Minden szélesség</option><option>320</option><option>360</option><option>390</option><option>430</option></select></label><div class="matrix">')
for locale in ['hu','en']:
    for width in [320,360,390,430]:
        for family,hu in [('boy','Fiú'),('girl','Lány'),('neutral','Semleges')]:
            file=f'matrix-{family}-{locale}-{width}.png';parts.append(f'<figure data-locale="{locale}" data-width="{width}"><figcaption>{hu} · {locale.upper()} · {width} px</figcaption><a href="screenshots/{file}"><img loading="lazy" src="screenshots/{file}" alt="{hu}, {locale}, {width} px"></a></figure>')
parts.append('''</div></article><script>const locale=document.getElementById('locale'),width=document.getElementById('width');const filter=()=>{for(const e of document.querySelectorAll('[data-locale]'))e.hidden=(locale.value&&e.dataset.locale!==locale.value)||(width.value&&e.dataset.width!==width.value)};locale.onchange=filter;width.onchange=filter;</script></html>''')
(a.output/'index.html').write_text('\n'.join(parts),encoding='utf-8')
shutil.copyfile(root/'docs/complete-looks/kiprobalas-hu.md',a.output/'OLVASDEL-HU.txt')
archive=a.output.with_suffix('.zip')
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
    for f in sorted(a.output.rglob('*')):
        if f.is_file():z.write(f,f.relative_to(a.output))
with zipfile.ZipFile(archive) as z:assert z.testzip() is None
print(f'{len(records)} unchanged PNG captures packaged: {archive} ({archive.stat().st_size} bytes)')
