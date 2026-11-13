"""Read-only debug APK signature, provenance and 16 KB static layout checks.

This does not test Android runtime, release AABs or Google Play acceptance.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct
import subprocess
import zipfile

p = argparse.ArgumentParser()
p.add_argument('apk', type=Path)
p.add_argument('--build-tools', type=Path, required=True)
p.add_argument('--source', required=True)
p.add_argument('--version', required=True)
p.add_argument('--build', required=True)
p.add_argument('--output', type=Path, required=True)
a = p.parse_args()
assert re.fullmatch(r'[0-9a-f]{40}', a.source)
assert f'source_commit={a.source}' in (a.apk.parent / 'build-info.txt').read_text(encoding='utf-8')
raw = a.apk.read_bytes()
digest = hashlib.sha256(raw).hexdigest()
assert (a.apk.parent / 'app-debug.apk.sha256').read_text().split()[0] == digest

def run(tool, *args):
    return subprocess.run([str(a.build_tools / tool), *map(str, args)], check=True,
                          capture_output=True, text=True).stdout

signature = run('apksigner', 'verify', '--verbose', '--print-certs', a.apk)
badging = run('aapt', 'dump', 'badging', a.apk)
permissions = run('aapt', 'dump', 'permissions', a.apk)
run('zipalign', '-c', '-P', '16', '4', a.apk)
assert "name='com.example.mennyiment'" in badging.splitlines()[0]
assert f"versionName='{a.version}'" in badging.splitlines()[0]
assert f"versionCode='{a.build}'" in badging.splitlines()[0]
assert "targetSdkVersion:'36'" in badging
cert = re.search(r'Signer #1 certificate SHA-256 digest: (\w+)', signature).group(1)
rows = []
with zipfile.ZipFile(a.apk) as archive:
    assert archive.testzip() is None
    for name in archive.namelist():
        if not name.endswith('.so'):
            continue
        data = archive.read(name)
        assert data[:4] == b'\x7fELF'
        cls = data[4]
        endian = '<' if data[5] == 1 else '>'
        if cls == 2:
            offset = struct.unpack_from(endian + 'Q', data, 32)[0]
            size, count = struct.unpack_from(endian + 'HH', data, 54)
            alignment_offset, fmt = 48, 'Q'
        else:
            offset = struct.unpack_from(endian + 'I', data, 28)[0]
            size, count = struct.unpack_from(endian + 'HH', data, 42)
            alignment_offset, fmt = 28, 'I'
        loads = []
        for i in range(count):
            header = offset + i * size
            if struct.unpack_from(endian + 'I', data, header)[0] == 1:
                loads.append(struct.unpack_from(endian + fmt, data, header + alignment_offset)[0])
        assert loads
        if '/arm64-v8a/' in name or '/x86_64/' in name:
            assert min(loads) >= 16384, (name, loads)
        rows.append({'file': name, 'minimumPtLoadAlignment': min(loads)})
assert any('/arm64-v8a/' in r['file'] for r in rows)
a.output.parent.mkdir(parents=True, exist_ok=True)
a.output.write_text(json.dumps({'sourceCommit': a.source, 'apkSha256': digest,
    'apkBytes': len(raw), 'certificateSha256': cert, 'signatureVerification': signature,
    'badging': badging.splitlines()[:6], 'permissions': permissions.splitlines(),
    'zipAlignment16Kb': True, 'nativeLibraries': rows, 'runtime16KbTested': False,
    'physicalAndroid': False, 'emulator': False, 'signedReleaseAabBuilt': False}, indent=2) + '\n', encoding='utf-8')
print(f'APK verified: {a.version}+{a.build}; certificate {cert}; static ZIP/64-bit ELF 16 KB checks passed. Runtime untested.')
