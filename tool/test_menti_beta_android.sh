#!/usr/bin/env bash
# Disposable CI emulator only. No uninstall, clear-data or signature bypass.
set -euo pipefail
[[ "${GITHUB_ACTIONS:-}" == "true" ]] || { echo "Only run on a disposable GitHub CI emulator."; exit 1; }
export ANDROID_SERIAL=emulator-5554
OUT=build/android-beta
mkdir -p "$OUT"
exec > >(tee "$OUT/device.log") 2>&1
trap 'adb exec-out screencap -p > "$OUT/last-screen.png" || true; adb logcat -d > "$OUT/logcat.txt" || true; adb shell dumpsys meminfo com.example.mennyiment.review > "$OUT/final-memory.txt" || true' EXIT
adb wait-for-device
[[ "$(adb shell getprop ro.kernel.qemu | tr -d '\r')" == "1" ]] || { echo "Refusing a non-emulator device."; exit 1; }
adb shell getprop ro.build.version.release > "$OUT/android-version.txt"
adb install -r artifacts/normal/app-debug.apk
adb install -r artifacts/review/app-debug.apk
adb shell pm list packages | tee "$OUT/packages.txt"
grep -Fx 'package:com.example.mennyiment' "$OUT/packages.txt"
grep -Fx 'package:com.example.mennyiment.review' "$OUT/packages.txt"
adb shell cmd package list packages -U > "$OUT/package-uids.txt"
python3 - <<'CHECK_UIDS'
import re
from pathlib import Path
text=Path('build/android-beta/package-uids.txt').read_text()
uids=[re.search(r'^package:'+re.escape(p)+r' uid:(\d+)$',text,re.M).group(1) for p in ['com.example.mennyiment','com.example.mennyiment.review']]
assert len(set(uids))==2, 'Normal and REVIEW must have distinct Android UIDs'
print('Separate Android sandbox UIDs verified:', uids)
CHECK_UIDS
# Both apps are installed simultaneously. Integration tests use native plugins.
flutter test integration_test/menti_beta_device_test.dart -d emulator-5554 --no-pub --no-uninstall
# Sample actual process memory while the native review test runs.
(while true; do date -u +%FT%TZ; adb shell dumpsys meminfo com.example.mennyiment.review; sleep 4; done) > "$OUT/review-memory-samples.txt" 2>&1 &
SAMPLER=$!
python3 tool/build_menti_alive_preview.py --studio --platform apk --device emulator-5554 --output build/unused-device-output || { kill "$SAMPLER"; exit 1; }
kill "$SAMPLER"
adb shell dumpsys -l > "$OUT/dumpsys-services.txt"
adb shell dumpsys media.resource_manager > "$OUT/codec-after-tests.txt"
adb shell run-as com.example.mennyiment cat shared_prefs/FlutterSharedPreferences.xml | sha256sum > "$OUT/normal-pre-update.sha256"
# Return to the exact delivered APKs; same signing key and data-preserving update.
adb install -r artifacts/normal/app-debug.apk
adb install -r artifacts/review/app-debug.apk
adb shell run-as com.example.mennyiment cat shared_prefs/FlutterSharedPreferences.xml | sha256sum > "$OUT/normal-post-update.sha256"
cmp "$OUT/normal-pre-update.sha256" "$OUT/normal-post-update.sha256"
adb shell wm size 720x1600
adb shell wm density 320
adb shell settings put system font_scale 2.0
adb shell am start -W -n com.example.mennyiment/com.example.mennyiment.MainActivity
sleep 3
adb exec-out screencap -p > "$OUT/normal-360-200.png"
adb shell input keyevent KEYCODE_HOME
adb shell am start -W -n com.example.mennyiment.review/com.example.mennyiment.MainActivity
sleep 3
adb exec-out screencap -p > "$OUT/review-360-200.png"
adb shell dumpsys meminfo com.example.mennyiment.review > "$OUT/review-idle-memory.txt"
adb shell input keyevent KEYCODE_BACK
adb shell am start -W -n com.example.mennyiment/com.example.mennyiment.MainActivity
adb shell dumpsys activity activities > "$OUT/activities.txt"
python3 - <<'PY'
import json,os
from pathlib import Path
Path('build/android-beta/result.json').write_text(json.dumps({'sourceCommit':os.environ['MENTI_SOURCE_COMMIT'],'emulator':True,'physicalAndroid':False,'api':35,'abi':'x86_64','simultaneousInstall':True,'nativeIntegrationTests':True,'lifecycleAndBackInputs':True,'systemFontScale':2,'logicalWidth':360,'filePickerManuallyVerified':False,'memory':'dumpsys samples every 4 seconds during native test, idle sample and codec dump; not a continuous peak-RAM benchmark'},indent=2))
PY
