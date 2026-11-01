#!/usr/bin/env python3
"""Build exact-reference review boards for the Menti 2.2 concept gate.

The source PNGs are immutable review checkpoints. This script only scales and
places them on labelled boards; it does not synthesize or repaint character art.
"""

from __future__ import annotations

import json
import zlib
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs/images/menti-concept-redesign"
FIXTURE = ROOT / "test/fixtures/menti_concept_assets.json"

ROWS = (
    (
        "Fiú",
        OUT / "references/01-classic-approved.png",
        OUT / "concepts/boy-concept-v1.png",
    ),
    (
        "Lány",
        OUT / "references/02-girl-approved.png",
        OUT / "concepts/girl-concept-v1.png",
    ),
    (
        "Semleges",
        OUT / "references/03-street-approved.png",
        OUT / "concepts/neutral-concept-v1.png",
    ),
)


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    name = "DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf"
    return ImageFont.truetype(f"/usr/share/fonts/truetype/dejavu/{name}", size)


def panel(size: tuple[int, int]) -> Image.Image:
    image = Image.new("RGB", size, "#14111d")
    draw = ImageDraw.Draw(image)
    for y in range(size[1]):
        t = y / max(1, size[1] - 1)
        color = (
            round(20 + 16 * t),
            round(17 + 10 * t),
            round(29 + 23 * t),
        )
        draw.line((0, y, size[0], y), fill=color)
    return image


def place_contained(
    board: Image.Image,
    source_path: Path,
    box: tuple[int, int, int, int],
) -> None:
    source = Image.open(source_path).convert("RGBA")
    left, top, right, bottom = box
    limit = (right - left, bottom - top)
    source.thumbnail(limit, Image.Resampling.LANCZOS)
    x = left + (limit[0] - source.width) // 2
    y = top + (limit[1] - source.height) // 2
    board.paste(source, (x, y), source)


def draw_cell(
    board: Image.Image,
    source: Path,
    box: tuple[int, int, int, int],
    label: str,
) -> None:
    draw = ImageDraw.Draw(board)
    left, top, right, bottom = box
    draw.rounded_rectangle(box, radius=26, fill="#211a2d", outline="#6f5a83", width=2)
    draw.text((left + 22, top + 18), label, font=font(24, True), fill="#f8efff")
    place_contained(board, source, (left + 18, top + 62, right - 18, bottom - 18))


def render_reference_comparison() -> Path:
    board = panel((1500, 1460))
    draw = ImageDraw.Draw(board)
    draw.text((50, 34), "Jóváhagyott referencia → új koncepció", font=font(38, True), fill="#fff5d7")
    draw.text(
        (50, 86),
        "Az eredeti képek és a koncepciók változtatás nélküli forrásfájlokból kerülnek a táblára.",
        font=font(19),
        fill="#cfc2dc",
    )
    column_width = 460
    gap = 30
    for column, (family, reference, concept) in enumerate(ROWS):
        x = 30 + column * (column_width + gap)
        draw_cell(board, reference, (x, 140, x + column_width, 760), f"{family} · eredeti")
        draw_cell(board, concept, (x, 790, x + column_width, 1410), f"{family} · koncepció v1")
    path = OUT / "reference-vs-concept.png"
    board.save(path, optimize=True)
    return path


def render_concept_lineup() -> Path:
    board = panel((1500, 780))
    draw = ImageDraw.Draw(board)
    draw.text((50, 28), "Menti 2.2 · három alapkarakter koncepció", font=font(38, True), fill="#fff5d7")
    draw.text(
        (50, 80),
        "Fiú: kerek-sportos · Lány: lágy, hajkeretezett · Semleges: nyugodt streetwear sziluett",
        font=font(19),
        fill="#cfc2dc",
    )
    column_width = 460
    gap = 30
    for column, (family, _, concept) in enumerate(ROWS):
        x = 30 + column * (column_width + gap)
        draw_cell(board, concept, (x, 125, x + column_width, 745), family)
    path = OUT / "concept-lineup.png"
    board.save(path, optimize=True)
    return path


def inventory(paths: list[Path]) -> None:
    items = []
    for path in paths:
        data = path.read_bytes()
        with Image.open(path) as image:
            items.append(
                {
                    "path": path.relative_to(ROOT).as_posix(),
                    "width": image.width,
                    "height": image.height,
                    "mode": image.mode,
                    "bytes": len(data),
                    "crc32": zlib.crc32(data),
                }
            )
    FIXTURE.write_text(json.dumps({"assets": items}, ensure_ascii=False, indent=2) + "\n")


def main() -> None:
    comparison = render_reference_comparison()
    lineup = render_concept_lineup()
    inventory(
        [path for _, reference, concept in ROWS for path in (reference, concept)]
        + [comparison, lineup]
    )
    print("Rendered exact-reference comparison and three-concept lineup")


if __name__ == "__main__":
    main()
