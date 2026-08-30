#!/usr/bin/env python3
"""Populate resources/textures/1x and 2x from resources/assets (AlphaCards layout).

Run before iOS builds:
  python3 _tools/build_letter_atlas.py
  python3 _tools/sync_texture_scales.py
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "resources" / "assets"
OUT_1X = ROOT / "resources" / "textures" / "1x"
OUT_2X = ROOT / "resources" / "textures" / "2x"

NATIVE_COPY = {
    "PlayingDeck.png",
    "title_garden.png",
    "Marketplace.png",
    "banner.png",
    "coin_stack.png",
    "coin.png",
    "play_icon.png",
    "shuffle_icon.png",
    "remove_placement_icon.png",
    "gamepad_ui.png",
}

LETTER_ATLAS = {
    "JumbalayaLetters.png",
    "JumbalayaCardFrame.png",
}


def run_build_letter_atlas() -> None:
    script = ROOT / "_tools" / "build_letter_atlas.py"
    if script.is_file():
        subprocess.run([sys.executable, str(script)], check=True)


def write_tier(src: Path, dest: Path, size: tuple[int, int] | None) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    img = Image.open(src).convert("RGBA")
    if size:
        img = img.resize(size, Image.Resampling.LANCZOS)
    img.save(dest)
    print(f"  wrote {dest.relative_to(ROOT)} {img.size}")


def sync_file(filename: str) -> None:
    src = ASSETS / filename
    if not src.is_file():
        print(f"  skip missing {filename}")
        return
    if filename in LETTER_ATLAS:
        print(f"  skip {filename} (use build_letter_atlas.py)")
        return

    out2 = OUT_2X / filename
    out1 = OUT_1X / filename
    w, h = Image.open(src).size

    if filename in NATIVE_COPY:
        write_tier(src, out2, None)
        write_tier(src, out1, None)
        return

    write_tier(src, out2, None)
    write_tier(src, out1, (max(1, w // 2), max(1, h // 2)))


def main() -> None:
    print("Building letter atlases…")
    run_build_letter_atlas()
    print("Syncing resources/textures/{1x,2x}…")
    for path in sorted(ASSETS.glob("*.png")):
        sync_file(path.name)
    print("Done.")


if __name__ == "__main__":
    main()
