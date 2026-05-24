# Certified Beauty Dataset

A small local dataset of ethically-certified beauty brands and their makeup products
across Ulta, Sephora, and Bluemercury, enriched with vendor-site cert research — built to answer
questions like:

- *Which fully-certified brands carry both a concealer and a bronzer?* → **bareMinerals**
- *Which ethical brands carry a sheer skin-evener + cheekbone highlighter + eyeshadow + eyeliner?*
  → **ILIA, Jane Iredale, PÜR Minerals, RMS Beauty, bareMinerals**
- *Which certified brands lean "natural"* (sheer/light coverage, natural/radiant finish)?

Stack: **DuckDB + Parquet**. No pandas required (DuckDB returns DataFrames if you want them).

## Status

| Retailer | Brands | Products | Attributes | Cert source |
|---|---|---|---|---|
| **Ulta** | 956 | 4,406 (26 categories) | 6,468 (coverage/finish) | native 5-pillar Conscious Beauty badges |
| **Sephora** | 341 | — (no product rows) | — | clean + vegan via cert-category pages |
| **Bluemercury** | 88 | 1,336 | 6,822 (incl. raw tags) | sustainable from Shopify tags |

**Vendor research** (`brand_certs.parquet`) fills the cert gaps Sephora/Bluemercury don't expose, growing
the **fully-certified set from 24 → 77 brands**. See `docs/SPEC.md` for the reproduction spec.

## Data model (`data/*.parquet`)

Four tables; full column lists, types, and value enums live in [`docs/SPEC.md`](docs/SPEC.md).

- **`brands`** — one row per (brand, source): the five retailer-asserted cert booleans.
- **`products`** — one row per (brand, source, product); `categories` are the retailer's own breadcrumb
  leaves, lowercased (combo products carry multiple).
- **`product_attributes`** — tidy/long, one row per (product, attribute, value): coverage/finish plus
  Bluemercury tag signals, each with a `confidence` (retailer-asserted vs title-inferred).
- **`brand_certs`** — vendor-site cert research, kept **separate** to preserve provenance (source of truth:
  `brand_certs_findings.json`, loaded by `research_certs.py`). Every true/false cites an evidence URL.

> **"Ethical"** = all five certs satisfied, where a cert counts if a retailer flags it **OR** research
> confirms it (vegan "partial"/mostly-vegan counts, with the note preserved; "unknown" does not). See the
> `ethical` view in `query.py`.
> **"Natural look"** = light/sheer coverage + natural/radiant finish — *not* color palette.

## Setup

```bash
python3 -m venv .venv
./.venv/bin/pip install -r requirements.txt        # duckdb, pyarrow, requests, playwright, ruff
./.venv/bin/playwright install chromium            # only needed for Sephora
```

## Build the data

```bash
./.venv/bin/python extract_ulta.py             # Ulta brands + products + coverage/finish attributes
./.venv/bin/python extract_bluemercury.py      # Bluemercury brands/products/attributes (Shopify)
./.venv/bin/python extract_sephora.py          # Sephora brands + clean/vegan certs (needs debug Chrome)
./.venv/bin/python research_certs.py           # load vendor-research findings -> brand_certs.parquet
./.venv/bin/python checks.py                   # data-correctness checks (exits non-zero on FAIL)
./.venv/bin/python query.py                    # views + headline/routine analyses
```
Crawls rate-limit to ~2 req/s and checkpoint to `data/*_checkpoint.json` (resumable; delete to re-crawl).
Writers replace rows per `source`, so re-running one retailer is safe.

**Sephora** is behind Akamai Bot Manager — automated browsers are blocked. Launch a real Chrome with
remote debugging and browse Sephora once; the scraper attaches over CDP:
```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --remote-debugging-port=9222 --user-data-dir="$HOME/.chrome-sephora-debug" https://www.sephora.com/
```
(See CLAUDE.md → Sephora gotchas for the why.)

## Query

`query.py` registers `brands / products / attributes / research / ethical / capability` views and runs the
headline + routine analyses. Quick start:

```python
import duckdb
con = duckdb.connect()
for v in ("brands", "products", "attributes"):
    con.sql(f"CREATE VIEW {v} AS SELECT * FROM 'data/{v if v!='attributes' else 'product_attributes'}.parquet'")
```

Headline — certified brands carrying both a concealer and a bronzer. Brand keys are normalized
(lowercase, alphanumeric-only) because `products.brand` and `brands.name` differ in case/punctuation
across retailers, so the join must be on the normalized key:
```sql
WITH norm AS (SELECT regexp_replace(lower(name),'[^a-z0-9]','','g') AS bk, * FROM brands),
     certified AS (SELECT DISTINCT bk FROM norm
                   WHERE clean AND cruelty_free AND vegan AND sustainable AND give_back),
     prod AS (SELECT regexp_replace(lower(brand),'[^a-z0-9]','','g') AS bk, categories FROM products)
SELECT DISTINCT b.name FROM norm b JOIN certified c USING(bk)
WHERE EXISTS (SELECT 1 FROM prod p WHERE p.bk=b.bk AND list_contains(p.categories,'concealer'))
  AND EXISTS (SELECT 1 FROM prod p WHERE p.bk=b.bk AND list_contains(p.categories,'bronzer'));
```

## Scope & limitations

- Out of scope by design: ingredient lists, shade ranges, SPF, sizes. Categories use each retailer's own taxonomy.
- **Sephora has no product rows** (client-side/virtualized storefront), so product-level questions only cover
  Ulta + Bluemercury — Sephora-only ethical brands (e.g. Milk Makeup, Tower 28) can't be evaluated for "carries X".
- Vendor research is **point-in-time** and evidence-cited; `clean`/`sustainable` are fuzzier than
  cruelty-free/vegan (no universal standard). Re-run `research_certs.py` after editing the findings JSON.
- See `docs/SPEC.md` for the full language-agnostic reproduction spec.

## Headline deliverable

`generate_csv.py` → `data/ethical_brands_face_makeup.csv`: ethical brands that carry ≥1 **core** face-makeup
product (hair/skin/fragrance-only and primer/setting-only skincare brands dropped). One row per brand with cert
provenance, each face category (`TRUE`/empty/`NULL`=unsearchable), the carrying `retailers` (where to buy), and a
**`verification_tier`** from an independent re-check: `all5_verified` › `minor_partials` (only minor partials,
e.g. vegan-except-beeswax) › `needs_docs` (a cert undocumented) › `refuted`. Sorted by tier, then name. The
dominant cert gap is `vegan` ("has a vegan range" ≠ 100% vegan); product existence was independently confirmed.
