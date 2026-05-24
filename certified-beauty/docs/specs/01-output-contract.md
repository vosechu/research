# 01 — Output Contract

Three Parquet files in `data/`. Use these exact column names and logical types. (Python types shown as
Arrow types; map to your language's Parquet writer equivalently. Booleans are real booleans, not strings.)

## `data/brands.parquet` — one row per (brand, source)

| column | type | notes |
|---|---|---|
| `name` | string | retailer's brand display name, verbatim (e.g. `bareMinerals`, `HAUS LABS BY LADY GAGA`) |
| `slug` | string | see slug rules per source (02-conventions) |
| `source` | string | `ulta` \| `sephora` \| `bluemercury` |
| `url` | string | brand page URL at that retailer |
| `clean` | bool | certification booleans — meaning is per-source (see source docs) |
| `cruelty_free` | bool | |
| `vegan` | bool | |
| `sustainable` | bool | |
| `give_back` | bool | |
| `cert_coverage` | string | `all` \| `some` (see 02-conventions) |
| `scraped_at` | timestamp[us, UTC] | run timestamp; identical for all rows written in one run |

A brand sold at multiple retailers produces **one row per source** (do not merge). Dedupe across sources
happens only in queries.

## `data/products.parquet` — one row per (brand, source, product)

| column | type | notes |
|---|---|---|
| `brand` | string | retailer's brand name for the product (join key to `brands.name` within a source) |
| `source` | string | `ulta` \| `sephora` \| `bluemercury` |
| `name` | string | product display name, verbatim |
| `url` | string | product page URL, query string stripped |
| `categories` | list<string> | retailer category tags, **lowercased**, sorted, deduped. Combo products carry multiple. |
| `scraped_at` | timestamp[us, UTC] | run timestamp |

Product identity within a source = the normalized product `url`. The same physical product at two
retailers is **not** merged (different `source`, different `url`).

## `data/product_attributes.parquet` — tidy/long, one row per (product, attribute, value, confidence)

| column | type | notes |
|---|---|---|
| `brand` | string | product's brand |
| `source` | string | retailer |
| `product_url` | string | join key to `products.url` (same normalization) |
| `attribute` | string | `coverage` \| `finish` \| `natural_beauty` \| `ingredient_preference` |
| `value` | string | lowercased value (e.g. `light`, `sheer`, `natural`, `matte`, `paraben free`) |
| `confidence` | string | `retailer_asserted` \| `brand_website_asserted` \| `inferred_from_title` \| `inferred_from_description` |
| `scraped_at` | timestamp[us, UTC] | run timestamp |

- Long format on purpose: one product may hold many attribute rows, including the **same** attribute
  from different sources/confidences (e.g. `coverage=light` both `retailer_asserted` and `inferred_from_title`). Keep both.
- Dedupe key within a source: `(product_url, attribute, value, confidence)`.
- `attribute` values `natural_beauty` / `ingredient_preference` are Bluemercury-only (raw tag namespaces).
  `coverage` / `finish` come from Ulta and Bluemercury.
- `confidence` values `brand_website_asserted` and `inferred_from_description` are **reserved but not yet produced**.

## Write semantics (all three files)

Each extractor **replaces all rows for its own `source`** and leaves other sources untouched (idempotent
re-runs; safe to rebuild one retailer). Implementation: read existing file, drop rows where
`source == this_source`, append new rows, rewrite. If the file does not exist, create it.
