#!/usr/bin/env python3
"""Build Tokens 1x/2x PNG with transparent background from Tokens.jpeg."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "resources/textures/2x/Tokens.jpeg"
MAX_2X_WIDTH = 280


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


def crop_alpha(im: Image.Image, pad: int = 4) -> Image.Image:
    bbox = im.getbbox()
    if not bbox:
        return im
    x0, y0, x1, y1 = bbox
    x0 = max(0, x0 - pad)
    y0 = max(0, y0 - pad)
    x1 = min(im.width, x1 + pad)
    y1 = min(im.height, y1 + pad)
    return im.crop((x0, y0, x1, y1))


def scale_to_width(im: Image.Image, width: int) -> Image.Image:
    if im.width <= width:
        return im
    height = max(1, round(im.height * width / im.width))
    return im.resize((width, height), Image.Resampling.LANCZOS)


def main() -> None:
    if not SRC.is_file():
        raise SystemExit(f"Missing source: {SRC}")

    im = key_checkerboard(Image.open(SRC))
    im = crop_alpha(im)
    im2 = scale_to_width(im, MAX_2X_WIDTH)
    im1 = im2.resize(
        (max(1, im2.width // 2), max(1, im2.height // 2)),
        Image.Resampling.LANCZOS,
    )

    for scale, image in (("2x", im2), ("1x", im1)):
        out_dir = ROOT / "resources/textures" / scale
        out_dir.mkdir(parents=True, exist_ok=True)
        out = out_dir / "Tokens.png"
        image.save(out)
        print("wrote", out, image.size)


if __name__ == "__main__":
    main()
