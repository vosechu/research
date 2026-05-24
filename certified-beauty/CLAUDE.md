# certified-beauty

Local dataset of ethically-certified beauty brands + their makeup products across **Ulta,
Sephora, Bluemercury**, enriched with vendor-site cert research. Answers questions like "which
fully-certified brands carry both a concealer and a bronzer" and "which ethical brands carry a
sheer skin-evener + highlighter + eyeshadow + eyeliner". Stack: **DuckDB + Parquet** (no pandas).
See `PLAN.md` for status, `docs/specs/` for the language-agnostic reproduction spec.

## Layout
- `common.py` — HTTP (rate-limited ~2 req/s, real UA, UTF-8 charset fix), `match_balanced_json` (Ulta apollo +
  Sephora linkStore), parquet schemas + a single `_write_replacing_source` writer.
- `extract_ulta.py` — Ulta brands → `data/brands.parquet`.
- `extract_ulta_products.py` — Ulta products via category-page inversion → `data/products.parquet`.
- `extract_ulta_attributes.py` — Ulta coverage/finish (retailer-asserted + title-inferred) → `data/product_attributes.parquet`.
- `extract_bluemercury.py` — Bluemercury brands/products/attributes from Shopify `products.json` tags.
- `extract_sephora.py` — Sephora brands + clean/vegan certs (CDP-attached Chrome; see gotchas).
- `research_certs.py` — loads `data/brand_certs_findings.json` → `data/brand_certs.parquet` (vendor research).
- `checks.py` — data-correctness checks (encoding, joins, dupes, nulls, enums, vocab); exits non-zero on FAIL.
- `query.py` — DuckDB views (`brands/products/attributes/research/ethical/capability`) + analyses; writes `all_five.md`.
- `data/*.parquet` outputs; `data/*_checkpoint.json` resumable crawl state (gitignored). `ruff.toml` lint config.

## Setup / run
```
python3 -m venv .venv && ./.venv/bin/pip install -r requirements.txt   # duckdb, pyarrow, requests, playwright, numpy, ruff
./.venv/bin/playwright install chromium                                 # for Sephora
```
Run order: extract_ulta{,_products,_attributes} → extract_bluemercury → extract_sephora → research_certs → checks → query.
No `uv` on this machine — use the venv. macOS: don't use GNU `sed` flags. Lint with `./.venv/bin/ruff check .`

## Data model (full schemas in docs/specs/01-output-contract.md)
- `brands`: name, slug, source, url, 5 cert booleans, cert_coverage, scraped_at. Retailer-asserted.
- `products`: brand, source, name, url, categories[] (lowercased retailer tags), scraped_at.
- `product_attributes` (tidy): brand, source, product_url, attribute {coverage|finish|natural_beauty|ingredient_preference}, value, confidence, scraped_at.
- `brand_certs` (vendor research, separate provenance): brand, cert, value(bool; null=unknown), confidence, evidence_url, note, researched_at.
- **`ethical` view** = retailer flags ∪ research (vegan "partial" counts; "unknown" doesn't). Source of truth for research = `brand_certs_findings.json`.

## Per-retailer gotchas (the important part)
- **Ulta** — easy, plain HTTP. Everything is in `<script id='apollo_state'>` (`match_balanced_json` on `window.__APOLLO_STATE__`).
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
- Vendor research is point-in-time + evidence-cited; kept OUT of `brands.parquet` to preserve provenance.
- "Natural" = sheer/light coverage + natural/radiant finish. NOT color palette. "Ethical" = all 5 certs via the `ethical` view.
