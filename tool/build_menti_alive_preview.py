"""Build the explicit unapproved-media review variant in an isolated tracked tree.
Never edits the working pubspec, copies secrets or approves clips. REVIEW has a separate Android sandbox.
"""
import argparse,hashlib,json,os,shutil,subprocess,tarfile,tempfile
from pathlib import Path


from menti_beta_android import prepare_review_android, ensure_committed_source

root=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--platform',choices=['web','apk'],required=True);p.add_argument('--output',type=Path,required=True);p.add_argument('--studio',action='store_true',help='Build the 18-look Animation Studio');p.add_argument('--device', help='Run native REVIEW integration tests instead of producing a distributable');p.add_argument('--flutter',default='flutter');a=p.parse_args()
try:ensure_committed_source(root)
except ValueError as error:raise SystemExit(str(error))
resolved_flutter=shutil.which(a.flutter)
if resolved_flutter is None:raise SystemExit('Flutter SDK not found. Add Flutter bin to PATH or use --flutter; the ready Web ZIP needs no SDK or Python.')
a.flutter=resolved_flutter
a.output=a.output.resolve()
if a.output.exists() and any(a.output.iterdir()):raise SystemExit('Output must be empty; existing files are preserved.')
source=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
with tempfile.TemporaryDirectory(prefix='mennyiment-alive-review-')as directory:
 work=Path(directory)
 process=subprocess.Popen(['git','archive','HEAD'],cwd=root,stdout=subprocess.PIPE)
 with tarfile.open(fileobj=process.stdout,mode='r|')as archive:archive.extractall(work,filter='data')
 if process.wait()!=0:raise SystemExit('Could not archive source')
 catalog=json.loads((work/'tool/menti_alive/review_assets/catalog.json').read_text(encoding='utf-8'))
 if a.studio:
  extra=json.loads((work/'tool/menti_animation_studio/review_assets/catalog.json').read_text(encoding='utf-8'))
  assert extra['previewOnly'] is True and extra['status']=='reviewRequired'
  catalog={**catalog,'clips':catalog['clips']+extra['clips']}
 assert catalog['previewOnly'] is True and catalog['status']=='reviewRequired'
 assert json.loads((work/'assets/menti_life/catalog.json').read_text(encoding='utf-8'))['clips']==[]
 additions=[]
 for clip in catalog['clips']:
  assert all(clip[k] is False for k in ['rightsVerified','identityVerified','backgroundApproved','ownerApproved'])
  candidate=work/'tool/menti_alive/review_assets'/Path(clip['asset']).name
  if a.studio and not candidate.exists():candidate=work/'tool/menti_animation_studio/review_assets'/Path(clip['asset']).name
  assert hashlib.sha256(candidate.read_bytes()).hexdigest()==clip['sha256'] and candidate.stat().st_size==clip['bytes']
  target=work/clip['asset'];target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(candidate,target);additions.append(clip['asset'])
 target=work/'assets/menti_alive_review/catalog.json';target.parent.mkdir(parents=True);shutil.copyfile(work/'tool/menti_alive/review_assets/catalog.json',target)
 additions.append('assets/menti_alive_review/catalog.json')
 pubspec=work/'pubspec.yaml';text=pubspec.read_text(encoding='utf-8')
 # Only full-look posters and existing offline font licenses are needed here.
 # The normal application's full asset manifest remains untouched.
 review_assets=['assets/menti_life/catalog.json','assets/images/menti_complete/',
                'assets/fonts/roboto/LICENSE.txt','assets/fonts/roboto/README.md',
                'assets/fonts/menti_emoji/OFL.txt']+additions
 text=text.split('  assets:\n',1)[0]+'  assets:\n'+''.join('    - '+x+'\n'for x in review_assets)
 pubspec.write_text(text,encoding='utf-8')
 prepare_review_android(work, studio=a.studio)
 subprocess.run([a.flutter,'pub','get'],cwd=work,check=True)
 if a.device:
  if a.platform!='apk': raise SystemExit('Device integration requires apk platform')
  subprocess.run([a.flutter,'test','integration_test/menti_beta_review_test.dart','-d',a.device,'--dart-define=MENTI_ALIVE_REVIEW=true','--no-pub','--no-uninstall'],cwd=work,check=True)
  raise SystemExit(0)
 command=[a.flutter,'build',a.platform,'--target',('tool/menti_animation_studio.dart' if a.studio else 'tool/menti_alive_preview.dart'),'--dart-define=MENTI_ALIVE_REVIEW=true','--no-pub']
 command+=['--no-web-resources-cdn','--no-wasm-dry-run']if a.platform=='web'else['--debug']
 subprocess.run(command,cwd=work,check=True)
 a.output.mkdir(parents=True,exist_ok=True)
 built=work/('build/web'if a.platform=='web'else'build/app/outputs/flutter-apk')
 if a.platform=='web':
  shutil.copytree(built,a.output,dirs_exist_ok=True)
  for name in ['INDITAS.cmd','INDITAS.ps1']:shutil.copyfile(work/'tool/windows'/name,a.output/name)
 else:
  shutil.copyfile(built/'app-debug.apk',a.output/'app-debug.apk')
  (a.output/'app-debug.apk.sha256').write_text(hashlib.sha256((a.output/'app-debug.apk').read_bytes()).hexdigest()+'  app-debug.apk\n')
 shutil.copyfile(work/('docs/menti-animation-studio/kiprobalas-hu.md' if a.studio else 'docs/menti-beta/kiprobalas-hu.md'),a.output/'OLVASDEL-REVIEW.txt')
 (a.output/'build-info.txt').write_text(f'source_commit={source}\nversion=3.0.0+42\nvariant=developer-preview\napplication_id=com.example.mennyiment.review\napproved_media=0\nreview_media={len(catalog["clips"])}\nurl=http://127.0.0.1:7357\n')
print('Isolated developer preview built:',a.output)
