"""Read-only atlas indexing: source PNG pixels are never changed.

Derives stable source rectangles, alpha contours for the eighteen hands, and
integrity metadata for Flutter's cached material composition. Requires Pillow.
"""
from collections import deque
from pathlib import Path
import hashlib
import json
import zlib
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUTFITS = ['basic', 'basic-alt', 'party', 'party-alt', 'sport', 'sport-alt',
           'business', 'business-alt', 'festival', 'festival-alt', 'legendary',
           'legendary-alt', 'street', 'street-alt', 'cozy', 'cozy-alt',
           'explorer', 'explorer-alt', 'creative', 'creative-alt']
HAIR = [f'{family}-{style}' for family in ['boy', 'girl', 'neutral']
        for style in ['crop', 'waves', 'curls', 'braid', 'bob', 'crest']]
FEATURES = [f'face:{style}' for style in ['cheerful', 'calm', 'playful',
            'confident', 'sleepy', 'determined']] + [f'eyes:{style}'
            for style in ['round', 'wide', 'relaxed', 'sharp', 'blink', 'wink']]
GROUPS = {
    'bodies': (3, 3, [f'{family}-{age}' for family in ['boy', 'girl', 'neutral']
                      for age in ['young', 'adult', 'veteran']]),
    'outfits': (5, 4, OUTFITS), 'hair': (6, 3, HAIR),
    'features': (6, 2, FEATURES),
    'headwear': (3, 3, ['crown-cap', 'sport-cap', 'beanie', 'headphones',
                       'party-crown', 'hood', 'party-hat', 'beret', 'cowboy']),
}


def hand_geometry(image, body, right):
    """Separate the outer hand component from the hip without editing the PNG.

    The wrist crosses the ROI's top edge and is covered by the sleeve at runtime.
    The full finger contour is retained; nearby leg pixels are excluded.
    """
    x, y, width, height = body
    box = (x + int(width * (.69 if right else 0)), y + int(height * .60),
           x + int(width * (1 if right else .31)), y + int(height * .84))
    alpha = image.getchannel('A').crop(box)
    pixels = alpha.load()
    remaining = {(i, j) for j in range(alpha.height) for i in range(alpha.width)
                 if pixels[i, j] > 150}
    components = []
    while remaining:
        seed = remaining.pop()
        queue, component = deque([seed]), [seed]
        while queue:
            i, j = queue.popleft()
            for neighbor in [(i-1, j), (i+1, j), (i, j-1), (i, j+1)]:
                if neighbor in remaining:
                    remaining.remove(neighbor)
                    component.append(neighbor)
                    queue.append(neighbor)
        if len(component) > 100:
            components.append(component)
    if len(components) < 2:
        raise ValueError(f'Hand and hip must be separate in ROI: {body}, {right}')
    ordered = sorted(components, key=lambda points: sum(p[0] for p in points) / len(points))
    component = ordered[-1 if right else 0]
    left, top = min(p[0] for p in component), min(p[1] for p in component)
    last_x, last_y = max(p[0] for p in component), max(p[1] for p in component)
    rect = [box[0]+left, box[1]+top, last_x-left+1, last_y-top+1]
    rows = {}
    for i, j in component:
        if j not in rows:
            rows[j] = [i, i]
        else:
            rows[j][0] = min(rows[j][0], i)
            rows[j][1] = max(rows[j][1], i)
    selected = sorted(set([top, last_y] + list(range(top, last_y+1, 2))))
    # One pixel of contour padding retains the source's soft alpha edge.
    lhs = [(max(0, rows[j][0]-left-1)/rect[2], (j-top)/rect[3]) for j in selected]
    rhs = [(min(rect[2], rows[j][1]-left+2)/rect[2], (j-top+1)/rect[3])
           for j in reversed(selected)]
    return rect, [[round(a, 6), round(b, 6)] for a, b in lhs+rhs]


manifest, rectangles, outlines = {}, {}, {}
for group, (columns, row_count, identifiers) in GROUPS.items():
    path = ROOT / f'assets/images/menti_2_2/premium/{group}.png'
    image = Image.open(path).convert('RGBA')
    width, height = image.size
    cells, hands = {}, {}
    for index, identifier in enumerate(identifiers):
        col, row = index % columns, index // columns
        cell = (round(col*width/columns), round(row*height/row_count),
                round((col+1)*width/columns), round((row+1)*height/row_count))
        if group == 'outfits':
            # The source artist's gutters are measured, not assumed to be equal.
            bounds = [(0, 312), (314, 620), (622, 927), (930, 1254)]
            cell = (cell[0], bounds[row][0], cell[2], bounds[row][1])
        alpha = image.getchannel('A').crop(cell).point(lambda v: 255 if v > 150 else 0)
        bbox = alpha.getbbox()
        if not bbox:
            raise ValueError(f'Empty sprite: {group}/{identifier}')
        rect = [cell[0]+bbox[0], cell[1]+bbox[1], bbox[2]-bbox[0], bbox[3]-bbox[1]]
        cells[identifier] = rect
        rectangles[f'{group}/{identifier}'] = rect
        if group == 'bodies':
            for right in [False, True]:
                key = f'{identifier}-{"right" if right else "left"}-hand'
                hand_rect, contour = hand_geometry(image, rect, right)
                hands[key] = {'rect': hand_rect, 'contour': contour}
                rectangles[f'bodies/{key}'] = hand_rect
                outlines[f'bodies/{key}'] = contour
    data = path.read_bytes()
    manifest[group] = {'asset': str(path.relative_to(ROOT)), 'size': [width, height],
                       'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest(),
                       'crc32': zlib.crc32(data), 'columns': columns, 'rows': row_count,
                       'sprites': cells}
    if hands:
        manifest[group]['hands'] = hands
lines = ["// Generated by tool/index_menti_premium_atlases.py; source pixels are unchanged.",
         "import 'dart:ui';", 'class MentiPremiumAtlas {',
         "  static const root = 'assets/images/menti_2_2/premium/';",
         '  static const rects = <String, Rect>{']
for key, rect in rectangles.items():
    lines.append(f"    '{key}': Rect.fromLTWH({','.join(map(str, rect))}),")
lines += ['  };', '  static const handOutlines = <String,List<Offset>>{']
for key, points in outlines.items():
    lines.append(f"    '{key}': [" + ','.join(f'Offset({a},{b})' for a, b in points) + '],')
lines += ['  };', '}']
(ROOT/'lib/menti_identity/menti_premium_atlas.dart').write_text('\n'.join(lines)+'\n')
(ROOT/'test/fixtures/menti_premium_atlases.json').write_text(json.dumps(manifest, indent=2)+'\n')
