#!/usr/bin/env python3
"""Build JumbalayaLetters + JumbalayaCardFrame atlases from JumbalayaDeck.png.

Letters: 13×2 grid (A–M row 0, N–Z row 1), full glyph art on transparent.
Frame: single card body with letter removed; grayscale shading for runtime tint.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
LOGICAL_W = 71
LOGICAL_H = 95


def cell_size(scale: str) -> tuple[int, int]:
    factor = 1 if scale == "1x" else 2
    return LOGICAL_W * factor, LOGICAL_H * factor


def load_deck(scale: str) -> Image.Image:
    path = ROOT / "resources/textures" / scale / "JumbalayaDeck.png"
    if not path.is_file():
        raise SystemExit(f"Missing deck atlas: {path}")
    return Image.open(path).convert("RGBA")


def luminance(r: int, g: int, b: int) -> float:
    return (r + g + b) / 3.0


def color_dist(a: tuple[int, int, int], b: tuple[int, int, int]) -> float:
    return abs(a[0] - b[0]) + abs(a[1] - b[1]) + abs(a[2] - b[2])


def sample_background(cell: Image.Image) -> tuple[int, int, int]:
    px = cell.load()
    w, h = cell.size
    samples: list[tuple[int, int, int]] = []
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < 128:
                continue
            lum = luminance(r, g, b)
            if lum > 95:
                continue
            samples.append((r, g, b))
    if not samples:
        return (126, 16, 15)
    r = sum(s[0] for s in samples) // len(samples)
    g = sum(s[1] for s in samples) // len(samples)
    b = sum(s[2] for s in samples) // len(samples)
    return (r, g, b)


def is_letter_pixel(r: int, g: int, b: int, a: int, bg: tuple[int, int, int]) -> bool:
    if a < 8:
        return False
    lum = luminance(r, g, b)
    # Cream fill and rim highlights on the glyph.
    if lum >= 118 and g >= 45:
        return True
    # Dark outline strokes around the glyph (not the flat card body).
    if lum <= 62 and color_dist((r, g, b), bg) >= 28:
        return True
    # Anti-aliased fringe between fill and body.
    if lum > 62 and lum < 118 and g >= 35 and color_dist((r, g, b), bg) >= 40:
        return True
    return False


def extract_glyph(cell: Image.Image, bg: tuple[int, int, int]) -> Image.Image:
    out = Image.new("RGBA", cell.size, (0, 0, 0, 0))
    src = cell.load()
    dst = out.load()
    for y in range(cell.height):
        for x in range(cell.width):
            r, g, b, a = src[x, y]
            if not is_letter_pixel(r, g, b, a, bg):
                continue
            dst[x, y] = (r, g, b, a)
    return out


def extract_frame(cell: Image.Image, bg: tuple[int, int, int]) -> Image.Image:
    """Card body with bevels preserved as grayscale shading for multiply tint."""
    out = Image.new("RGBA", cell.size, (0, 0, 0, 0))
    src = cell.load()
    dst = out.load()

    shades: list[float] = []
    for y in range(cell.height):
        for x in range(cell.width):
            r, g, b, a = src[x, y]
            if a < 8 or is_letter_pixel(r, g, b, a, bg):
                continue
            shades.append(luminance(r, g, b) / 255.0)

    lo = min(shades) if shades else 0.12
    hi = max(shades) if shades else 0.55
    span = max(hi - lo, 0.08)

    for y in range(cell.height):
        for x in range(cell.width):
            r, g, b, a = src[x, y]
            if a < 8 or is_letter_pixel(r, g, b, a, bg):
                continue
            shade = (luminance(r, g, b) / 255.0 - lo) / span
            shade = max(0.0, min(1.0, shade))
            # Keep corner bevels bright; body stays in the mid range.
            gray = int(70 + shade * 185)
            dst[x, y] = (gray, gray, gray, a)

    return out


def build_letters(deck: Image.Image, cell_w: int, cell_h: int) -> Image.Image:
    cols, rows = 13, 2
    sheet = Image.new("RGBA", (cols * cell_w, rows * cell_h), (0, 0, 0, 0))

    sources = [(0, 0), (2, 1)]  # deck row, sheet row
    for deck_row, sheet_row in sources:
        for col in range(cols):
            box = (
                col * cell_w,
                deck_row * cell_h,
                (col + 1) * cell_w,
                (deck_row + 1) * cell_h,
            )
            cell = deck.crop(box)
            bg = sample_background(cell)
            glyph = extract_glyph(cell, bg)
            sheet.paste(glyph, (col * cell_w, sheet_row * cell_h))

    return sheet


def build_frame(deck: Image.Image, cell_w: int, cell_h: int) -> Image.Image:
    cell = deck.crop((0, 0, cell_w, cell_h))
    bg = sample_background(cell)
    return extract_frame(cell, bg)


def write_atlases(scale: str) -> None:
    cell_w, cell_h = cell_size(scale)
    deck = load_deck(scale)
    out_dir = ROOT / "resources/textures" / scale
    out_dir.mkdir(parents=True, exist_ok=True)

    letters = build_letters(deck, cell_w, cell_h)
    frame = build_frame(deck, cell_w, cell_h)

    letters_path = out_dir / "JumbalayaLetters.png"
    frame_path = out_dir / "JumbalayaCardFrame.png"
    letters.save(letters_path)
    frame.save(frame_path)
    print("wrote", letters_path, letters.size)
    print("wrote", frame_path, frame.size)


def main() -> None:
    for scale in ("1x", "2x"):
        write_atlases(scale)


if __name__ == "__main__":
    main()
