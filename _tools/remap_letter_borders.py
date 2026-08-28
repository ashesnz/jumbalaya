#!/usr/bin/env python3
"""Remap red glyph borders in JumbalayaLetters.png to neutral black shades.

The letter atlas keeps cream/white fill pixels untouched and converts
red-dominant outline / anti-alias pixels to grayscale.

Examples:
  python _tools/remap_letter_borders.py
  python _tools/remap_letter_borders.py --dry-run
  python _tools/remap_letter_borders.py --black-ceiling 90 --red-dominance 8
  python _tools/remap_letter_borders.py --input resources/textures/1x/JumbalayaLetters.png
"""

from __future__ import annotations

import argparse
import shutil
import sys
from pathlib import Path

from PIL import Image

TOOLS_DIR = Path(__file__).resolve().parent
if str(TOOLS_DIR) not in sys.path:
    sys.path.insert(0, str(TOOLS_DIR))

from letter_border_remap import BorderRemapConfig, remap_image

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_PATHS = (
    ROOT / "resources/textures/1x/JumbalayaLetters.png",
    ROOT / "resources/textures/2x/JumbalayaLetters.png",
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--input",
        type=Path,
        action="append",
        help="PNG to process (default: both 1x and 2x JumbalayaLetters.png)",
    )
    parser.add_argument(
        "--output",
        type=Path,
        help="Optional output path (only valid with a single --input)",
    )
    parser.add_argument(
        "--backup",
        action="store_true",
        help="Write a .bak copy beside each source file before overwriting",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print remap stats without writing files",
    )
    parser.add_argument("--red-dominance", type=int, default=10)
    parser.add_argument("--max-luminance", type=float, default=118.0)
    parser.add_argument("--fill-min-luminance", type=float, default=118.0)
    parser.add_argument("--fill-min-green", type=int, default=45)
    parser.add_argument("--black-floor", type=int, default=0)
    parser.add_argument("--black-ceiling", type=int, default=72)
    parser.add_argument("--black-gamma", type=float, default=1.0)
    return parser.parse_args()


def build_config(args: argparse.Namespace) -> BorderRemapConfig:
    return BorderRemapConfig(
        red_dominance=args.red_dominance,
        max_luminance=args.max_luminance,
        fill_min_luminance=args.fill_min_luminance,
        fill_min_green=args.fill_min_green,
        black_floor=args.black_floor,
        black_ceiling=args.black_ceiling,
        black_gamma=args.black_gamma,
    )


def process_file(path: Path, cfg: BorderRemapConfig, *, output: Path | None, backup: bool, dry_run: bool) -> None:
    if not path.is_file():
        raise SystemExit(f"Missing input: {path}")

    image = Image.open(path)
    remapped, stats = remap_image(image, cfg)
    pct = (100.0 * stats["remapped"] / stats["pixels"]) if stats["pixels"] else 0.0
    print(f"{path}: remapped {stats['remapped']:,} / {stats['pixels']:,} pixels ({pct:.2f}%)")

    if dry_run:
        return

    dest = output or path
    if dest == path and backup:
        backup_path = path.with_suffix(path.suffix + ".bak")
        shutil.copy2(path, backup_path)
        print(f"  backup -> {backup_path}")

    dest.parent.mkdir(parents=True, exist_ok=True)
    remapped.save(dest)
    print(f"  wrote -> {dest}")


def main() -> None:
    args = parse_args()
    cfg = build_config(args)
    inputs = args.input or list(DEFAULT_PATHS)

    if args.output and len(inputs) != 1:
        raise SystemExit("--output requires exactly one --input")

    for path in inputs:
        process_file(path, cfg, output=args.output, backup=args.backup, dry_run=args.dry_run)


if __name__ == "__main__":
    main()
