# Certified Beauty Dataset — Plan

Goal: local DuckDB+Parquet dataset of ethically-certified beauty brands and their
makeup products across Ulta, Sephora, Bluemercury — plus per-product **natural-look**
attributes (coverage/finish) with provenance/confidence. "Natural" = light/sheer
coverage + natural/radiant finish (NOT color palette).

## Data model
- `data/brands.parquet` — one row per (brand, source); 5 cert booleans + cert_coverage.
- `data/products.parquet` — one row per (brand, source, product); `categories[]` from retailer breadcrumbs.
- `data/product_attributes.parquet` — tidy/long: `brand, source, product_url, attribute, value, confidence, scraped_at`.
  - `confidence` ∈ {`retailer_asserted`, `brand_website_asserted`, `inferred_from_title`, `inferred_from_description`}.
  - Raw values only — no combination/scoring logic yet.

## Ulta  ✅ (fully unblocked — plain curl + embedded apollo_state JSON)
- [x] Brands → `brands.parquet` (956 brands, native 5-pillar Conscious Beauty icons; 24 fully certified)
- [x] Products → `products.parquet` (4,406 products, 281 brands, 27 face/eyes/lips categories) via **category-page inversion**
- [x] Retailer-asserted attributes — `?coverage=` / `?finish=` filtered crawls (confidence=retailer_asserted)  *[running, ~done]*
- [x] Title-inferred attributes — name lexicon (confidence=inferred_from_title)  *[same run]*

## Sephora  ✅ (CDP-attach to real Chrome; certs via dedicated cert-category pages)
- [x] Akamai bypass: CDP-attach to user-launched real Chrome (`:9222`). headless/automated Chrome is blocked.
- [x] Brands: 341 names+urls from allowlisted `/brands-list` (plain HTTP).
- [x] Certs: clean (41) + vegan (51) via `/shop/clean-makeup` + `/shop/vegan-makeup` brand refinements.
      cruelty-free/sustainable/give_back have NO scrapable source → vendor research.
- [x] Products/attributes: NOT extracted (client-side/virtualized storefront). Sephora contributes brands+certs only.

## Bluemercury  ✅ (Shopify)
- [x] Brands (88 makeup vendors) + products (1,336) via `products.json`
- [x] Raw retailer-asserted attributes (coverage/finish/natural_beauty/ingredient_preference); `sustainable` derived (31 brands)

## Vendor research  ✅ (data/brand_certs.parquet ← brand_certs_findings.json via research_certs.py)
- [x] Pilot (5 brands) validated the rubric; ILIA cross-check surfaced retailer-"vegan" = "has vegan range" vs strict 100%.
- [x] Fan-out: 40 brands at 4/5 researched for their single missing verifiable cert (cf/vegan/give_back/sustainable).
- [x] Policy: keep both (retailer + research separate); `ethical` view = union, vegan "partial" counts, "unknown" doesn't.
- [x] Result: **fully-certified set 25 → 56 brands** (47 strict-vegan). Evidence-cited, confidence-tiered.
- [ ] Next batch: the **88 brands at 3/5** (research their missing verifiable certs to grow the set further).

## Cross-source notes
- BM↔Ulta product overlap: ~171 exact + ~69 fuzzy(≥0.85) = **~240 shared products** across 26 shared brands.
- **Sephora has no product rows** → product-level "carries X" questions only cover Ulta + Bluemercury.

## Finish
- [x] `query.py` — views (brands/products/attributes/research/ethical/capability) + headline + routine queries; `all_five.md`
- [x] `checks.py` — data-correctness suite (0 FAIL on clean data)
- [x] `docs/specs/` — language-agnostic reproduction spec (audited by an independent subagent)
- [x] CSV export (`generate_csv.py` → `data/ethical_brands_face_makeup.csv`): 56 ethical brands × face categories,
      retailer per cell, cert provenance, + independent verification (`brand_certs_verification.json`).
      **Independent agents confirmed only 13/56 as truly all-5** (common gaps: vegan=partial, undocumented give-back);
      product existence 45/45 confirmed. Next research batch (88 at 3/5) still open.

---

## EPIPHANIES / hard-won facts
1. **Retailers don't put per-product categories on brand pages.** Solved with *category-page inversion*:
   crawl each category listing, tag products by breadcrumb leaf, aggregate combos. Ulta done this way.
2. **Ulta category pages embed everything** in `<script id='apollo_state'>`: `ProductListingResults` (products
   w/ brandName), `Breadcrumbs` (category), and facet groups with `groupType` COVERAGE/FINISH + `applyFilterUrl`
   (e.g. `?coverage=light`). Filtered URLs DO server-render filtered results → per-product attributes. Pagination `?page=N`.
3. **Only Ulta exposes brand-level certs.** Sephora/Bluemercury certs must be *derived* from product membership.
4. **Sephora = Akamai Bot Manager.** curl/WebFetch/Playwright-launched-Chrome (headless OR headed) all get 403.
   Working method: user launches real Chrome with `--remote-debugging-port=9222 --user-data-dir=~/.chrome-sephora-debug`
   (Chrome 136+ needs the non-default profile), browses once; we `connect_over_cdp` and reuse `contexts[0]`.
5. **Sephora filters are 100% client-side.** SSR `linkStore` (and its refinements) are ALWAYS unfiltered, regardless
   of `?filters[...]` in the URL — confirmed identical totals across unfiltered/clean/vegan. The grid is React-
   *virtualized* (~6 tiles in DOM until scroll). The only product-bearing API over the wire is sponsored ads
   (`api-developer.sephora.com/v1/browseSearchProduct`, public `x-api-key` — a publishable client key, NOT a secret,
   nothing to report; replaying it at volume would be a ToS issue, so we don't). Net: filtered cert/attribute data
   requires interactive checkbox-clicking + de-virtualizing the grid → fragile & expensive. **Resolved:** use the
   dedicated cert *category* pages (clean/vegan exist; cruelty-free/planet-aware do not) and send the rest to vendor research.
6. **Dedicated cert category pages** (`/shop/clean-makeup`, `/shop/vegan-makeup`) expose the cert-filtered brand set
   natively via `nthCategory` brand refinement — but only clean + vegan have one. `/beauty/planet-aware` is a curated
   guide page (~25 featured brands, not a full faceted set); cruelty-free has none.
7. **Encoding:** Ulta serves `text/html` with no charset → `requests.text` defaults to ISO-8859-1 and mangles accents
   (`Avène`→`AvÃ¨ne`). Always force/sniff UTF-8 when charset is absent. (Caught by `checks.py` mojibake check.)
8. **Retailer "vegan" = "has a vegan range", not "100% vegan brand"** (ILIA validation case). Kept both signals;
   the `ethical` view counts research "partial"/mostly-vegan with the caveat note preserved.
