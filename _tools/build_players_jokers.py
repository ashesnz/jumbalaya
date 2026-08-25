#!/usr/bin/env python3
"""Bake assets/Players.png into the joker atlas grid (1x + 2x).

The game expects a 10×16 grid of 71×95 px cells (same layout as Jokers.png).
Source art is scaled to fit that grid so in-game card size is unchanged.

Run from repo root:
    _tools/.venv/bin/python _tools/build_players_jokers.py

After this, run build_pads_joker.py if Pads cells (0,9)/(1,9) should be restored.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets" / "Players.png"
TEX_1X = ROOT / "resources" / "textures" / "1x"
TEX_2X = ROOT / "resources" / "textures" / "2x"
OUT_1X = TEX_1X / "Players.png"
OUT_2X = TEX_2X / "Players.png"

COLS, ROWS = 10, 16
CELL_W, CELL_H = 71, 95
TARGET_W = COLS * CELL_W
TARGET_H = ROWS * CELL_H


def build() -> None:
    if not SRC.is_file():
        raise FileNotFoundError(f"Missing source art: {SRC}")

    src = Image.open(SRC).convert("RGBA")
    sheet_1x = src.resize((TARGET_W, TARGET_H), Image.Resampling.LANCZOS)
    TEX_1X.mkdir(parents=True, exist_ok=True)
    TEX_2X.mkdir(parents=True, exist_ok=True)
    sheet_1x.save(OUT_1X)

    sheet_2x = sheet_1x.resize((TARGET_W * 2, TARGET_H * 2), Image.Resampling.NEAREST)
    sheet_2x.save(OUT_2X)

    print(f"OK  {SRC.name} -> {OUT_1X.name} ({TARGET_W}x{TARGET_H}, {CELL_W}x{CELL_H} cells)")
    print(f"    {OUT_2X.name} ({TARGET_W * 2}x{TARGET_H * 2})")


if __name__ == "__main__":
    build()
