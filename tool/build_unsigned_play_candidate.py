"""Explicit unsigned release preparation in a disposable committed archive.

Normal Gradle release tasks retain their strict signing guard. This tool never
creates a key, uses debug signing, or labels an unsigned bundle upload-ready.
"""
import argparse, hashlib, json, os, re, shutil, struct, subprocess, tarfile, tempfile, zipfile
from pathlib import Path
import xml.etree.ElementTree as ET
from menti_beta_android import ensure_committed_source

NORMAL_ID = 'com.example.mennyiment'
BUNDLETOOL_SHA256 = 'a099cfa1543f55593bc2ed16a70a7c67fe54b1747bb7301f37fdfd6d91028e29'

def prepare_unsigned(work):
    if work.resolve() == Path(__file__).resolve().parents[1]:
        raise ValueError('Refusing to patch the working checkout; use a disposable archive.')
    p = work / 'android/app/build.gradle.kts'
    s = p.read_text()
    signing = 'signingConfig = signingConfigs.getByName("release")'
    guard = 'dependsOn(validateMennyiMentReleaseSigning)'
    if s.count(signing) != 1 or s.count(guard) != 1:
        raise ValueError('Unexpected release guard; no source or signing changes made.')
    s = s.replace(signing, 'signingConfig = null // EXPLICIT UNSIGNED PREPARATION ONLY')
    s = s.replace(guard, '// EXPLICIT UNSIGNED PREPARATION ONLY: no signing task.')
    p.write_text(s)

def elf_alignments(data):
    if data[:4] != b'\x7fELF' or len(data) < 64 or data[4] not in [1, 2] or data[5] not in [1, 2]:
        raise ValueError('Invalid ELF library')
    endian = '<' if data[5] == 1 else '>'
    wide = data[4] == 2
    offset = struct.unpack_from(endian + ('Q' if wide else 'I'), data, 32 if wide else 28)[0]
    size, count = struct.unpack_from(endian + 'HH', data, 54 if wide else 42)
    if size < (56 if wide else 32) or offset + size * count > len(data):
        raise ValueError('Invalid ELF program headers')
    values = [struct.unpack_from(endian + ('Q' if wide else 'I'), data, offset + i*size + (48 if wide else 28))[0]
              for i in range(count) if struct.unpack_from(endian + 'I', data, offset + i*size)[0] == 1]
    if not values: raise ValueError('Missing ELF load segments')
    return values

def check_unsigned(aab, manifest_text, config_text, source, version, build, root):
    manifest = ET.fromstring(manifest_text); ns = '{http://schemas.android.com/apk/res/android}'
    assert manifest.get('package') == NORMAL_ID
    assert manifest.get(ns+'versionCode') == str(build) and manifest.get(ns+'versionName') == version
    sdk = manifest.find('uses-sdk'); assert int(sdk.get(ns+'targetSdkVersion')) >= 36
    app = manifest.find('application'); assert app.get(ns+'label') == 'MennyiMent?' and app.get(ns+'icon')
    permissions = sorted(x.get(ns+'name') for x in manifest.findall('uses-permission'))
    assert set(permissions) <= {'android.permission.INTERNET', NORMAL_ID+'.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION'}, permissions
    rows = []
    with zipfile.ZipFile(aab) as z:
        assert z.testzip() is None
        assert not any(re.fullmatch(r'META-INF/[^/]+\.(SF|RSA|DSA|EC)', n, re.I) for n in z.namelist()), 'Unsigned candidate contains a signing block'
        assert not any(n.endswith('.mp4') for n in z.namelist()), 'REVIEW media must not enter the Play candidate'
        prefix = 'base/assets/flutter_assets/'
        assert json.loads(z.read(prefix+'assets/menti_life/catalog.json'))['clips'] == []
        originals = list((root/'assets/images/menti_complete').glob('*.png')); assert len(originals)==18
        for p in originals:
            assert hashlib.sha256(z.read(prefix+str(p.relative_to(root)))).digest()==hashlib.file_digest(p.open('rb'),'sha256').digest()
        for n in z.namelist():
            if n.endswith('.so'):
                values = elf_alignments(z.read(n))
                if '/arm64-v8a/' in n or '/x86_64/' in n: assert min(values)>=16384, (n, values)
                rows.append({'file':n,'minimumPtLoadAlignment':min(values)})
    assert any('/arm64-v8a/' in x['file'] for x in rows)
    config = json.loads(config_text)
    uncompress = config.get('optimizations',{}).get('uncompressNativeLibraries',{})
    if uncompress.get('enabled'): assert uncompress.get('alignment') == 'PAGE_ALIGNMENT_16K', uncompress
    return {'sourceCommit':source,'version':version,'versionCode':build,'applicationId':NORMAL_ID,
            'signingState':'unsigned','uploadReady':False,'uploadCertificateVerified':False,
            'targetSdk':int(sdk.get(ns+'targetSdkVersion')),'minSdk':int(sdk.get(ns+'minSdkVersion')),
            'applicationLabel':app.get(ns+'label'),'permissions':permissions,
            'androidAllowBackupExplicit':app.get(ns+'allowBackup'),'originalPngHashesVerified':18,
            'productionVideoCount':0,'nativeLibraries':rows,'bundleNativePackaging':uncompress,
            'bundletoolValidated':True,'runtime16KbTested':False,'physicalAndroidTested':False,
            'aabSha256':hashlib.file_digest(aab.open('rb'),'sha256').hexdigest()}

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--unsigned',action='store_true',required=True)
    p.add_argument('--output',type=Path,required=True)
    p.add_argument('--bundletool',type=Path,required=True)
    p.add_argument('--flutter',default='flutter')
    a=p.parse_args();root=Path(__file__).resolve().parents[1]
    ensure_committed_source(root)
    if hashlib.file_digest(a.bundletool.open('rb'),'sha256').hexdigest()!=BUNDLETOOL_SHA256:
        raise SystemExit('Use the pinned official bundletool-all 1.18.3 with the documented SHA-256.')
    a.bundletool=a.bundletool.resolve(); a.output=a.output.resolve()
    if a.output.exists() and any(a.output.iterdir()): raise SystemExit('Output must be empty; existing files preserved.')
    source=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
    version_text=(root/'pubspec.yaml').read_text();m=re.search(r'^version: (\S+)\+(\d+)$',version_text,re.M);version,build=m[1],int(m[2])
    with tempfile.TemporaryDirectory(prefix='mennyiment-unsigned-release-') as temp:
        work=Path(temp);process=subprocess.Popen(['git','archive','HEAD'],cwd=root,stdout=subprocess.PIPE)
        with tarfile.open(fileobj=process.stdout,mode='r|') as archive:archive.extractall(work,filter='data')
        if process.wait()!=0: raise SystemExit('Source archive failed')
        prepare_unsigned(work)
        env={k:v for k,v in os.environ.items() if not k.startswith('MENNYIMENT_')}
        env['MENNYIMENT_RELEASE_PROPERTIES']=str(work/'no-signing-properties')
        for args in [['pub','get'],['build','appbundle','--release','--no-pub']]:
            subprocess.run([a.flutter,*args],cwd=work,env=env,check=True)
        bundle=work/'build/app/outputs/bundle/release/app-release.aab'
        def tool(*args):
            return subprocess.run(['java','-jar',str(a.bundletool),*args,'--bundle='+str(bundle)],check=True,capture_output=True,text=True).stdout
        tool('validate')
        dependencies = subprocess.run([str(work/'android/gradlew'), ':app:dependencies', '--configuration', 'releaseRuntimeClasspath', '--console=plain'], cwd=work/'android', env=env, check=True, capture_output=True, text=True).stdout
        manifest=tool('dump','manifest','--module=base');config=tool('dump','config')
        verification=check_unsigned(bundle,manifest,config,source,version,build,root)
        a.output.mkdir(parents=True,exist_ok=True)
        target=a.output/'app-release-UNSIGNED.aab';shutil.copyfile(bundle,target)
        (a.output/'app-release-UNSIGNED.aab.sha256').write_text(verification['aabSha256']+'  '+target.name+'\n')
        (a.output/'release-manifest.xml').write_text(manifest)
        (a.output/'release-runtime-dependencies.txt').write_text(dependencies)
        (a.output/'bundle-config.json').write_text(config)
        (a.output/'aab-verification.json').write_text(json.dumps(verification,indent=2)+'\n')
        (a.output/'build-info.txt').write_text(f'source_commit={source}\nversion={version}+{build}\nsigning=UNSIGNED\nupload_ready=false\napplication_id={NORMAL_ID}\n')
        shutil.copyfile(root/'docs/play-3.3/ALÁÍRATLAN-AAB-HU.md',a.output/'OLVASDEL-UNSIGNED-AAB.txt')
        print('UNSIGNED release candidate verified. NOT upload-ready; original release signing guard unchanged.')
if __name__=='__main__':main()
