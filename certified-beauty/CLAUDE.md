# certified-beauty

Local dataset of ethically-certified beauty brands + their makeup products across **Ulta,
Sephora, Bluemercury**, enriched with vendor-site cert research. Answers questions like "which
fully-certified brands carry both a concealer and a bronzer" and "which ethical brands carry a
sheer skin-evener + highlighter + eyeshadow + eyeliner". Stack: **DuckDB + Parquet** (no pandas).
See `docs/SPEC.md` for the language-agnostic reproduction spec.

## Setup / run
```
python3 -m venv .venv
# deps: duckdb, pyarrow, requests, playwright, ruff
./.venv/bin/pip install -r requirements.txt
# chromium is only needed for Sephora
./.venv/bin/playwright install chromium
```
Each `*.py` has a module docstring describing its job; `ls *.py` + those docstrings are the file map.
Run order: extract_ulta → extract_bluemercury → extract_sephora → research_certs → checks → query.
No `uv` on this machine — use the venv. macOS: don't use GNU `sed` flags. Lint with `./.venv/bin/ruff check .`

## Per-retailer gotchas (the important part)
- **Ulta** — plain HTTP, no anti-bot. Everything is in `<script id='apollo_state'>` (`match_balanced_json` on `window.__APOLLO_STATE__`).
  Brand pages lack per-product categories → crawl category pages and tag by breadcrumb. Coverage/Finish are facet groups with
  `applyFilterUrl` (`?coverage=light`); filtered URLs server-render filtered results. **Ulta sends `text/html` with no charset →
  force UTF-8 or accents mojibake** (`common.get` handles this).
- **Sephora** — behind **Akamai Bot Manager**. Only `/` and `/brands-list` work via plain HTTP; everything else 403s, and
  Playwright-launched Chrome (headless OR headed) is also blocked. **Must CDP-attach to a real Chrome the user launched**
  (`--remote-debugging-port=9222 --user-data-dir=~/.chrome-sephora-debug`, browse once), then `connect_over_cdp` + reuse `contexts[0]`.
  Filters are **client-side only** (SSR `linkStore` always unfiltered, grid React-virtualized) → only the dedicated cert *category*
  pages (`/shop/clean-makeup`, `/shop/vegan-makeup`) yield filtered brand sets. **No Sephora product rows** — storefront isn't scrapable.
- **Bluemercury** — Shopify. `/collections/makeup/products.json` tags carry category (`collection::`), coverage/finish
  (`filter::`), and cert-ish signals (`attr::natural beauty_`). Only `sustainable` maps to a discrete cert; rest = research.

## Conventions
- Lowercase-normalize category/attribute values on write; combo products get multiple categories. Don't invent taxonomy.
- Brand-name joins across tables/sources: normalize = lowercase + strip non-alphanumeric.
- Parquet writers replace rows per `source` (idempotent re-runs). Out of scope: ingredient lists, shade ranges, SPF, sizes.
- Vendor research is point-in-time + evidence-cited; kept in a separate `brand_certs` table (not `brands.parquet`) to preserve provenance. Source of truth = `data/brand_certs_findings.json`.
- "Natural" = sheer/light coverage + natural/radiant finish, NOT color palette.
- "Ethical" = all 5 certs via the `ethical` view (query.py): a cert counts if a retailer flags it OR research confirms it; vegan "partial" counts, "unknown" doesn't.
