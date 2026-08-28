"""Shared helpers for remapping red glyph borders to neutral black shades."""

from __future__ import annotations

from dataclasses import dataclass

from PIL import Image


@dataclass
class BorderRemapConfig:
    """Tune these when the source art or extraction rules change."""

    min_alpha: int = 8
    # Cream letter fill — never remap.
    fill_min_luminance: float = 118.0
    fill_min_green: int = 45
    # Dark red outline / anti-alias fringe.
    max_luminance: float = 118.0
    red_dominance: int = 10  # R must exceed both G and B by at least this much.
    # Output neutral border tone (0–255). Luminance is scaled into this range.
    black_floor: int = 0
    black_ceiling: int = 72
    # Gamma on normalized luminance before mapping to black_ceiling.
    black_gamma: float = 1.0


def luminance(r: int, g: int, b: int) -> float:
    return (r + g + b) / 3.0


def is_letter_fill(r: int, g: int, b: int, cfg: BorderRemapConfig) -> bool:
    return luminance(r, g, b) >= cfg.fill_min_luminance and g >= cfg.fill_min_green


def is_red_border_pixel(r: int, g: int, b: int, a: int, cfg: BorderRemapConfig) -> bool:
    if a < cfg.min_alpha:
        return False
    if is_letter_fill(r, g, b, cfg):
        return False
    lum = luminance(r, g, b)
    if lum > cfg.max_luminance:
        return False
    return r > g + cfg.red_dominance and r > b + cfg.red_dominance


def border_gray(r: int, g: int, b: int, cfg: BorderRemapConfig) -> int:
    """Map a red-dominant pixel to a neutral gray, preserving apparent weight."""
    src = max(r, g, b)
    span = max(1, cfg.black_ceiling - cfg.black_floor)
    norm = max(0.0, min(1.0, src / 255.0))
    if cfg.black_gamma != 1.0:
        norm = norm ** cfg.black_gamma
    return int(round(cfg.black_floor + norm * span))


def remap_pixel(r: int, g: int, b: int, a: int, cfg: BorderRemapConfig) -> tuple[int, int, int, int]:
    if not is_red_border_pixel(r, g, b, a, cfg):
        return r, g, b, a
    gray = border_gray(r, g, b, cfg)
    return gray, gray, gray, a


def remap_image(image: Image.Image, cfg: BorderRemapConfig | None = None) -> tuple[Image.Image, dict[str, int]]:
    cfg = cfg or BorderRemapConfig()
    src = image.convert("RGBA")
    out = Image.new("RGBA", src.size)
    spx = src.load()
    dpx = out.load()
    stats = {"pixels": 0, "remapped": 0}

    for y in range(src.height):
        for x in range(src.width):
            rgba = spx[x, y]
            stats["pixels"] += 1
            nr, ng, nb, na = remap_pixel(*rgba, cfg)
            if (nr, ng, nb) != rgba[:3]:
                stats["remapped"] += 1
            dpx[x, y] = (nr, ng, nb, na)

    return out, stats
