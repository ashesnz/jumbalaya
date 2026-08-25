#!/usr/bin/env bash
# Package Jumbalaya into a .love zip for iOS (or desktop) LÖVE players.
set -euo pipefail

usage() {
	echo "Usage: $0 [game_root] [output.love]" >&2
	echo "  Defaults: game_root=repo root, output=./Jumbalaya.love" >&2
	exit 1
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
default_root="$(cd "${script_dir}/../.." && pwd)"

game_root="${1:-${default_root}}"
output="${2:-${game_root}/Jumbalaya.love}"

if [[ ! -f "${game_root}/main.lua" ]]; then
	echo "error: main.lua not found in ${game_root}" >&2
	exit 1
fi

tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT

out_dir="$(dirname "${output}")"
mkdir -p "${out_dir}"

(
	cd "${game_root}"
	zip -9 -q -r "${tmp}/game.love" . \
		-x "*.git/*" \
		-x ".git/*" \
		-x "tests/*" \
		-x "docs/*" \
		-x "_tools/*" \
		-x "tools/*" \
		-x ".idea/*" \
		-x ".junie/*" \
		-x "AlphaCardsBackup/*" \
		-x "dice-have-no-eyes/*" \
		-x "build/*" \
		-x "dist/*" \
		-x "*.love" \
		-x "*.log" \
		-x "error-output.txt" \
		-x ".DS_Store"
)

mv "${tmp}/game.love" "${output}"
echo "Wrote ${output} ($(du -h "${output}" | cut -f1))"
