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

## Sephora  (CDP-attach to real Chrome; certs via dedicated cert-category pages)
- [x] Akamai bypass solved: CDP-attach to user-launched real Chrome (`:9222`). headless/automated Chrome is blocked.
- [x] Brands: 341 names+urls from allowlisted `/brands-list` (curl OK).
- [x] **Breakthrough:** client-side filters are unscrapable, BUT Sephora has dedicated cert *category* pages whose
      SSR `linkStore` brand refinement IS the cert-filtered brand set: `/shop/clean-makeup` (41 brands),
      `/shop/vegan-makeup` (51). Need cruelty-free + planet-aware URLs.
- [ ] Certs: read brand refinement per cert page → booleans + counts. give_back←none (research vendor sites).
- [ ] Products/attributes: limited (linkStore shows ~60/page, grid virtualized) — defer / best-effort.

## Bluemercury  (Shopify — done)
- [x] Brands (88 makeup vendors) + products (1,336) via `products.json`
- [x] Raw retailer-asserted attributes (coverage/finish/natural_beauty/ingredient_preference); `sustainable` derived (31 brands)
- [ ] **Research the 31 BM brands with ≥1 sustainability tag directly on vendor sites** for cruelty_free/vegan/clean/give_back
      (Bluemercury exposes no discrete cf/vegan/clean/give_back tag). Same vendor-site research pattern as Sephora give-back.

## Cross-source notes
- BM↔Ulta product overlap: ~171 exact + ~69 fuzzy(≥0.85) = **~240 shared products** across 26 shared brands.

## Finish
- [ ] `query.py` — DuckDB views + 4 queries; `all_five.md`

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
   requires interactive checkbox-clicking + de-virtualizing the grid → fragile & expensive. **Decision needed.**
6. Sephora refinement vocab (for when/if we crack it): Coverage{light,sheer,medium,full}, Finish{natural,radiant,
   matte,satin}; certs under Ingredient Preferences (cleanAtSephora, crueltyFree, vegan) + Shopping Preferences (planetAware).

## Open decision
Sephora cert extraction is the "bulk of the work" the handoff warned about. Options: (A) interactive
click-filter automation per cert (fragile, slow), (B) Sephora names-only + defer certs, (C) drop Sephora.
