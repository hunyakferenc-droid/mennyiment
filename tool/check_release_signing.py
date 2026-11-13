"""Exercise real Gradle bundleRelease rejections without making a signing key.

Run after a successful debug build so Gradle/plugin dependencies are available.
All credentials below are disposable test sentinels, never real signing data.
Only redacted results are written. No existing AAB is removed or replaced.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
android = root / 'android'
wrapper = android / ('gradlew.bat' if os.name == 'nt' else 'gradlew')
if not wrapper.is_file():
    raise SystemExit('Run a debug Android build first to prepare the Gradle wrapper.')

def aabs():
    folder = root / 'build/app/outputs/bundle'
    return {str(p.relative_to(root)): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in folder.rglob('*.aab')} if folder.exists() else {}

before = aabs()
env = {k: v for k, v in os.environ.items() if not k.startswith('MENNYIMENT_')}
results = []
with tempfile.TemporaryDirectory(prefix='mennyiment-signing-check-') as temp:
    private = Path(temp)
    private_props = private / 'key.properties'
    store_secret = 'sentinel-store-password-2f934c'
    key_secret = 'sentinel-key-password-a83e67'
    alias_secret = 'sentinel-upload-alias-48c303'
    for name, expected, props in [
        ('missing credentials', 'MISSING', ''),
        ('nonexistent external keystore', 'FILE',
         f'storeFile={private.as_posix()}/missing.jks\nstorePassword={store_secret}\n'
         f'keyAlias={alias_secret}\nkeyPassword={key_secret}\n'),
        ('debug alias refused', 'DEBUG',
         f'storeFile={private.as_posix()}/missing.jks\nstorePassword={store_secret}\n'
         f'keyAlias=androiddebugkey\nkeyPassword={key_secret}\n'),
    ]:
        private_props.write_text(props)
        env['MENNYIMENT_RELEASE_PROPERTIES'] = str(private_props)
        command = [str(wrapper), ':app:bundleRelease', '--console=plain', '--max-workers=2']
        run = subprocess.run(command, cwd=android, env=env, text=True,
                             stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=180)
        output = run.stdout
        if any(value in output for value in [store_secret, key_secret, alias_secret]):
            raise SystemExit('Release signing check failed: a secret sentinel appeared in output (withheld).')
        marker = f'MENNYIMENT_RELEASE_SIGNING[{expected}]'
        if run.returncode == 0 or marker not in output:
            # Raw provider output is not a safe diagnostic artifact.
            markers = re.findall(r'MENNYIMENT_RELEASE_SIGNING\[[A-Z]+\]', output)
            raise SystemExit(f'Release signing check failed for {name}; exit={run.returncode}; markers={markers}. Raw output withheld.')
        if aabs() != before:
            raise SystemExit('A bundle was unexpectedly created or changed by a rejected release.')
        results.append({'case': name, 'expectedMarker': marker,
                        'nonzeroExit': True, 'secretSentinelsAbsent': True, 'aabUnchanged': True})
        print(f'{name}: rejected as expected; no AAB; secret sentinels absent')
args.output.parent.mkdir(parents=True, exist_ok=True)
args.output.write_text(json.dumps({'sourceCommit': os.environ.get('SOURCE_SHA'),
    'cases': results, 'passed': len(results), 'signedReleaseAabBuilt': False}, indent=2) + '\n')
print('3 release-signing rejection checks passed. No release key was created.')
