"""Check Play draft text limits and actual local references; no Console access."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
folder = root / 'docs/play-2.3.1'
text = (folder / 'store-listing-hu.md').read_text()
for title, limit in [('Alkalmazás neve', 30), ('Rövid leírás', 80), ('Teljes leírás', 4000)]:
    value = re.search(r'## ' + re.escape(title) + r'\n\n(.*?)(?=\n## |\Z)', text, re.S).group(1).strip()
    assert value and len(value) <= limit, (title, len(value), limit)
    print(f'{title}: {len(value)}/{limit} characters')
for page in [*folder.glob('*.md'), root / 'docs/2.3.1-play-preparation-hu.md']:
    for reference in re.findall(r'\]\(([^)]+)\)', page.read_text()):
        if not reference.startswith(('https://', 'http://', '#')):
            target = reference.split('#')[0]
            assert (page.parent / target).exists(), (page.name, target)
print('All local dossier references exist. These are drafts, not Play submissions.')
