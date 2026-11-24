"""Exercise real Android APK replacement and DocumentsUI on a fresh CI AVD."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time

from android33_device_ui import DeviceUI, NORMAL, REVIEW, STRINGS, adb, prefs, require_emulator
from check_android_update import decision, inspect
from run_android33_upgrade import ROOT, run

BASE = 'c927e42d712f164e2e41b62f3f67088ce4eacb94'

OUT = ROOT / 'build/android34'
DRINKS = 'mennyiment_drinks_v1'
DOWNLOAD = '/sdcard/Download'


def documents_ui(ui, timeout=15):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        tree = ui.dump()
        if any('documentsui' in node.get('package', '').lower()
               for node in tree.iter('node')):
            return True
    return False


def open_restore_picker(ui):
    # Bring the button well clear of Android's bottom gesture area.
    ui.swipe()
    ui.swipe()
    ui.click(STRINGS['restorePick'], top=False)
    if documents_ui(ui):
        return
    # A transition or a partially clipped hit can leave the app foregrounded.
    # Retry only when the original control is still on the app screen.
    assert ui.nodes(STRINGS['restorePick']), 'Restore control left the screen without DocumentsUI'
    ui.swipe()
    ui.click(STRINGS['restorePick'], top=False)
    assert documents_ui(ui), 'Android system DocumentsUI did not open'


def start_review(ui):
    ui.start(REVIEW)
    if ui.nodes("Pixel Launcher isn't responding"):
        ui.click('Close app', top=False)
        ui.start(REVIEW)


def open_backup(ui):
    ui.click(STRINGS['avatarMore'], top=False)
    ui.click(STRINGS['backupTitle'], top=False)


def choose_download(ui, filename):
    open_restore_picker(ui)
    # Navigate explicitly to Downloads, independent of the picker's remembered root.
    ui.click('Show roots', top=False)
    ui.click('Downloads', top=False)
    ui.click(filename, top=False)


def apply_backup(ui):
    ui.visible(STRINGS['restorePreview'])
    ui.click(STRINGS['restoreConfirm'])
    ui.visible(STRINGS['restoreQuestion'])
    ui.click(STRINGS['restoreConfirm'], top=False)
    # Successful restore rebuilds the app and returns to Home.
    ui.visible(STRINGS['avatarMore'])


def backup_round_trip(ui, before):
    adb('shell', 'settings', 'put', 'system', 'font_scale', '1.0')
    ui.stop(REVIEW)
    start_review(ui)
    open_backup(ui)
    ui.click(STRINGS['backupPrepare'])
    ui.click(STRINGS['backupSave'])
    assert documents_ui(ui), 'Android system DocumentsUI did not open'
    ui.back()
    ui.visible(STRINGS['backupCancelled'])
    assert prefs(REVIEW) == before

    ui.click(STRINGS['backupSave'])
    assert documents_ui(ui), 'Android system DocumentsUI did not open'
    ui.click('Show roots', top=False)
    ui.click('Downloads', top=False)
    ui.click('SAVE', top=False)
    ui.visible(STRINGS['backupSaved'])
    listed = adb('shell', 'find', DOWNLOAD, '-maxdepth', '1', '-name',
                 'mennyiment-backup-*.json').decode().splitlines()
    assert len(listed) == 1, listed
    exported_path = listed[0].strip()
    exported = json.loads(adb('exec-out', 'cat', exported_path))
    assert exported['format'] == 'mennyiment.local-backup' and exported['version'] == 1
    assert exported['entries'][DRINKS]['value'] == before['flutter.' + DRINKS][2]

    open_restore_picker(ui)
    ui.back()
    ui.visible(STRINGS['restorePick'])
    assert prefs(REVIEW) == before

    invalid = OUT / 'invalid-review-backup.json'
    invalid.write_text('{"version": 1,')
    adb('push', invalid, f'{DOWNLOAD}/{invalid.name}')
    choose_download(ui, invalid.name)
    ui.visible(STRINGS['restoreInvalid'])
    assert prefs(REVIEW) == before

    # The version-1 envelope also supports older journals without priceFt.
    legacy = OUT / 'legacy-review-backup.json'
    entries = exported['entries']
    drinks = json.loads(entries[DRINKS]['value'])
    assert drinks[0].pop('priceFt') == 0
    legacy_drinks = json.dumps(drinks, ensure_ascii=False, separators=(',', ':'))
    legacy.write_text(json.dumps({
        **exported, 'entries': {DRINKS: {'type': 'string', 'value': legacy_drinks}},
    }, ensure_ascii=False), encoding='utf-8')
    adb('push', legacy, f'{DOWNLOAD}/{legacy.name}')
    choose_download(ui, legacy.name)
    apply_backup(ui)
    expected = dict(before)
    tag, attributes, _, children = expected['flutter.' + DRINKS]
    expected['flutter.' + DRINKS] = tag, attributes, legacy_drinks, children
    assert prefs(REVIEW) == expected

    open_backup(ui)
    choose_download(ui, Path(exported_path).name)
    apply_backup(ui)
    ui.stop(REVIEW)
    ui.start(REVIEW)
    assert prefs(REVIEW) == before


def configure_device():
    adb('shell', 'wm', 'size', '640x1280')
    adb('shell', 'wm', 'density', '320')
    adb('shell', 'settings', 'put', 'system', 'font_scale', '2.0')
    adb('shell', 'settings', 'put', 'secure', 'show_ime_with_hard_keyboard', '1')
    adb('shell', 'cmd', 'connectivity', 'airplane-mode', 'enable')
    adb('shell', 'svc', 'wifi', 'disable')
    adb('shell', 'svc', 'data', 'disable')
    time.sleep(2)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--english-first-use', action='store_true')
    args = parser.parse_args()
    require_emulator()
    configure_device()
    if args.english_first_use:
        run(['flutter', 'test', 'integration_test/android_first_use_en_test.dart',
             '-d', 'emulator-5554', '--no-pub', '--no-uninstall', '--reporter', 'expanded'])
        assert prefs(NORMAL)['flutter.mennyiment_locale_v1'][2] == 'en'
        return

    OUT.mkdir(parents=True, exist_ok=True)
    ui = DeviceUI(OUT / 'device')
    run(['flutter', 'test', 'integration_test/android_first_use_hu_test.dart',
         '-d', 'emulator-5554', '--no-pub', '--no-uninstall', '--reporter', 'expanded'])
    assert prefs(NORMAL)['flutter.mennyiment_locale_v1'][2] == 'hu'

    with tempfile.TemporaryDirectory() as temporary:
        work = Path(temporary) / 'baseline'
        run(['git', 'worktree', 'add', '--detach', work, BASE])
        try:
            run(['python3', 'tool/build_menti_alive_preview.py', '--home',
                 '--platform', 'apk', '--output', OUT / 'baseline'], cwd=work)
            # Only test sources are overlaid. The existing #53 app remains the baseline.
            for filename in ['android33_flows.dart', 'android_upgrade_seed_test.dart']:
                (work / 'integration_test' / filename).write_bytes(
                    (ROOT / 'integration_test' / filename).read_bytes()
                )
            run(['python3', '-c', '''
from pathlib import Path
from menti_review_media import prepare_review_media
from menti_beta_android import prepare_review_android
work = Path("..").resolve()
_, additions = prepare_review_media(work, studio=True)
manifest = work / "pubspec.yaml"
manifest.write_text(manifest.read_text() + "".join(f"    - {asset}\\n" for asset in additions))
prepare_review_android(work, studio=True)
'''], cwd=work / 'tool')
            run(['flutter', 'pub', 'get'], cwd=work)
            run(['flutter', 'test', 'integration_test/android_upgrade_seed_test.dart',
                 '-d', 'emulator-5554', '--no-pub', '--no-uninstall', '--reporter',
                 'expanded', '--dart-define=MENTI_ALIVE_REVIEW=true'], cwd=work)
        finally:
            run(['git', 'worktree', 'remove', '--force', work])

    baseline = OUT / 'baseline/app-debug.apk'
    candidate = OUT / 'review/app-debug.apk'
    sdk_tools = max(Path(os.environ['ANDROID_HOME']).glob('build-tools/*/apksigner'),
                    key=lambda p: tuple(map(int, p.parent.name.split('.')))).parent
    old, new = inspect(baseline, sdk_tools), inspect(candidate, sdk_tools)
    assert old['versionCode'] == 47 and new['versionCode'] == 48
    assert decision(old, new)[0] == 'compatible-signature'
    before = prefs(REVIEW)
    adb('install', '-r', baseline)
    ui.start(REVIEW)
    ui.stop(REVIEW)
    start_review(ui)
    assert prefs(REVIEW) == before
    ui.visible(STRINGS['avatarMore'])
    ui.screen('home-before-320dp-200pct')
    adb('install', '-r', candidate)
    ui.start(REVIEW)
    ui.stop(REVIEW)
    start_review(ui)
    assert prefs(REVIEW) == before
    ui.visible(STRINGS['avatarMore'])
    ui.screen('home-after-320dp-200pct')
    ui.click(STRINGS['fitnessTitle'], top=False)
    ui.visible(STRINGS['rhythmTitle'])
    ui.back()
    ui.visible(STRINGS['avatarMore'])
    assert prefs(REVIEW) == before
    verification = {
        'sourceCommit': os.environ['SOURCE_SHA'], 'rebuiltBaselineSource': BASE,
        'review': new, 'rebuiltBaseline': old, 'emulatorApi': 35,
        'exactPreferencesAfterBaselineRestart': True,
        'exactPreferencesAfterUpgradeAndRestart': True,
        'historicallyDistributedApkVerified': False,
        'physicalAndroidTested': False,
    }
    (ui.out / 'upgrade-verification.json').write_text(
        json.dumps(verification, indent=2) + '\n', encoding='utf-8')
    print('REVIEW_UPGRADE_VERIFIED', json.dumps(verification), flush=True)
    backup_round_trip(ui, before)
    verification.update({
        'exactPreferencesAfterExportAndRestore': True,
        'systemPickerExportCancellationImportCancellationInvalidAndLegacy': True,
    })
    (OUT / 'verification.json').write_text(
        json.dumps(verification, indent=2) + '\n', encoding='utf-8')


if __name__ == '__main__':
    main()
