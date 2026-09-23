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
META_REL=$(sqlite3 "$SQL" "select v from meta where k='release'")
SCHEMA=$(sqlite3 "$SQL" "select v from meta where k='schema'")
PUBS=$(sqlite3 "$SQL" "select v from meta where k='publications'")
[ "$META_REL" = "$REL" ] || { echo "index release $META_REL != $REL"; exit 1; }

echo "== compress"
zstd -19 -T0 --rm -q "$SQL" -o "$ZST" || { zstd -19 -T0 -q "$SQL" -o "$ZST"; rm -f "$SQL"; }
# note: --rm removes the sqlite after compression; we need its sha256 first, so recompute via decompression stream
SQL_SHA=$(zstd -dc "$ZST" | sha256sum | awk '{print $1}')
SQL_SIZE=$(zstd -l "$ZST" 2>/dev/null | awk 'NR==2{print $5}' | tr -d ',')
ZST_SHA=$(sha256sum "$ZST" | awk '{print $1}')
ZST_SIZE=$(stat -c %s "$ZST" 2>/dev/null || stat -f %z "$ZST")
BUILDER=$(pip show mcp-dblp 2>/dev/null | awk '/^Version/{print "mcp-dblp " $2}')

cat > latest.json <<JSON
{
  "schema": $SCHEMA,
  "release": "$REL",
  "file": "$ZST",
  "size": $ZST_SIZE,
  "sha256": "$ZST_SHA",
  "sqlite_size": ${SQL_SIZE:-0},
  "sqlite_sha256": "$SQL_SHA",
  "publications": $PUBS,
  "urls": ["https://github.com/szeider/mcp-dblp-index/releases/download/dblp-$REL/$ZST"],
  "built": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "builder": "${BUILDER:-mcp-dblp}"
}
JSON
cat latest.json
