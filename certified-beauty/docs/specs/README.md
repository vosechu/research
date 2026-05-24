# Certified Beauty Dataset — Reproduction Spec

These documents specify the dataset precisely enough to **reproduce the same Parquet output in any
language** (the current implementation is Python; Ruby/Java/etc. should yield equivalent files).

Read in order:

1. [01-output-contract.md](01-output-contract.md) — the three Parquet files: exact schemas, types, row identity.
2. [02-conventions.md](02-conventions.md) — shared rules: fetching, normalization, slugs, categories, confidence, write semantics.
3. [03-ulta.md](03-ulta.md) — Ulta extraction (brands, products, attributes). Fully automated, no auth.
4. [04-sephora.md](04-sephora.md) — Sephora extraction (Akamai bypass via a real browser; brands + clean/vegan certs).
5. [05-bluemercury.md](05-bluemercury.md) — Bluemercury extraction (Shopify `products.json`).
6. [06-queries.md](06-queries.md) — the analysis queries + `all_five.md`.
7. [07-vendor-research.md](07-vendor-research.md) — vendor-site cert research (`brand_certs.parquet`) + the `ethical` view.

## What "same Parquet" means

- **Same logical rows and column values**, not a byte-identical file. Row *order* is unspecified
  (the data is a set); a reproduction may sort differently. Parquet compression/metadata may differ.
- **`scraped_at` will differ** (it's the run timestamp) — exclude it when diffing two runs.
- **Live-data drift is expected.** Retailers change inventory/badges continuously. The specs define the
  *method* and *mapping rules*, which are stable; absolute counts are a point-in-time reference, not a contract.

## Reference snapshot (captured 2026-05-24)

| source | brands | clean | cruelty_free | vegan | sustainable | give_back | all-5 | products | attribute rows |
|---|---|---|---|---|---|---|---|---|---|
| ulta | 956 | 156 | 138 | 142 | 154 | 125 | 24 | 4,406 | 6,467 |
| sephora | 341 | 41 | 0\* | 51 | 0\* | 0\* | 0 | — | — |
| bluemercury | 88 | 0\* | 0\* | 0\* | 31 | 0\* | 0 | 1,336 | 6,822 |

\* Not available from that retailer's data; left `false` and delegated to vendor-site research. See per-source docs.

Headline query result at snapshot: the only fully-certified (all-5) brand carrying both a concealer
and a bronzer is **bareMinerals**.

## Verifying a reproduction

After building, a reproduction is "correct" if:
1. `DESCRIBE` on each Parquet matches the schemas in [01-output-contract.md](01-output-contract.md) exactly (types included).
2. Per-source row counts and per-cert tallies are within drift tolerance of the reference snapshot
   (exact if run against an unchanged site cache).
3. The four queries in [06-queries.md](06-queries.md) run and the headline/`all_five.md` are sane.
4. Spot-check: the icon/tag → boolean mappings produce identical booleans for a fixed sample of brands.
