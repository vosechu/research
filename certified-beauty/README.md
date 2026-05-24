# Certified Beauty Dataset

A small local dataset of **ethically-certified beauty brands** and their **makeup products**
across Ulta, Sephora, and Bluemercury, enriched with **vendor-site cert research** — built to answer
questions like:

- *Which fully-certified brands carry both a concealer and a bronzer?* → **bareMinerals**
- *Which ethical brands carry a sheer skin-evener + cheekbone highlighter + eyeshadow + eyeliner?*
  → **ILIA, PÜR Minerals, RMS Beauty, bareMinerals**
- *Which certified brands lean "natural"* (sheer/light coverage, natural/radiant finish)?

Stack: **DuckDB + Parquet**. No pandas required (DuckDB returns DataFrames if you want them).

## Status

| Retailer | Brands | Products | Attributes | Cert source |
|---|---|---|---|---|
| **Ulta** | 956 | 4,406 (27 categories) | 6,467 (coverage/finish) | native 5-pillar Conscious Beauty badges |
| **Sephora** | 341 | — (Akamai/virtualized; see CLAUDE.md) | — | clean + vegan via cert-category pages |
| **Bluemercury** | 88 | 1,336 | 6,822 (incl. raw tags) | sustainable from Shopify tags |

**Vendor research** (`brand_certs.parquet`) fills the cert gaps Sephora/Bluemercury don't expose, growing
the **fully-certified set from 25 → 56 brands**. See `PLAN.md` for the live checklist and engineering notes.

## Data model (`data/*.parquet`)

**`brands`** — one row per (brand, source); the retailer-asserted cert booleans:
`name, slug, source, url, clean, cruelty_free, vegan, sustainable, give_back, cert_coverage, scraped_at`

**`products`** — one row per (brand, source, product):
`brand, source, name, url, categories[], scraped_at` — `categories` are the retailer's own breadcrumb
leaves, lowercased; combo products carry multiple.

**`product_attributes`** — tidy/long, one row per (product, attribute, value):
`brand, source, product_url, attribute, value, confidence, scraped_at`
- `attribute` ∈ {`coverage`, `finish`, `natural_beauty`, `ingredient_preference`}; `value` lowercased.
- `confidence` ∈ `retailer_asserted` | `inferred_from_title` (others reserved).

**`brand_certs`** — vendor-site cert research, kept separate to preserve provenance (source of truth is
`brand_certs_findings.json`; load with `research_certs.py`):
`brand, cert, value (bool; null=unknown), confidence, evidence_url, note, researched_at`
- `confidence` ∈ `third_party_certified` > `brand_website_asserted` > `inferred` > `unknown`. Every
  true/false cites an `evidence_url`.

> **"Ethical"** = all five certs satisfied, where a cert counts if a retailer flags it **OR** research
> confirms it (vegan "partial"/mostly-vegan counts, with the note preserved; "unknown" does not). See the
> `ethical` view in `query.py`.
> **"Natural look"** = light/sheer coverage + natural/radiant finish — *not* color palette.

## Setup

```bash
python3 -m venv .venv
./.venv/bin/pip install -r requirements.txt        # duckdb, pyarrow, requests, playwright, numpy, ruff
./.venv/bin/playwright install chromium            # only needed for Sephora
```

## Build the data

```bash
./.venv/bin/python extract_ulta.py             # Ulta brands
./.venv/bin/python extract_ulta_products.py    # Ulta products (category-page inversion)
./.venv/bin/python extract_ulta_attributes.py  # Ulta coverage/finish (retailer + title-inferred)
./.venv/bin/python extract_bluemercury.py      # Bluemercury brands/products/attributes (Shopify)
./.venv/bin/python extract_sephora.py          # Sephora brands + clean/vegan certs (needs debug Chrome)
./.venv/bin/python research_certs.py           # load vendor-research findings -> brand_certs.parquet
./.venv/bin/python checks.py                   # data-correctness checks (exits non-zero on FAIL)
./.venv/bin/python query.py                    # views + analyses; writes all_five.md
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

Headline — certified brands carrying both a concealer and a bronzer:
```sql
WITH certified AS (SELECT DISTINCT name FROM brands
                   WHERE clean AND cruelty_free AND vegan AND sustainable AND give_back)
SELECT c.name FROM certified c
WHERE EXISTS (SELECT 1 FROM products p WHERE p.brand=c.name AND list_contains(p.categories,'concealer'))
  AND EXISTS (SELECT 1 FROM products p WHERE p.brand=c.name AND list_contains(p.categories,'bronzer'));
```

## Scope & limitations

- Out of scope by design: ingredient lists, shade ranges, SPF, sizes. Categories use each retailer's own taxonomy.
- **Sephora has no product rows** (client-side/virtualized storefront), so product-level questions only cover
  Ulta + Bluemercury — Sephora-only ethical brands (e.g. Milk Makeup, Tower 28) can't be evaluated for "carries X".
- Vendor research is **point-in-time** and evidence-cited; `clean`/`sustainable` are fuzzier than
  cruelty-free/vegan (no universal standard). Re-run `research_certs.py` after editing the findings JSON.
- See `docs/specs/` for the full language-agnostic reproduction spec.

## Headline deliverable

`generate_csv.py` → `data/ethical_brands_face_makeup.csv`: the 56 fully-certified brands × major face-makeup
categories, with the carrying retailer per cell, cert provenance, **and an independent-verification verdict**.
Independent agents confirmed only **13/56** as genuinely all-five (frequent gaps: `vegan` is "has a vegan
range" not 100% vegan; `give_back`/`sustainable` often undocumented) — while product existence was 45/45
confirmed. Treat `independently_verified=all5_confirmed` as the high-confidence subset.
