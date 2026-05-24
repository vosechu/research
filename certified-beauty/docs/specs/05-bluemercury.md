# 05 — Bluemercury

`source = "bluemercury"`. Bluemercury runs on **Shopify**; all data comes from the public `products.json`
endpoint (plain HTTP, no auth, no anti-bot). Everything (brand, category, coverage, finish, cert signals)
is inline in each product's `tags`.

## Crawl

GET `https://bluemercury.com/collections/makeup/products.json?limit=250&page={N}`, N starting at 1,
until a page returns an empty `products` array. Concatenate. Expect ~1,336 products across ~88 vendors.

Each product object: `vendor` (brand), `title` (name), `handle`, `tags[]` (array of strings).
Product `url = "https://bluemercury.com/products/" + handle`.

## Tag namespaces

Tags are namespaced with `::` or `_`. Relevant ones:

| tag pattern | meaning |
|---|---|
| `collection::<x>` | category membership (includes hierarchy + promo noise) |
| `filter::coverage_<v>` | coverage attribute |
| `filter::finish_<v>` | finish attribute |
| `attr::natural beauty_<v>` | natural-beauty claim (cert-ish) |
| `filter::ingredient preference_<v>` | ingredient-preference claim |

## A. Products → `products.parquet`

For each product: `brand = vendor`, `name = title`, `url` as above.
`categories` = the set of `collection::<x>` values, lowercased, **excluding**:
- any value beginning with `campaign_`, `gifts_`, or `gift`
- the exact stoplist: `makeup`, `inclusive brands`, `active lifestyle`, `home lifestyle`,
  `tools and accessories`, `brushes and tools`, `face brushes`, `eye brushes`, `skin care`, `skincare`,
  `best sellers`, `new`, `sale`.

Sort + dedupe `categories`. (Kept values include real leaves like `concealer`, `bronzer`, `lipstick`,
`mascara`, and useful hierarchy like `face and cheek`, `eyes`, `lips`.)

## B. Attributes → `product_attributes.parquet` (all `confidence = "retailer_asserted"`)

For each product, emit one attribute row per matching tag (dedupe `(product_url, attribute, value)`).
"suffix" = everything after the **first** `_` in the tag (each prefix above contains exactly one `_`,
so this equals stripping the prefix):

| tag prefix | attribute | value |
|---|---|---|
| `filter::coverage_` | `coverage` | suffix, lowercased (e.g. `light`, `sheer`, `buildable`, `full`) |
| `filter::finish_` | `finish` | suffix, lowercased (e.g. `natural`, `radiant`, `dewy`, `matte`) |
| `attr::natural beauty_` | `natural_beauty` | suffix, lowercased (e.g. `paraben free`, `sustainable packaging`) |
| `filter::ingredient preference_` | `ingredient_preference` | suffix, lowercased |

Expect ~6,822 rows (coverage ~634, finish ~836, natural_beauty ~2,226, ingredient_preference ~3,126).

## C. Brands → `brands.parquet`

The brand set = the distinct `vendor` values among the crawled makeup products (~88).

Cert booleans — Bluemercury exposes **no discrete cruelty-free / vegan / clean / give-back tag**, so:
- `sustainable` = the brand has **≥1** product carrying any sustainability tag, where a sustainability tag
  is an `attr::natural beauty_<v>` with `v` ∈ {`sustainable packaging`, `eco friendly`, `sustainable`, `refillable`}.
- `clean = false`, `cruelty_free = false`, `vegan = false`, `give_back = false` (no tag → delegated to vendor research).
- `cert_coverage` = `all` if `sustainable` and `(# sustainable products / # of the brand's products) > 0.5`,
  else `some`. Brands with **no** sustainability product also get `some` (it is the default; `cert_coverage`
  is never null).
- `slug` = vendor, lowercased, spaces → `-` (the `&` character is **kept** in the slug).
- `url` = `"https://bluemercury.com/collections/"` + vendor lowercased with spaces → `-` **and** `&` → `and`
  (note: `&→and` applies to the URL only, not the slug).

Expect ~31 brands with `sustainable = true`.

## Vendor-research backlog (not automated)

cruelty_free / vegan / clean / give_back for Bluemercury brands (start with the 31 sustainable ones) are to
be researched on each brand's own website. Out of scope for the automated pipeline.

## Notes

- A separate `/collections/<brand>/products.json` exists per brand but many return 0 (smart collections);
  crawling the single `makeup` collection and reading `vendor` is the reliable path.
- Bluemercury↔Ulta share ~26 brands and ~240 products (≥0.85 fuzzy name match) — informational only.
