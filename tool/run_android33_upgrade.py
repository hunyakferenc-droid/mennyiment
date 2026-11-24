"""Pinned-source #50 -> current same-key upgrade, never an uninstall or downgrade.

Historical distributed #48/#50 keys are not fabricated or recovered. The pinned
#50 product is rebuilt using this run's ordinary debug key, exactly as reported.
"""
import hashlib,json,os,shutil,subprocess,sys,tarfile,tempfile,time
from pathlib import Path
from android33_device_ui import adb,require_emulator,prefs,lifecycle,store_screens,DeviceUI
from check_android_update import inspect,decision
from menti_beta_android import ensure_committed_source
ROOT=Path(__file__).resolve().parents[1]
BASE='e75e1ed6e2b852600e9833453931dd2d23ed45e4'
REVIEW='com.example.mennyiment.review'

def run(args,cwd=ROOT):subprocess.run(list(map(str,args)),cwd=cwd,check=True)
def main():
 require_emulator();ensure_committed_source(ROOT)
 source=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
 assert source==os.environ['SOURCE_SHA']
 out=ROOT/'build/android33-upgrade';out.mkdir(parents=True,exist_ok=True)
 tools=sorted(Path(os.environ['ANDROID_HOME']).glob('build-tools/*/apksigner'),key=lambda x:tuple(int(i) for i in x.parent.name.split('.')))[-1].parent
 adb('shell','wm','size','640x1280');adb('shell','wm','density','320');adb('shell','settings','put','system','font_scale','2.0')
 adb('shell','settings','put','secure','show_ime_with_hard_keyboard','1')
 adb('shell','cmd','connectivity','airplane-mode','enable');adb('shell','svc','wifi','disable');adb('shell','svc','data','disable');time.sleep(2)
 (out/'offline-connectivity.txt').write_bytes(adb('shell','dumpsys','connectivity'))
 # Fresh NORMAL UID on this second, separate emulator, current source in EN.
 run(['flutter','test','integration_test/android_first_use_en_test.dart','-d','emulator-5554','--no-pub','--no-uninstall','--reporter','expanded'])
 normal_before=prefs('com.example.mennyiment')
 if subprocess.run(['git','cat-file','-e',BASE+'^{commit}'],cwd=ROOT,capture_output=True).returncode:
  raise RuntimeError('Pinned #50 source absent from checkout; increase checkout fetch-depth. No baseline source is substituted.')
 with tempfile.TemporaryDirectory(prefix='mennyiment-baseline50-') as directory:
  work=Path(directory);process=subprocess.Popen(['git','archive',BASE],cwd=ROOT,stdout=subprocess.PIPE)
  with tarfile.open(fileobj=process.stdout,mode='r|') as archive:archive.extractall(work,filter='data')
  assert process.wait()==0
  # Execute the baseline's own isolation/media code, not the current app code.
  prepare="""from pathlib import Path
from menti_review_media import prepare_review_media
from menti_beta_android import prepare_review_android
w=Path('..').resolve();manifest,additions=prepare_review_media(w,studio=True)
p=w/'pubspec.yaml';s=p.read_text();assert 'version: 3.2.0+45' in s
s+=''.join('    - '+x+'\\n' for x in additions);p.write_text(s)
prepare_review_android(w,studio=True)
"""
  run([sys.executable,'-c',prepare],cwd=work/'tool')
  for name in ['android33_flows.dart','android_upgrade_seed_test.dart']:
   shutil.copyfile(ROOT/'integration_test'/name,work/'integration_test'/name)
  run(['flutter','pub','get'],cwd=work)
  run(['flutter','build','apk','--debug','--target','tool/menti_home_review.dart','--dart-define=MENTI_ALIVE_REVIEW=true','--no-pub'],cwd=work)
  baseline=out/'baseline50-rebuilt-review.apk';shutil.copyfile(work/'build/app/outputs/flutter-apk/app-debug.apk',baseline)
  incoming=ROOT/'build/menti-home-review-apk/app-debug.apk'
  old,new=inspect(baseline,tools),inspect(incoming,tools)
  status,help=decision(old,new);assert status=='compatible-signature' and old['versionCode']==45 and new['versionCode']==46
  comparison={'baselineSource':BASE,'incomingSource':source,'baselineKind':'rebuilt pinned #50 using this CI run debug key; NOT original distributed APK',
   'installed':old,'incoming':new,'preflight':status,'guidance':help,'original48Or50DistributedApkUpgradeTested':False,
   'original48CertificateSha256':'51eeabfb52e48db66c6b0e65be0ed6edec065e638c2bf0ed39dd93b4bb4f637f',
   'original50CertificateSha256':'b70cfaeaf903b3e7f05355ece465c9353dacd287f27244f3308280d9d0cd89ef'}
  (out/'compatible-rebuilt-route.json').write_text(json.dumps(comparison,indent=2)+'\n')
  run(['flutter','test','integration_test/android_upgrade_seed_test.dart','-d','emulator-5554','--dart-define=MENTI_ALIVE_REVIEW=true','--no-pub','--no-uninstall','--reporter','expanded'],cwd=work)
  adb('install','-r',baseline)
  before=prefs(REVIEW)
  (out/'before-upgrade.xml').write_bytes(adb('exec-out','run-as',REVIEW,'cat','shared_prefs/FlutterSharedPreferences.xml'))
  adb('install','-r',incoming);ui=DeviceUI(out);ui.start(REVIEW);ui.stop(REVIEW);ui.start(REVIEW)
  assert prefs(REVIEW)==before,'Persisted values changed on APK replacement or cold restart'
  (out/'after-cold-restart.xml').write_bytes(adb('exec-out','run-as',REVIEW,'cat','shared_prefs/FlutterSharedPreferences.xml'))
  run(['python3','tool/build_menti_alive_preview.py','--home','--platform','apk','--device','emulator-5554','--integration-test','integration_test/android_upgrade_read_test.dart','--output','build/unused-upgrade-test-output'])
  adb('install','-r',incoming);ui.start(REVIEW);assert prefs(REVIEW)==before
  # Real lifecycle UI uses the user's reduced-motion system preference. It does
  # not re-enable movie playback or change any application preference.
  for setting in ['animator_duration_scale','transition_animation_scale','window_animation_scale']:
   adb('shell','settings','put','global',setting,'0')
  results=lifecycle(out/'review-lifecycle')
  adb('install','-r',ROOT/'artifacts/normal/app-debug.apk')
  assert prefs('com.example.mennyiment')==normal_before
  screens=store_screens(out/'store-candidates')
  assert prefs('com.example.mennyiment')==normal_before
  (out/'store-candidates/metadata.json').write_text(json.dumps(screens,indent=2)+'\n')
  (out/'result.json').write_text(json.dumps({'sourceCommit':source,'baselineSource':BASE,'rebuiltSameKeyUpgrade':True,
   'originalDistributedApkUpgrade':False,'allPreferencesEqualAfterUpdateAndColdRestart':True,'nativeReadVerification':True,
   'freshCurrentEnglishFirstUse':True,'logicalWidth':320,'systemFontScale':2,'offlineConfigured':True,
   'actualAndroidLifecycle':results,'normalPreferencesUnchanged':True,'physicalAndroid':False,'emulatorApi':35,
   'baselineApkSha256':old['sha256'],'incomingApkSha256':new['sha256']},indent=2)+'\n')
 print('ANDROID33_UPGRADE: real rebuilt #50 -> delivered candidate, all values preserved after process restart; real lifecycle + isolated virtual day checks passed')
if __name__=='__main__':main()
