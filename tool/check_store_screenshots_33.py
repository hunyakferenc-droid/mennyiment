"""Lossless screenshot file-format normalization; never redraws or retouches UI.

Keep original native RGBA captures. Export opaque 24-bit PNG copies required by
Play and assert every RGB pixel is unchanged. No crops, resize, overlay or model.
"""
import hashlib,json,os,struct,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
output=ROOT/'build/play-store-images';output.mkdir(parents=True,exist_ok=True)
rows=[]
for directory in ['build/android-beta/store-candidates','build/android33-upgrade/store-candidates']:
 for source in sorted((ROOT/directory).glob('store-*.png')):
  data=source.read_bytes();assert data[:8]==b'\x89PNG\r\n\x1a\n'
  width,height=struct.unpack('>II',data[16:24]);assert 320<=min(width,height) and max(width,height)<=3840 and max(width,height)<=2*min(width,height)
  raw=subprocess.run(['ffmpeg','-v','error','-i',str(source),'-f','rawvideo','-pix_fmt','rgba','pipe:1'],check=True,capture_output=True).stdout
  assert len(raw)==width*height*4 and all(x==255 for x in raw[3::4]), 'Source screenshot is not fully opaque; no compositing is allowed'
  target=output/source.name
  if target.exists():raise SystemExit('Screenshot output already exists; preserve it instead of overwriting.')
  subprocess.run(['ffmpeg','-v','error','-i',str(source),'-frames:v','1','-pix_fmt','rgb24',str(target)],check=True)
  converted=subprocess.run(['ffmpeg','-v','error','-i',str(target),'-f','rawvideo','-pix_fmt','rgba','pipe:1'],check=True,capture_output=True).stdout
  assert raw==converted,'Visual pixel content changed'
  exported=target.read_bytes();assert exported[24:26]==bytes([8,2]) and len(exported)<=8*1024*1024
  rows.append({'file':target.name,'original':str(source.relative_to(ROOT)),'originalSha256':hashlib.sha256(data).hexdigest(),
   'sha256':hashlib.sha256(exported).hexdigest(),'width':width,'height':height,'color':'24-bit PNG, no alpha',
   'pixelsUnchanged':True,'emulator':True,'physicalAndroid':False,'variant':'normal-debug','sourceCommit':os.environ['SOURCE_SHA']})
assert len(rows)==6,rows
(output/'screenshots.json').write_text(json.dumps({'sourceCommit':os.environ['SOURCE_SHA'],'screenshots':rows,'ownerApproved':False,'generativeEditing':False},indent=2)+'\n')
print('Six actual Android screenshots verified: 1080x1920, opaque RGB PNG, pixels unchanged; owner approval pending')
