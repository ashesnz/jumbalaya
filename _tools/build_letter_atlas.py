#!/usr/bin/env python3
"""Build JumbalayaLetters + JumbalayaCardFrame atlases from source deck art.

Source: assets/JumbalayaDeck.jpg (13×4 card grid). Letters: 13×2 grid (A–M row 0,
N–Z row 1), full glyph art on transparent. Frame: white card silhouette for runtime tint.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageChops, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
LOGICAL_W = 71
LOGICAL_H = 95

# Canonical default face colour for the starter deck (Jumbalaya deck red).
DECK_RED_RGBA = (126 / 255.0, 16 / 255.0, 17 / 255.0, 1.0)  # #7e1011
# Marketplace modify transform target colour.
MODIFIED_FACE_RGBA = (22 / 255.0, 21 / 255.0, 26 / 255.0, 1.0)  # #16151a


def cell_size(scale: str) -> tuple[int, int]:
    factor = 1 if scale == "1x" else 2
    return LOGICAL_W * factor, LOGICAL_H * factor


# Sampled from black row of JumbalayaDeck (row 3); kept fixed after deck PNG removal.
DECK_BLACK_RGBA = (0.086275, 0.082353, 0.101961, 1.0)


def deck_grid_size(scale: str) -> tuple[int, int]:
    cell_w, cell_h = cell_size(scale)
    return cell_w * 13, cell_h * 4


def load_deck(scale: str) -> Image.Image:
    cell_w, cell_h = cell_size(scale)
    target_w, target_h = deck_grid_size(scale)
    for path in (
        ROOT / "resources/textures" / scale / "JumbalayaDeck.png",
        ROOT / "assets" / "JumbalayaDeck.jpg",
    ):
        if not path.is_file():
            continue
        img = Image.open(path).convert("RGBA")
        if img.size != (target_w, target_h):
            img = img.resize((target_w, target_h), Image.Resampling.LANCZOS)
        return img
    raise SystemExit(
        f"Missing deck source art for {scale}: expected JumbalayaDeck.png or assets/JumbalayaDeck.jpg"
    )


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
    """Card silhouette filled with white for an exact runtime face tint."""
    del bg, letter_mask  # Silhouette only; colour comes from the palette at draw time.
    out = Image.new("RGBA", cell.size, (0, 0, 0, 0))
    src = cell.load()
    dst = out.load()

    for y in range(cell.height):
        for x in range(cell.width):
            _r, _g, _b, a = src[x, y]
            if a < 128:
                continue
            dst[x, y] = (255, 255, 255, a)

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
    return extract_frame(cell, (0, 0, 0), None)


def sample_face_fill(cell: Image.Image, bg: tuple[int, int, int]) -> tuple[float, float, float, float]:
    px = cell.load()
    rs = gs = bs = 0
    count = 0
    for y in range(cell.height):
        for x in range(cell.width):
            r, g, b, a = px[x, y]
            if a < 128:
                continue
            lum = luminance(r, g, b)
            if lum > 95 or is_letter_pixel(r, g, b, a, bg):
                continue
            if 45 < lum < 70:
                rs += r
                gs += g
                bs += b
                count += 1
    if count == 0:
        return (bg[0] / 255.0, bg[1] / 255.0, bg[2] / 255.0, 1.0)
    return (rs / count / 255.0, gs / count / 255.0, bs / count / 255.0, 1.0)


def deck_face_colors() -> dict[str, tuple[float, float, float, float]]:
    return {
        "red": DECK_RED_RGBA,
        "black": DECK_BLACK_RGBA,
        "modified": MODIFIED_FACE_RGBA,
    }


def sample_deck_face_colors(scale: str) -> dict[str, tuple[float, float, float, float]]:
    del scale  # colours are fixed; deck art is only used for glyph/frame atlases
    return deck_face_colors()


def write_face_colors_lua(colors: dict[str, tuple[float, float, float, float]]) -> None:
    path = ROOT / "word_game/config/deck_face_colors.lua"
    lines = [
        "-- Generated by _tools/build_letter_atlas.py — do not edit by hand.",
        "-- Default red is fixed at #7e1011; modified is #16151a; black is fixed from legacy deck art.",
        "return {",
    ]
    r, g, b, a = DECK_RED_RGBA
    lines.append(f'    red = {{ {r:.6f}, {g:.6f}, {b:.6f}, {a:.1f} }},')
    mr, mg, mb, ma = MODIFIED_FACE_RGBA
    lines.append(f'    modified = {{ {mr:.6f}, {mg:.6f}, {mb:.6f}, {ma:.1f} }},')
    br, bg, bb, ba = colors["black"]
    lines.append(f'    black = {{ {br:.6f}, {bg:.6f}, {bb:.6f}, {ba:.1f} }},')
    lines.append("}")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("wrote", path)


def validate_frame(frame: Image.Image) -> None:
    """Reject a solid rectangle; the frame must keep rounded-corner transparency."""
    px = frame.load()
    w, h = frame.size
    corners = ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1))
    if any(px[x, y][3] > 32 for x, y in corners):
        raise SystemExit(
            "JumbalayaCardFrame has opaque corners (solid rectangle). "
            "Restore deck source art or keep the committed frame PNG."
        )
    transparent = sum(1 for y in range(h) for x in range(w) if px[x, y][3] < 32)
    if transparent < 32:
        raise SystemExit("JumbalayaCardFrame has too few transparent pixels; check source art.")


def validate_letters(letters: Image.Image, cell_w: int, cell_h: int) -> None:
    """Glyphs must be transparent outside the card body; no baked card background rows."""
    cols, rows = letters.width // cell_w, letters.height // cell_h
    for row in range(rows):
        for col in range(cols):
            cell = letters.crop((col * cell_w, row * cell_h, (col + 1) * cell_w, (row + 1) * cell_h))
            px = cell.load()
            for y in range(min(3, cell_h)):
                if sum(1 for x in range(cell_w) if px[x, y][3] > 32) >= cell_w - 2:
                    raise SystemExit(
                        "JumbalayaLetters includes a full-width background row near the top. "
                        "Glyphs must be letter art only; card colour comes from JumbalayaCardFrame."
                    )


def write_atlases(scale: str) -> None:
    cell_w, cell_h = cell_size(scale)
    deck = load_deck(scale)
    out_dir = ROOT / "resources/textures" / scale
    out_dir.mkdir(parents=True, exist_ok=True)

    letters = build_letters(deck, cell_w, cell_h)
    frame = build_frame(deck, cell_w, cell_h)
    validate_frame(frame)
    validate_letters(letters, cell_w, cell_h)

    letters_path = out_dir / "JumbalayaLetters.png"
    frame_path = out_dir / "JumbalayaCardFrame.png"
    letters.save(letters_path)
    frame.save(frame_path)
    print("wrote", letters_path, letters.size)
    print("wrote", frame_path, frame.size)


def main() -> None:
    write_face_colors_lua(sample_deck_face_colors("1x"))
    for scale in ("1x", "2x"):
        write_atlases(scale)


if __name__ == "__main__":
    main()
