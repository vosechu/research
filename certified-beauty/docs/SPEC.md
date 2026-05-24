# Certified Beauty Dataset — Reproduction Spec

Enough to rebuild the dataset in any language (current impl is Python). "Same output" = same logical
rows/values, not byte-identical files; `scraped_at`/`researched_at` differ per run; live-data drift is expected.

## Outputs (`data/`)
Scraped parquets are **gitignored** (regenerate via the extractors); committed inputs are the research JSON
+ the CSV deliverable.

**`brands.parquet`** — one row per (brand, source): `name, slug, source(ulta|sephora|bluemercury), url,
clean, cruelty_free, vegan, sustainable, give_back` (bool), `cert_coverage(all|some)`, `scraped_at(ts us UTC)`.
A brand at N retailers = N rows.

**`products.parquet`** — one row per (brand, source, product): `brand, source, name, url, categories(list<str>,
lowercased retailer tags), scraped_at`. Combo products carry multiple categories.

**`product_attributes.parquet`** — tidy: `brand, source, product_url, attribute(coverage|finish|natural_beauty|
ingredient_preference), value(lowercased), confidence, scraped_at`. `confidence` ∈ `retailer_asserted` |
`brand_website_asserted` | `inferred_from_title` | `inferred_from_description` (only first + third populated).

**`brand_certs.parquet`** ← `brand_certs_findings.json` via `research_certs.py` — vendor-research, kept separate
from scraped data: `brand, cert, value(bool; null=unknown), confidence, evidence_url, note, researched_at`.
`confidence` ∈ `third_party_certified` > `brand_website_asserted` > `inferred` > `unknown`. Every true/false cites a URL.

**`ethical_brands_face_makeup.csv`** (committed deliverable) — see Queries below.

## Conventions
- **UA:** Chrome 124 mac string. **Rate limit:** ≥0.5s between requests (~2/s).
- **Encoding (critical):** Ulta serves `text/html` with no charset but UTF-8 bytes — force/sniff UTF-8 or
  accents mangle (`Avène`→`AvÃ¨ne`). Sephora declares charset; Bluemercury JSON is UTF-8.
- **Embedded JSON:** brace-match (string-aware), not regex. Ulta = `<script id='apollo_state'>` `__APOLLO_STATE__`;
  Sephora = `<script id="linkStore" type="text/json">`.
- **Normalize:** lowercase + trim category/attribute values and **brand/product names** (trailing whitespace
  in scraped names collides on joins). Brand-join key = lowercase + strip non-alphanumeric. `categories` deduped/sorted.
- **slug:** last URL path segment (Ulta/Sephora); vendor lowercased+hyphenated (Bluemercury).
- **cert_coverage:** Ulta=`all` (brand-level program). Derived sources: `all` if majority of products carry the
  representative cert else `some`; never null. A boolean cert is true if ≥1 qualifying product.
- Out of scope: ingredient lists, shade ranges, SPF, sizes. Never invent a taxonomy — use the retailer's own.

## Ulta (plain HTTP)
- **Brands:** GET `/brand/all`; recursively find module `type=="ShopAllBrands"` → `navItems[].items[].action{label,url}`
  + `icons`. Icon→bool: `Clean`→clean, `CrueltyFree`→cruelty_free, `Vegan`→vegan, `SustainablePackaging`→sustainable,
  `PositiveImpact`→give_back. `cert_coverage="all"`. (~956 brands.)
- **Products (category-page inversion):** brand pages lack per-product categories, so crawl each makeup category
  page `/shop/makeup/{face,eyes,lips}/<cat>?page=N` (27 paths), module `ProductListingResults` → `items[].{brandName,
  productName, action.url}`; category = `Breadcrumbs` leaf lowercased; paginate via `resultCount`/`pageSize`.
  Aggregate by (brand, url-sans-query) → sorted category set. (~4,406 products.)
- **Coverage/Finish attrs:** retailer-asserted = facet groups with `groupType` COVERAGE/FINISH → each value's
  `applyFilterUrl` (`?coverage=light`) server-renders filtered results → membership. inferred_from_title = name
  lexicon (skin tint/sheer/tinted→coverage light; full coverage→full; matte/dewy/radiant/natural→finish). (~6,468 rows.)

## Sephora (Akamai — needs a real browser)
- `/` and `/brands-list` work via plain HTTP; everything else 403s, incl. **Playwright-launched Chrome (headless OR
  headed)**. Working method: user launches real Chrome `--remote-debugging-port=9222 --user-data-dir=~/.chrome-sephora-debug`,
  browses once; `connect_over_cdp` + reuse `contexts[0]`.
- **Brands:** GET `/brands-list` (plain HTTP) → `linkStore.ssrProps[*BrandsList*].groupedBrands[*].brands[].{shortName,
  targetUrl}`. (~341.)
- **Certs:** filters are client-side/virtualized (not in SSR), BUT dedicated cert *category* pages expose the
  cert-filtered Brand refinement natively: `clean`←`/shop/clean-makeup`, `vegan`←`/shop/vegan-makeup`
  (denominator = `/shop/makeup-cosmetics`). cruelty_free/sustainable/give_back have no category page → vendor research.
- **No product rows** (storefront unscrapable).

## Bluemercury (Shopify)
GET `/collections/makeup/products.json?limit=250&page=N` (dedupe by handle). Per product: `vendor`(brand),
`title`(name), `handle`→url, `tags`. Tags: `collection::<x>`→categories (drop `campaign_`/`gifts`/structural
stoplist); `filter::coverage_`/`filter::finish_`→attrs; `attr::natural beauty_`/`filter::ingredient preference_`→
raw attrs. Only `sustainable` maps to a discrete cert (sustainability tags: sustainable packaging/eco friendly/
sustainable/refillable); cf/vegan/clean/give_back have no BM tag → vendor research. (~88 brands, 1,336 products.)

## Vendor research + the `ethical` view
Fills certs retailers don't expose, evidence-cited, kept separate (`brand_certs_findings.json`). Rubric anchors:
cruelty_free = Leaping Bunny/PETA/explicit no-test; vegan = 100% vegan/cert (partial→false, note "partial");
give_back = documented donation program / 1% for the Planet / B Corp (community); sustainable = B Corp / Climate
Neutral / documented packaging-sourcing (**not** 1% for the Planet — that's give_back). B Corp counts for both.
Prioritize brands closest to all-5.

**`ethical` view** (query.py): a cert is satisfied if a retailer flags it OR research confirms true OR (vegan only)
research = "partial". "Fully certified" = all five satisfied. Raw layers never overwritten.

**Independent verification** (`brand_certs_verification.json`) grades each ethical brand: `verification_tier` ∈
`all5_verified` > `minor_partials` (only partials) > `needs_docs` (a cert undocumented) > `refuted` (contradicted).

## Queries (query.py) + the CSV
Views: `brands/products/attributes/research/ethical/capability`. Headline = fully-certified brands carrying both
`concealer` and `bronzer`. `generate_csv.py` → `ethical_brands_face_makeup.csv`: ethical brands that carry ≥1 **core
color** face-makeup product (drops hair/skin/fragrance + primer/setting-only skincare brands), columns = cert
provenance + `verification_tier`/`verification_flags` + each face category (`TRUE`/empty/`NULL`=unsearchable) +
`retailers` (where to buy). Sorted by tier then name.

## Verifying a reproduction
`DESCRIBE` matches the schemas above (types incl. `timestamp[us,UTC]`, `list<string>`); per-source counts within
drift of the reference; `checks.py` passes (encoding, joins, dupes, nulls, enums, whitespace); icon/tag→bool
mappings reproduce for a fixed brand sample. Reference (2026-05-24): ulta 956 brands/4,406 products; sephora 341;
bluemercury 88/1,336.
