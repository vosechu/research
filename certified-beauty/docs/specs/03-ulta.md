# 03 — Ulta

Fully automated, no authentication, plain HTTP. All data lives in the `__APOLLO_STATE__` blob (see 02).
`source = "ulta"` for every row.

## A. Brands → `brands.parquet`

1. GET `https://www.ulta.com/brand/all`. Extract `__APOLLO_STATE__`.
2. Recursively walk the whole `__APOLLO_STATE__` object and take the **first** dict with
   `type == "ShopAllBrands"` (it lives under `ROOT_QUERY → Page(...) → content`, but a simple
   recursive type-search is what the implementation does and is unambiguous).
3. That module has `navItems` = A–Z groups; each group has `items[]`. For each item:
   - `name = item.action.label`, `url = item.action.url` (skip items missing either).
   - `icons = item.icons` (array of strings; may be null/empty).
4. Map icons → booleans (the five Ulta "Conscious Beauty" pillars):

   | icon string | column |
   |---|---|
   | `Clean` | `clean` |
   | `CrueltyFree` | `cruelty_free` |
   | `Vegan` | `vegan` |
   | `SustainablePackaging` | `sustainable` |
   | `PositiveImpact` | `give_back` |

   A column is `true` iff its icon is present in `icons`.
5. `slug` = last path segment of `url`. `cert_coverage = "all"` (always). 
6. Expect ~956 brands; ~24 with all five icons.

(There is also an `item.badges` field — it only ever carries a `New` brand marker; ignore it.)

## B. Products → `products.parquet` (category-page inversion)

Ulta brand pages do **not** carry per-product categories, so crawl category listing pages instead and tag
each product with that page's category.

**Category paths** (27; under `https://www.ulta.com/shop/makeup/`):

```
face/foundation  face/concealer  face/bb-cc-creams  face/color-correcting  face/blush
face/bronzer  face/highlighter  face/contouring  face/face-primer  face/setting-spray-powder
eyes/eyeshadow  eyes/eyeshadow-palettes  eyes/eyeliner  eyes/mascara  eyes/eyebrows
eyes/eyelashes  eyes/eye-primer-base  eyes/lash-primer-serums
lips/lipstick  lips/lip-gloss  lips/lip-liner  lips/lip-oil  lips/lip-balms
lips/lip-plumpers  lips/lip-stain  lips/lip-tints-balms  lips/lip-treatments
```
(This is "full makeup" = all face + eyes + lips subcategories, nails excluded. The list is Ulta's own
taxonomy under `/shop/makeup`; re-discoverable from that page if it changes.)

For each category path:
1. GET `https://www.ulta.com/shop/makeup/{path}?page={N}`, starting at N=1. Extract `__APOLLO_STATE__`.
2. Find module `type == "ProductListingResults"`. Read `resultCount` and `pageSize`.
3. Category label = the `Breadcrumbs` module's last crumb `label`, lowercased (e.g. `concealer`).
   Fallback if missing: the path leaf with `-`→space.
4. For each `items[]` entry: `brand = brandName`, `name = productName`,
   `url = action.url` with query string stripped. Skip if brand/name/url missing.
5. Paginate: stop when `N * pageSize >= resultCount`; else N+1.

Then **aggregate across all categories**: group by `(brand, url)`; `categories` = sorted set of the labels
under which that url appeared; `name` = the productName. Expect ~4,406 products, ~597 in >1 category.

## C. Coverage / Finish attributes → `product_attributes.parquet`

### C1. Retailer-asserted (`confidence = "retailer_asserted"`)
For each category path, GET the unfiltered page and find facet groups whose `groupType` ∈ {`COVERAGE`,`FINISH`}.
Each facet value object has an `applyFilterUrl` (e.g. `…/concealer?coverage=light`) and a `title`.
For each such value: GET the `applyFilterUrl` (paginate with `&page=N`, same ProductListingResults logic),
and for every product in the filtered result emit a row:
`attribute = groupType.lower()` (`coverage`/`finish`), `value = title.lower()` (e.g. `light`, `natural`),
`product_url` = normalized product url. Dedupe `(product_url, attribute, value)`.

Coverage values seen: `light, buildable, medium, full`. Finish values seen: `matte, natural, radiant`
(plus eye-specific finishes like `shimmer, metallic` on eye categories). Not all categories expose both
facets (eyes often lack Coverage) — that's expected sparsity.

### C2. Inferred-from-title (`confidence = "inferred_from_title"`)
Apply a case-insensitive regex lexicon to each Ulta product `name`; each match emits an attribute row.
A name may match several patterns (keep all). Lexicon:

| attribute | value | regex (case-insensitive) |
|---|---|---|
| coverage | light | `skin\s*tint`, `tinted\s*moisturi[sz]er`, `\btint\b`, `sheer`, `light\s*coverage`, `veil`, `second\s*skin`, `barely[\s-]*there`, `no[\s-]*makeup`, `your\s*skin\s*but\s*better`, `serum\s*(foundation\|concealer\|tint)`, `water\s*tint`, `blur` |
| coverage | full | `full[\s-]*coverage`, `high\s*coverage`, `total\s*coverage`, `maximum\s*coverage` |
| finish | matte | `\bmatte\b`, `mattif` |
| finish | radiant | `\bdewy\b`, `radian`, `\bglow`, `luminous`, `lumini[sz]`, `gleam`, `\bsheen\b`, `lustre`, `luster` |
| finish | natural | `natural\s*finish`, `\bsatin\b`, `soft[\s-]*focus`, `skin[\s-]*like` |

Read product names from the already-built `products.parquet` (source=ulta). Dedupe `(product_url, attribute, value)`
within this confidence level. Expect ~5,516 retailer-asserted + ~951 title-inferred rows.

**Scope note (intentional asymmetry):** title inference is applied to **Ulta only**. The same lexicon
*could* run on Bluemercury product names, but Bluemercury already provides comprehensive retailer-asserted
coverage/finish tags (05), so inference would add little but noise; Sephora has no product rows at all (04).
A reproduction should keep title inference Ulta-only to match this output. (Extending it to other sources
is a deliberate future choice, not a reproduction requirement.)
