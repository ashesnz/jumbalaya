#!/usr/bin/env python3
"""Build JumbalayaLetters + JumbalayaCardFrame atlases from JumbalayaDeck.png.

Letters: 13×2 grid (A–M row 0, N–Z row 1), full glyph art on transparent.
Frame: single card body with letter removed; grayscale shading for runtime tint.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageChops, ImageFilter

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


def extract_frame(
    cell: Image.Image,
    bg: tuple[int, int, int],
    letter_mask: Image.Image | None = None,
) -> Image.Image:
    """Card body with bevels preserved as grayscale shading for multiply tint."""
    out = Image.new("RGBA", cell.size, (0, 0, 0, 0))
    src = cell.load()
    dst = out.load()
    mask_px = letter_mask.load() if letter_mask is not None else None

    shades: list[float] = []
    for y in range(cell.height):
        for x in range(cell.width):
            r, g, b, a = src[x, y]
            if a < 8 or is_letter_pixel(r, g, b, a, bg):
                continue
            if mask_px and mask_px[x, y] > 48:
                continue
            shades.append(luminance(r, g, b) / 255.0)

    lo = min(shades) if shades else 0.12
    hi = max(shades) if shades else 0.55
    span = max(hi - lo, 0.08)
    body_gray = int(70 + ((sum(shades) / len(shades)) - lo) / span * 185) if shades else 140

    for y in range(cell.height):
        for x in range(cell.width):
            r, g, b, a = src[x, y]
            if a < 8:
                continue
            if mask_px and mask_px[x, y] > 48:
                dst[x, y] = (body_gray, body_gray, body_gray, a)
                continue
            if is_letter_pixel(r, g, b, a, bg):
                continue
            shade = (luminance(r, g, b) / 255.0 - lo) / span
            shade = max(0.0, min(1.0, shade))
            gray = int(70 + shade * 185)
            dst[x, y] = (gray, gray, gray, a)

    return out


def build_letter_zone_mask(
    deck: Image.Image,
    cell_w: int,
    cell_h: int,
    *,
    dilate: int,
) -> Image.Image:
    """Union of every glyph alpha, expanded to cover outline shadows."""
    mask = Image.new("L", (cell_w, cell_h), 0)
    sources = [(col, 0) for col in range(13)] + [(col, 2) for col in range(13)]
    for col, row in sources:
        box = (col * cell_w, row * cell_h, (col + 1) * cell_w, (row + 1) * cell_h)
        cell = deck.crop(box)
        bg = sample_background(cell)
        glyph = extract_glyph(cell, bg)
        alpha = glyph.split()[3]
        mask = ImageChops.lighter(mask, alpha)

    if dilate > 0:
        size = dilate * 2 + 1
        mask = mask.filter(ImageFilter.MaxFilter(size))

    # Every glyph shares the same centre footprint; flatten a generous inner
    # rectangle so baked-in letter shading cannot bleed through the frame.
    zone = Image.new("L", (cell_w, cell_h), 0)
    zx0 = int(cell_w * 0.08)
    zx1 = int(cell_w * 0.92)
    zy0 = int(cell_h * 0.10)
    zy1 = int(cell_h * 0.90)
    for y in range(zy0, zy1):
        for x in range(zx0, zx1):
            zone.putpixel((x, y), 255)
    return ImageChops.lighter(mask, zone)


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
    dilate = 6 if cell_w <= LOGICAL_W else 12
    letter_mask = build_letter_zone_mask(deck, cell_w, cell_h, dilate=dilate)
    return extract_frame(cell, bg, letter_mask)


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
