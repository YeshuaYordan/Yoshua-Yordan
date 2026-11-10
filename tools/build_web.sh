#!/usr/bin/env bash
# Build a standalone web zip (for itch.io or any web host) from index.html + characters.js.
# Removes the hooks that only matter on the claude.ai preview page.
# Usage: tools/build_web.sh OUT.zip
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-beanery-web.zip}"
TMP="$(mktemp -d)"
sed -e '/<meta name="claude:viewport-fit-sides"/d' \
    -e '/window\.claude?\.hot?\.snapshot/d' \
    -e 's|  if (window\.claude?\.hot?\.ready) window\.claude\.hot\.ready(boot);|  boot({});|' \
    -e '/  else boot(window\.claude?\.hot?\.data ?? {});/d' \
    index.html > "$TMP/index.html"
cp characters.js "$TMP/characters.js"
if grep -qi 'claude' "$TMP/index.html" "$TMP/characters.js"; then echo "still contains preview hooks" >&2; exit 1; fi
rm -f "$OUT"; (cd "$TMP" && zip -q -r - index.html characters.js) > "$OUT"
rm -rf "$TMP"
echo "built $OUT"
