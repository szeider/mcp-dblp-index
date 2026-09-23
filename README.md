# mcp-dblp-index

Prebuilt SQLite index of the [DBLP](https://dblp.org) computer science bibliography, for
[mcp-dblp](https://github.com/szeider/mcp-dblp). A new release is built from each monthly DBLP
XML dump (published under CC0 on [Dagstuhl DROPS](https://drops.dagstuhl.de/entities/collection/10.4230/dblp.xml)).

- Release tag: `dblp-YYYY-MM-01` (the dump's release date)
- Assets: `dblp-YYYY-MM-01.sqlite.zst` (zstd -19, about 1.3 GB; 4.2 GB decompressed) and `latest.json`
- Stable manifest URL: `https://github.com/szeider/mcp-dblp-index/releases/latest/download/latest.json`

`mcp-dblp` downloads the current index on first start (`mcp-dblp-index fetch`). To build the index
yourself from the dump instead, run `mcp-dblp-index download && mcp-dblp-index build`.

The data is DBLP's, under CC0. This repository only holds the build workflow and its scripts.
