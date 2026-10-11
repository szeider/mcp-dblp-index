#!/usr/bin/env bash
# Build one dblp index release: download dump, build sqlite, compress, write manifest.
# Usage: scripts/build_release.sh YYYY-MM-01 OUTDIR   (needs mcp-dblp-index, zstd, curl)
# The release is labelled by month (YYYY-MM-01); the dump is whatever file DROPS
# published for that month (find_dump.sh), saved under the label's name, so that the
# index, its file names and latest.json all carry YYYY-MM-01. OUTDIR/SOURCE names it.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REL="$1"; OUT="$2"; mkdir -p "$OUT"; cd "$OUT"
YEAR="${REL%%-*}"
BASE="https://drops.dagstuhl.de/storage/artifacts/dblp/xml/$YEAR"
DUMP="dblp-$REL.xml.gz"; SQL="dblp-$REL.sqlite"
UA="mcp-dblp-index-builder (https://github.com/szeider/mcp-dblp-index)"
SRC=$("$HERE/find_dump.sh" "$REL") || { echo "no dump for $REL on DROPS"; exit 1; }
echo "$SRC" > SOURCE

echo "== download $SRC as $DUMP"
curl -sSfL -A "$UA" -o "$DUMP.md5" "$BASE/$SRC.md5"
curl -sSfL -A "$UA" -o "$DUMP" "$BASE/$SRC"
EXPECTED=$(awk '{print $1}' "$DUMP.md5"); ACTUAL=$(md5sum "$DUMP" | awk '{print $1}')
[ "$EXPECTED" = "$ACTUAL" ] || { echo "md5 mismatch: $EXPECTED != $ACTUAL"; exit 1; }

echo "== build $SQL"
mcp-dblp-index build-file "$DUMP" "$SQL"
rm -f "$DUMP" "$DUMP.md5"

"$HERE/package_release.sh" "$REL" "$OUT"
rm -f "$SQL"
