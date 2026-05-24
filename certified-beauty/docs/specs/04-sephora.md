# 04 — Sephora

`source = "sephora"`. Sephora is behind **Akamai Bot Manager**; access rules differ sharply by path.

## Access model (critical)

- `/` and `/brands-list` are edge-allowlisted: **plain HTTP (requests/curl) with the standard UA returns
  200 with real content.** Use plain HTTP for the brands list.
- Everything else (`/shop/*`, `/brand/*`, `/api/*`) returns **403 "Access Denied"** to any non-validated
  client — including curl, WebFetch, AND Playwright-launched Chrome (headless or headed). Akamai detects
  automation/CDP-launch signals.
- **The only working method for protected pages:** attach to a Chrome that a *human launched* and browsed:
  1. Launch real Chrome with remote debugging on a **non-default** profile (Chrome 136+ ignores the debug
     port on the default profile):
     `"…/Google Chrome" --remote-debugging-port=9222 --user-data-dir="$HOME/.chrome-sephora-debug" https://www.sephora.com/`
  2. Browse the homepage once so Akamai validates the session (`_abck` cookie) via genuine JS execution.
  3. Connect via CDP (`connect_over_cdp("http://localhost:9222")`) and **reuse the existing browser context**
     (inherits the validated cookies). Navigate protected pages from there → 200 with real content.
- A Ruby/Java reproduction needs an equivalent: drive a real, human-warmed Chrome over CDP/DevTools Protocol.
  Pure HTTP clients cannot reach protected pages.

Protected pages embed data in `<script id="linkStore" type="text/json">` (brace-match, see 02).

## A. Brands → `brands.parquet` (plain HTTP)

1. GET `https://www.sephora.com/brands-list` (plain requests; allowlisted).
2. From `linkStore`, find `ssrProps[<key containing "BrandsList">]` whose value has `groupedBrands`.
3. `groupedBrands` is keyed A–Z(+`#`); each has `brands[]` with `{shortName, targetUrl, ...}`.
   `name = shortName`, `url = "https://www.sephora.com" + targetUrl`. Expect ~341 brands.
4. `slug` = last path segment of `url`.

## B. Certs (via CDP browser)

Sephora's on-page filters are applied **client-side** (the SSR `linkStore` is always unfiltered, the grid
is React-virtualized) — so filters are not scrapable from the embedded JSON. **However**, dedicated cert
*category* pages exist whose SSR `linkStore.page.nthCategory` natively reflects the cert, and whose **Brand
refinement** lists every qualifying brand with a product count:

| boolean | cert category page |
|---|---|
| `clean` | `https://www.sephora.com/shop/clean-makeup` |
| `vegan` | `https://www.sephora.com/shop/vegan-makeup` |

Denominator page for coverage ratio: `https://www.sephora.com/shop/makeup-cosmetics`.

For each of those pages (navigated via the CDP browser): parse `linkStore.page.nthCategory.refinements`,
find the refinement group whose values' `refinementValue` strings contain `filters[Brand]=` , and read
`{<brand name after "filters[Brand]=">: count}`.

Then for each of the 341 brands (matched by normalized name, see 02):
- `clean` = brand ∈ clean set; `vegan` = brand ∈ vegan set.
- `cruelty_free = false`, `sustainable = false`, `give_back = false` — **no scrapable Sephora source**
  (cruelty-free has no category page; "Planet Aware" is only a curated guide page / client-side filter;
  give-back is not a Sephora concept). These are delegated to vendor-site research.
- `cert_coverage` = `all` if `clean` and `clean_count / total_makeup_count > 0.5`, else `some`.

Expect ~41 clean, ~51 vegan, ~22 clean&vegan. No brand is all-5 (cf/sustainable/give_back are false).

## C. Products / attributes

**Not extracted.** Sephora's grid is client-side/virtualized and its filters unscrapable from SSR, so
per-product category/coverage/finish data isn't reliably obtainable without heavy, fragile DOM automation.
Sephora contributes brands+certs only; it has no rows in `products.parquet` / `product_attributes.parquet`.

## Vendor-research backlog (not automated)

For the clean&vegan candidate brands (and others), `cruelty_free`, `sustainable`, and `give_back` are to be
determined by visiting each brand's own website — recorded later with `confidence = brand_website_asserted`
semantics. Out of scope for the automated pipeline.
