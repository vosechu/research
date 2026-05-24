# certified-beauty

Local dataset of ethically-certified beauty brands + their makeup products across **Ulta,
Sephora, Bluemercury**, to answer questions like "which fully-certified brands carry both a
concealer and a bronzer" and "which certified brands lean "natural" (sheer/light coverage,
natural finish)". Stack: **DuckDB + Parquet** (no pandas needed). See `PLAN.md` for status.

## Layout
- `common.py` — HTTP (rate-limited ~2 req/s, real UA), apollo_state extraction, parquet schemas + writers.
- `extract_ulta.py` — Ulta brands → `data/brands.parquet`.
- `extract_ulta_products.py` — Ulta products via category-page inversion → `data/products.parquet`.
- `extract_ulta_attributes.py` — Ulta coverage/finish (retailer-asserted + title-inferred) → `data/product_attributes.parquet`.
- `extract_sephora.py` — Sephora brands/certs (WIP; see Sephora gotchas).
- `data/*.parquet` — outputs. `data/*_checkpoint.json` — resumable crawl checkpoints (safe to delete to re-crawl).
- `query.py` — (todo) DuckDB views + analysis queries.

## Setup / run
```
python3 -m venv .venv && ./.venv/bin/pip install -r requirements.txt   # duckdb, pyarrow, requests, playwright
./.venv/bin/playwright install chromium                                 # for Sephora
./.venv/bin/python extract_ulta.py            # then extract_ulta_products.py, extract_ulta_attributes.py
```
No `uv` on this machine — use the venv. macOS: don't use GNU `sed` flags.

## Data model (see PLAN.md for full schemas)
- `brands`: name, slug, source, url, clean, cruelty_free, vegan, sustainable, give_back, cert_coverage, scraped_at.
- `products`: brand, source, name, url, categories[] (lowercased breadcrumb leaves), scraped_at.
- `product_attributes` (tidy/long): brand, source, product_url, attribute, value, confidence, scraped_at.
  - confidence ∈ retailer_asserted | brand_website_asserted | inferred_from_title | inferred_from_description.

## Per-retailer gotchas (the important part)
- **Ulta** — easy. Everything is in `<script id='apollo_state'>` (brace-match `window.__APOLLO_STATE__`).
  Brand pages lack per-product categories → crawl category pages instead and tag by breadcrumb. Coverage/Finish
  are facet groups with `applyFilterUrl` (`?coverage=light`); filtered URLs server-render filtered results.
- **Sephora** — behind **Akamai Bot Manager**. Only `/` and `/brands-list` work via curl; everything else 403s,
  and Playwright-launched Chrome (headless or headed) is also blocked. **Must CDP-attach to a real Chrome the user
  launched** (`--remote-debugging-port=9222 --user-data-dir=~/.chrome-sephora-debug`, browse once to validate),
  then `connect_over_cdp` + reuse `contexts[0]`. Also: Sephora **filters client-side only** — the embedded
  `linkStore` is always unfiltered and the grid is React-virtualized, so cert/attribute extraction is hard.
- **Bluemercury** — Shopify. `/<collection>/products.json` works; no structured cert program (clean-beauty collection at most).

## Conventions
- Lowercase-normalize category/attribute values on write. Combo products get multiple category entries.
- Out of scope (per spec): ingredient lists, shade ranges, SPF, sizes.
- Parquet writers replace rows per `source` (idempotent re-runs; safe to re-run one retailer).
- "Natural" goal = sheer/light coverage + natural/radiant finish. NOT color palette.
