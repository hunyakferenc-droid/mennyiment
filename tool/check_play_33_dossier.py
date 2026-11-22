"""Check real dossier/source invariants, not ownership or Console approval."""
import hashlib,json,os,re,subprocess
from pathlib import Path
root=Path(__file__).resolve().parents[1]
listing=json.loads((root/'docs/play-3.3/store-listing-hu-en.json').read_text())
for lang in ['hu','en']:
 d=listing[lang]
 assert 0<len(d['title'])<=30 and 0<len(d['short'])<=80 and 0<len(d['full'])<=4000 and 0<len(d['releaseNotes'])<=500
 assert not re.search(r'Fitness Club|Fitneszklub|Movement Cards|Mozgáskártyák',d['full']), 'Do not advertise disabled REVIEW functions in the Play candidate'
assert listing['ownerApproved'] is False
lock=(root/'pubspec.lock').read_text();versions={}
for m in re.finditer(r'^  ([A-Za-z0-9_]+):\n(.*?)(?=^  [A-Za-z0-9_]+:|\Z)',lock,re.M|re.S):
 v=re.search(r'^    version: "([^"]+)"',m[2],re.M)
 if v:versions[m[1]]=v[1]
for name in ['shared_preferences','file_picker','package_info_plus','video_player','video_player_android','crypto','intl']:assert name in versions,name
assert not any(re.search(r'^(firebase|sentry|google_mobile_ads|amplitude|mixpanel)',name) for name in versions)
manifest=(root/'android/app/src/main/AndroidManifest.xml').read_text()
assert 'android:label="MennyiMent?"' in manifest and '@drawable/menti_launcher' in manifest
assert 'applicationId = "com.example.mennyiment"' in (root/'android/app/build.gradle.kts').read_text()
source=os.environ.get('SOURCE_SHA') or subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
out=root/'build/play-dossier';out.mkdir(parents=True,exist_ok=True)
(out/'dossier-audit.json').write_text(json.dumps({'sourceCommit':source,'lockfileSha256':hashlib.sha256(lock.encode()).hexdigest(),
 'packageVersions':versions,'listingLimitsVerified':True,'ownerApproved':False,'privacyPolicyUrlVerified':False, 'publishedByThisTask':False,
 'controllerDetailsProvided':False,'uploadSigningVerified':False,'playConsoleOpened':False,
 'reviewedRuntimePaths':['lib/backup_file.dart','lib/menti_animation_controller.dart','lib/main.dart','lib/menti_club_store.dart','lib/menti_favorites_store.dart'],
 'independentPrivacyAudit':False},indent=2)+'\n')
print('3.3 dossier: HU/EN listing limits and actual lockfile checked; owner/Console/signing approval not asserted')
