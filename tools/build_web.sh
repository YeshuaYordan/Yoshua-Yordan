#!/usr/bin/env bash
# Build a standalone web zip (for itch.io or any web host) from index.html + characters.js.
# Usage: tools/build_web.sh OUT.zip
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-beanery-web.zip}"
rm -f "$OUT"
zip -q -j "$OUT" index.html characters.js
echo "built $OUT"
