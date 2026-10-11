#!/usr/bin/env bash
# Print the file name of the month's dump on Dagstuhl DROPS, e.g. dblp-2026-10-03.xml.gz.
# Usage: scripts/find_dump.sh YYYY-MM-01   (exit 1 if DROPS has no dump for that month)
#
# Releases are labelled by month (YYYY-MM-01, what mcp-dblp 2.0.x clients accept), but
# DROPS does not always date the dump the 1st: October 2026 is dblp-2026-10-03.xml.gz.
# Probe the .md5 of every day, latest first.
set -euo pipefail
REL="$1"; MONTH="${REL%-*}"; YEAR="${REL%%-*}"
BASE="https://drops.dagstuhl.de/storage/artifacts/dblp/xml/$YEAR"
UA="mcp-dblp-index-builder (https://github.com/szeider/mcp-dblp-index)"
for d in $(seq -w 31 -1 1); do
  f="dblp-$MONTH-$d.xml.gz"
  if curl -sfI -A "$UA" -o /dev/null "$BASE/$f.md5"; then echo "$f"; exit 0; fi
done
exit 1
