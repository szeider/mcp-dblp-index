#!/usr/bin/env bash
# Build one dblp index release: download dump, build sqlite, compress, write manifest.
# Usage: scripts/build_release.sh YYYY-MM-01 OUTDIR   (needs mcp-dblp-index, zstd, curl)
set -euo pipefail
REL="$1"; OUT="$2"; mkdir -p "$OUT"; cd "$OUT"
YEAR="${REL%%-*}"
BASE="https://drops.dagstuhl.de/storage/artifacts/dblp/xml/$YEAR"
DUMP="dblp-$REL.xml.gz"; SQL="dblp-$REL.sqlite"; ZST="$SQL.zst"
UA="mcp-dblp-index-builder (https://github.com/szeider/mcp-dblp-index)"

echo "== download $DUMP"
curl -sSfL -A "$UA" -o "$DUMP.md5" "$BASE/$DUMP.md5"
curl -sSfL -A "$UA" -o "$DUMP" "$BASE/$DUMP"
EXPECTED=$(awk '{print $1}' "$DUMP.md5"); ACTUAL=$(md5sum "$DUMP" | awk '{print $1}')
[ "$EXPECTED" = "$ACTUAL" ] || { echo "md5 mismatch: $EXPECTED != $ACTUAL"; exit 1; }

echo "== build $SQL"
mcp-dblp-index build-file "$DUMP" "$SQL"
rm -f "$DUMP" "$DUMP.md5"

"$(dirname "$0")/package_release.sh" "$REL" "$OUT"
rm -f "$SQL"

