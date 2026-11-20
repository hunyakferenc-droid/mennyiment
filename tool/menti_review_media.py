"""Prepare only the isolated REVIEW tree, including its actual loaded catalog."""
import hashlib
import json
import shutil
from pathlib import Path


def prepare_review_media(work, studio=False):
    legacy = work / 'tool/menti_alive/review_assets'
    extra = work / 'tool/menti_animation_studio/review_assets'
    catalog = json.loads((legacy / 'catalog.json').read_text(encoding='utf-8'))
    if studio:
        additional = json.loads((extra / 'catalog.json').read_text(encoding='utf-8'))
        assert additional['previewOnly'] is True and additional['status'] == 'reviewRequired'
        catalog = {**catalog, 'clips': catalog['clips'] + additional['clips']}
    assert catalog['previewOnly'] is True and catalog['status'] == 'reviewRequired'
    assert json.loads((work / 'assets/menti_life/catalog.json').read_text())['clips'] == []
    additions = []
    for clip in catalog['clips']:
        assert all(clip[k] is False for k in ['rightsVerified', 'identityVerified', 'backgroundApproved', 'ownerApproved'])
        candidate = legacy / Path(clip['asset']).name
        if studio and not candidate.exists():
            candidate = extra / Path(clip['asset']).name
        assert hashlib.sha256(candidate.read_bytes()).hexdigest() == clip['sha256']
        assert candidate.stat().st_size == clip['bytes']
        target = work / clip['asset']
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(candidate, target)
        additions.append(clip['asset'])
    target = work / 'assets/menti_alive_review/catalog.json'
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    additions.append('assets/menti_alive_review/catalog.json')
    return catalog, additions
