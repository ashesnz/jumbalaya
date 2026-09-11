#!/usr/bin/env python3
"""Split a Lua class file into modules by section comments (---- lines)."""

from __future__ import annotations

import re
import sys
from pathlib import Path


def split_sections(text: str) -> list[tuple[str, str]]:
    lines = text.splitlines()
    header: list[str] = []
    i = 0
    while i < len(lines):
        line = lines[i]
        if line.startswith("function ") or line.startswith("local ") and "Class:extend" in line:
            break
        header.append(line)
        i += 1

    sections: list[tuple[str, str]] = []
    current_name = "core"
    current: list[str] = []
    for line in lines[i:]:
        if re.match(r"^%-{5,}$", line.strip()):
            if current:
                sections.append((current_name, "\n".join(current).rstrip() + "\n"))
                current = []
            continue
        m = re.match(r"^%-+%\s*(.+?)\s*-+%$", line)
        if m:
            current_name = re.sub(r"[^a-z0-9]+", "_", m.group(1).lower()).strip("_") or current_name
            continue
        current.append(line)
    if current:
        sections.append((current_name, "\n".join(current).rstrip() + "\n"))
    return header, sections


def main() -> None:
    if len(sys.argv) < 3:
        print("usage: split_class_module.py <source.lua> <out_dir>")
        sys.exit(1)
    source = Path(sys.argv[1]).read_text(encoding="utf-8")
    out_dir = Path(sys.argv[2])
    out_dir.mkdir(parents=True, exist_ok=True)
    header, sections = split_sections(source)
    class_match = re.search(r"(\w+)\s*=\s*Class:extend\(\)", source)
    class_name = class_match.group(1) if class_match else "Module"
    header_text = "\n".join(header).strip()
    for name, body in sections:
        path = out_dir / f"{name}.lua"
        path.write_text(
            f"{header_text}\n\nreturn function({class_name})\n{body}end\n",
            encoding="utf-8",
        )
        print(f"wrote {path} ({len(body.splitlines())} lines)")


if __name__ == "__main__":
    main()
