#!/usr/bin/env python3
"""Build ui_assets 1x/2x JPEG spritesheets from ui_assets.jpeg at fixed atlas size."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "resources/textures/2x/ui_assets.jpeg"
TARGET_2X = (144, 72)
TARGET_1X = (72, 36)


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
                px[x, y] = (0, 0, 0, 0)
    return im


def crop_alpha(im: Image.Image, pad: int = 2) -> Image.Image:
    bbox = im.getbbox()
    if not bbox:
        return im
    x0, y0, x1, y1 = bbox
    x0 = max(0, x0 - pad)
    y0 = max(0, y0 - pad)
    x1 = min(im.width, x1 + pad)
    y1 = min(im.height, y1 + pad)
    return im.crop((x0, y0, x1, y1))


def fit_to_size(im: Image.Image, size: tuple[int, int]) -> Image.Image:
    tw, th = size
    scale = min(tw / im.width, th / im.height)
    nw = max(1, round(im.width * scale))
    nh = max(1, round(im.height * scale))
    resized = im.resize((nw, nh), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    ox = (tw - nw) // 2
    oy = (th - nh) // 2
    canvas.paste(resized, (ox, oy), resized)
    return canvas


def save_outputs(scale: str, image: Image.Image) -> None:
    out_dir = ROOT / "resources/textures" / scale
    out_dir.mkdir(parents=True, exist_ok=True)
    rgb = Image.new("RGB", image.size, (0, 0, 0))
    rgb.paste(image, mask=image.split()[3])
    for name in ("ui_assets.jpeg", "ui_assets_opt2.jpeg"):
        path = out_dir / name
        rgb.save(path, quality=95)
        print("wrote", path, image.size)
    for name in ("ui_assets.png", "ui_assets_opt2.png"):
        path = out_dir / name
        image.save(path)
        print("wrote", path, image.size)


def main() -> None:
    if not SRC.is_file():
        raise SystemExit(f"Missing source: {SRC}")

    im = key_checkerboard(Image.open(SRC))
    im = crop_alpha(im)
    save_outputs("2x", fit_to_size(im, TARGET_2X))
    save_outputs("1x", fit_to_size(im, TARGET_1X))


if __name__ == "__main__":
    main()
