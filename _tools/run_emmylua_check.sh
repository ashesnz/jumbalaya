#!/usr/bin/env bash
# Install (if needed) and run emmylua_check locally. Matches CI version in .github/workflows/tests.yml.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${EMMYLUA_CHECK_VERSION:-0.25.1}"
SEVERITY="${1:-warn}"
export PATH="${HOME}/.cargo/bin:${PATH}"

if ! command -v emmylua_check >/dev/null 2>&1; then
  echo "Installing emmylua_check ${VERSION}..."
  cargo install emmylua_check --version "${VERSION}" --locked
fi

cd "$ROOT"
echo "Running emmylua_check . --severity ${SEVERITY}"
emmylua_check . --severity "${SEVERITY}"
