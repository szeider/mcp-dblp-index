#!/usr/bin/env bash
# Package an existing index: OUTDIR/dblp-REL.sqlite -> dblp-REL.sqlite.zst + latest.json
# Usage: scripts/package_release.sh YYYY-MM-01 OUTDIR   (needs zstd, sqlite3)
set -euo pipefail
REL="$1"; OUT="$2"; cd "$OUT"
SQL="dblp-$REL.sqlite"; ZST="$SQL.zst"
META_REL=$(sqlite3 "$SQL" "select v from meta where k='release'")
SCHEMA=$(sqlite3 "$SQL" "select v from meta where k='schema'")
PUBS=$(sqlite3 "$SQL" "select v from meta where k='publications'")
[ "$META_REL" = "$REL" ] || { echo "index release $META_REL != $REL"; exit 1; }
SQL_SIZE=$(stat -c %s "$SQL" 2>/dev/null || stat -f %z "$SQL")
SQL_SHA=$(sha256sum "$SQL" 2>/dev/null | awk '{print $1}' || shasum -a 256 "$SQL" | awk '{print $1}')
[ -n "$SQL_SHA" ] || SQL_SHA=$(shasum -a 256 "$SQL" | awk '{print $1}')
if [ -s "$ZST" ] && [ "$ZST" -nt "$SQL" ] && zstd -tq "$ZST"; then
  echo "== reuse existing $ZST"
else
  echo "== compress $SQL ($SQL_SIZE bytes)"
  zstd -19 -T0 -q -f "$SQL" -o "$ZST"
fi
ZST_SIZE=$(stat -c %s "$ZST" 2>/dev/null || stat -f %z "$ZST")
ZST_SHA=$(sha256sum "$ZST" 2>/dev/null | awk '{print $1}' || shasum -a 256 "$ZST" | awk '{print $1}')
[ -n "$ZST_SHA" ] || ZST_SHA=$(shasum -a 256 "$ZST" | awk '{print $1}')
BUILDER="mcp-dblp $(python3 -c 'import importlib.metadata as m; print(m.version("mcp-dblp"))' 2>/dev/null || echo unknown)"
cat > latest.json <<JSON
{
  "schema": $SCHEMA,
  "release": "$REL",
  "file": "$ZST",
  "size": $ZST_SIZE,
  "sha256": "$ZST_SHA",
  "sqlite_size": $SQL_SIZE,
  "sqlite_sha256": "$SQL_SHA",
  "publications": $PUBS,
  "urls": ["https://github.com/szeider/mcp-dblp-index/releases/download/dblp-$REL/$ZST"],
  "built": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "builder": "$BUILDER"
}
JSON
cat latest.json
