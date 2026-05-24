# Certified Beauty Dataset

A small local dataset of **ethically-certified beauty brands** and their **makeup products**
across Ulta, Sephora, and Bluemercury — built to answer questions like:

- *Which fully-certified brands carry both a concealer and a bronzer?*
- *Which certified brands lean "natural"* (sheer/light coverage, natural/radiant finish)?

Stack: **DuckDB + Parquet**. No pandas required (DuckDB returns DataFrames if you want them).

## Status

| Retailer | Brands | Products | Cert source | Notes |
|---|---|---|---|---|
| **Ulta** | ✅ 956 | ✅ 4,406 (27 categories) | native 5-pillar Conscious Beauty badges | fully done, incl. coverage/finish attributes |
| **Sephora** | ✅ 341 (names) | ⏳ | derive from Clean/Vegan/CF/PlanetAware filters | Akamai-protected; cert extraction is the hard part (see below) |
| **Bluemercury** | ⏳ ~247 | ⏳ | clean-beauty collection only | Shopify `products.json` |

See `PLAN.md` for the live checklist and engineering notes.

## Data model (`data/*.parquet`)

**`brands`** — one row per (brand, source):
`name, slug, source, url, clean, cruelty_free, vegan, sustainable, give_back, cert_coverage, scraped_at`
A brand sold at multiple retailers gets one row per retailer; dedupe in queries.

**`products`** — one row per (brand, source, product):
`brand, source, name, url, categories[], scraped_at`
`categories` are the retailer's own breadcrumb leaves, lowercased (e.g. `['concealer']`). Combo
products carry multiple categories.

**`product_attributes`** — tidy/long, one row per (product, attribute, value, source):
`brand, source, product_url, attribute, value, confidence, scraped_at`
- `attribute` ∈ {`coverage`, `finish`}; `value` lowercased (e.g. `light`, `sheer`, `natural`, `radiant`, `matte`).
- `confidence` ∈ `retailer_asserted` | `brand_website_asserted` | `inferred_from_title` | `inferred_from_description`.
  Today only `retailer_asserted` (from retailer filter facets) and `inferred_from_title` (name lexicon) are populated.

> **"Natural look"** is operationalized as light/sheer coverage + natural/radiant finish — *not* color palette.

## Setup

```bash
python3 -m venv .venv
./.venv/bin/pip install -r requirements.txt        # duckdb, pyarrow, requests, playwright
./.venv/bin/playwright install chromium            # only needed for Sephora
```

## Build the data

```bash
./.venv/bin/python extract_ulta.py             # brands
./.venv/bin/python extract_ulta_products.py    # products (category-page inversion)
./.venv/bin/python extract_ulta_attributes.py  # coverage/finish (retailer + title-inferred)
```
Crawls rate-limit to ~2 req/s and checkpoint to `data/*_checkpoint.json` (resumable; delete to re-crawl).
Writers replace rows per `source`, so re-running one retailer is safe.

**Sephora** is behind Akamai Bot Manager — automated browsers are blocked. You must launch a real
Chrome with remote debugging and browse Sephora once, then the scraper attaches to it:
```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --remote-debugging-port=9222 --user-data-dir="$HOME/.chrome-sephora-debug" https://www.sephora.com/
```
(See CLAUDE.md → Sephora gotchas for the why.)

## Query

```python
import duckdb
con = duckdb.connect()
con.sql("CREATE VIEW brands     AS SELECT * FROM 'data/brands.parquet'")
con.sql("CREATE VIEW products   AS SELECT * FROM 'data/products.parquet'")
con.sql("CREATE VIEW attributes AS SELECT * FROM 'data/product_attributes.parquet'")
```

Headline — certified brands carrying both a concealer and a bronzer:
```sql
WITH certified AS (
  SELECT DISTINCT name FROM brands
  WHERE clean AND cruelty_free AND vegan AND sustainable AND give_back
)
SELECT c.name FROM certified c
WHERE EXISTS (SELECT 1 FROM products p WHERE p.brand=c.name AND 'concealer' = ANY(p.categories))
  AND EXISTS (SELECT 1 FROM products p WHERE p.brand=c.name AND 'bronzer'   = ANY(p.categories));
```

"Natural" products (retailer-asserted), with brand certs:
```sql
SELECT DISTINCT a.brand, a.product_url
FROM attributes a
WHERE a.confidence='retailer_asserted'
  AND a.attribute='coverage' AND a.value IN ('light','sheer');
```

## Scope

Out of scope by design: ingredient lists, shade ranges, SPF values, sizes.
Categories use each retailer's own taxonomy — no invented taxonomy.
