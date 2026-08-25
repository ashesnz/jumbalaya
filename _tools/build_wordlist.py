#!/usr/bin/env python3
"""Build Jumbalaya dictionary assets from SCOWL/ESDB (en-wl/wordlist).

Run once (or when refreshing the word list):
    python3 _tools/build_wordlist.py

Outputs:
    resources/dictionary/wordlist.txt   filtered plain-text word list (uppercase)
    dictionary/words_set.lua            O(1) exact-match hash set
    resources/dictionary/COPYING.txt    SCOWL/ESDB license notice

The game loads words_set.lua at runtime and builds an in-memory trie once on
Dictionary.load() (Lua cannot load a pre-serialized trie table at this scale).
"""

from __future__ import annotations

import argparse
import subprocess
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CACHE = ROOT / "_tools" / ".cache"
SCOWL_REPO = CACHE / "en-wl-wordlist"
NORVIG_URL = "https://norvig.com/ngrams/count_1w.txt"
NORVIG_CACHE = CACHE / "norvig_count_1w.txt"

OUT_TXT = ROOT / "resources" / "dictionary" / "wordlist.txt"
OUT_SET = ROOT / "dictionary" / "words_set.lua"
OUT_COPY = ROOT / "resources/dictionary/COPYING.txt"

SCOWL_COPY = """Jumbalaya word list derived from the English Speller Database (ESDB),
formerly SCOWL, by Kevin Atkinson et al.

Source: https://github.com/en-wl/wordlist
License: MIT-like (see SCOWL Copyright file in the ESDB repository)

Filtered for conversational American English (length 2–7):
  - SCOWL size 60, abbreviations and proper nouns excluded
  - Two-letter words: strict conversational whitelist only
  - Three- to seven-letter words: must appear in Norvig frequency corpus

Frequency data: Peter Norvig's count_1w.txt (public domain).
"""

MIN_WORD_LEN = 2
MAX_WORD_LEN = 7

# Conversational two-letter words only — no state codes (CA, DE), media (TV), etc.
TWO_LETTER_WHITELIST = frozenset({
    "am", "an", "as", "at", "be", "by", "do", "go", "he", "hi", "if", "in", "is", "it",
    "me", "my", "no", "of", "oh", "on", "or", "ox", "so", "to", "up", "us", "we",
})

# ESDB pos-classes for proper nouns / place names / company names (see en-wl/wordlist docs).
POS_CLASSES_EXCLUDE = "person,surname,name,place,company,upper,name?,upper?"


def ensure_scowl_repo() -> Path:
    if (SCOWL_REPO / "scowl.db").exists():
        return SCOWL_REPO
    if not SCOWL_REPO.exists():
        CACHE.mkdir(parents=True, exist_ok=True)
        subprocess.check_call(
            ["git", "clone", "--depth", "1", "--branch", "v2",
             "https://github.com/en-wl/wordlist.git", str(SCOWL_REPO)],
        )
    db = SCOWL_REPO / "scowl.db"
    if not db.exists():
        subprocess.check_call(["make", "scowl.db"], cwd=SCOWL_REPO)
    return SCOWL_REPO


def ensure_norvig_freq() -> dict[str, int]:
    if not NORVIG_CACHE.exists():
        CACHE.mkdir(parents=True, exist_ok=True)
        print(f"Downloading frequency list from {NORVIG_URL}")
        data = urllib.request.urlopen(NORVIG_URL, timeout=60).read().decode("utf-8", errors="ignore")
        NORVIG_CACHE.write_text(data, encoding="utf-8")
    freq: dict[str, int] = {}
    for line in NORVIG_CACHE.read_text(encoding="utf-8").splitlines():
        parts = line.split("\t")
        if len(parts) == 2:
            freq[parts[0].lower()] = int(parts[1])
    return freq


def extract_scowl_words(repo: Path, size: int) -> set[str]:
    cmd = [
        "./scowl", "--db", "scowl.db", "word-list",
        str(size), "A", "1",
        "--deaccent",
        "--wo-poses", "abbr",
        "--wo-pos-classes", POS_CLASSES_EXCLUDE,
    ]
    raw = subprocess.check_output(cmd, cwd=repo, text=True, stderr=subprocess.DEVNULL)
    words: set[str] = set()
    for line in raw.splitlines():
        w = line.strip().lower()
        if MIN_WORD_LEN <= len(w) <= MAX_WORD_LEN and w.isalpha():
            words.add(w)
    return words


def finalize_word_list(words: set[str], freq: dict[str, int]) -> list[str]:
    """Apply conversational filters: whitelist 2-letter; corpus-backed 3–7 letter."""
    kept: list[str] = []
    dropped_two = 0
    dropped_freq = 0

    for w in words:
        if len(w) == 2:
            if w in TWO_LETTER_WHITELIST:
                kept.append(w)
            else:
                dropped_two += 1
        elif freq.get(w, 0) > 0:
            kept.append(w)
        else:
            dropped_freq += 1

    print(f"  dropped {dropped_two} two-letter abbreviations/non-words")
    print(f"  dropped {dropped_freq} words with no corpus frequency")
    return sorted(set(kept))


def write_words_set(path: Path, words: list[str]) -> None:
    chunks = ["return {"]
    for w in words:
        chunks.append(f"  {w.upper()} = true,")
    chunks.append("}")
    path.write_text("\n".join(chunks) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Build Jumbalaya dictionary assets")
    parser.add_argument("--size", type=int, default=60, help="ESDB size tier (default 60)")
    parser.add_argument("--skip-clone", action="store_true", help="Do not clone/build SCOWL if missing")
    args = parser.parse_args()

    if args.skip_clone and not (SCOWL_REPO / "scowl.db").exists():
        print("scowl.db not found; run without --skip-clone first", file=sys.stderr)
        return 1

    repo = ensure_scowl_repo()
    print(f"Extracting ESDB size {args.size} (American English, no abbr/proper nouns)...")
    words = extract_scowl_words(repo, args.size)
    print(f"  {len(words):,} words with {MIN_WORD_LEN}–{MAX_WORD_LEN} letters from SCOWL")

    freq = ensure_norvig_freq()
    words_list = finalize_word_list(words, freq)
    by_len = {}
    for w in words_list:
        by_len[len(w)] = by_len.get(len(w), 0) + 1
    print(f"  {len(words_list):,} words in final list ({by_len})")

    OUT_TXT.parent.mkdir(parents=True, exist_ok=True)
    OUT_COPY.write_text(SCOWL_COPY, encoding="utf-8")
    OUT_TXT.write_text("\n".join(w.upper() for w in words_list) + "\n", encoding="utf-8")
    write_words_set(OUT_SET, words_list)

    print(f"Wrote {OUT_TXT}")
    print(f"Wrote {OUT_SET} ({OUT_SET.stat().st_size:,} bytes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
