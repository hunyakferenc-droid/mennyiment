"""Prepare only the isolated render harness, never the shipped app webbuild.

Changing a harness query repeatedly makes Chromium refetch/cancel its favicon.
Use a self-contained empty favicon so every failed graphics request remains an
error in the capture tool. Application HTML, icons and assets are untouched.
"""
import argparse
from pathlib import Path

p = argparse.ArgumentParser()
p.add_argument('web_directory', type=Path)
a = p.parse_args()
file = a.web_directory / 'index.html'
html = file.read_text()
assert 'flutter_bootstrap.js' in html
assert 'href="icons/Menti.png"' in html or 'href="data:,"' in html
file.write_text(html.replace('href="icons/Menti.png"', 'href="data:,"'))
