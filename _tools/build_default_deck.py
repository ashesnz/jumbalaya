#!/usr/bin/env python3
"""Build DefaultDeck 1x/2x PNG spritesheets with transparent gutters.

Source: resources/textures/2x/DefaultDeck.jpeg (or DefaultDeck.png with alpha).
Output: resources/textures/{1,2}x/DefaultDeck.png (+ _opt2 copies).

Grid matches game/prototypes.lua: 13 columns × 4 rows, 71×95 px cells at 1x.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC_JPEG = ROOT / "resources/textures/2x/DefaultDeck.jpeg"
SRC_PNG = ROOT / "resources/textures/2x/DefaultDeck_source.png"
TARGET_2X = (1846, 760)
TARGET_1X = (923, 380)


def key_checkerboard(im: Image.Image) -> Image.Image:
    im = im.convert("RGBA")
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            mx = max(r, g, b)
            mn = min(r, g, b)
            if mx - mn <= 12 and mx >= 175:
                px[x, y] = (r, g, b, 0)
    return im


def main() -> None:
    src = SRC_PNG if SRC_PNG.is_file() else SRC_JPEG
    if not src.is_file():
        raise SystemExit(f"Missing source: {SRC_JPEG} or {SRC_PNG}")

    im = Image.open(src)
    if src.suffix.lower() in {".jpg", ".jpeg"}:
        im = key_checkerboard(im)

    scaled2 = im.resize(TARGET_2X, Image.Resampling.LANCZOS)
    scaled1 = scaled2.resize(TARGET_1X, Image.Resampling.LANCZOS)

    for scale, image in (("2x", scaled2), ("1x", scaled1)):
        out_dir = ROOT / "resources/textures" / scale
        out_dir.mkdir(parents=True, exist_ok=True)
        for name in ("DefaultDeck.png", "DefaultDeck_opt2.png"):
            image.save(out_dir / name)
            print("wrote", out_dir / name)


if __name__ == "__main__":
    main()
