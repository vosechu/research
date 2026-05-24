"""Ulta extractor: brands, products, and coverage/finish attributes (plain HTTP, embedded apollo_state).

Run `python extract_ulta.py [brands|products|attributes|all]` (default: all, in that order).
- brands     -> data/brands.parquet              (5-pillar Conscious Beauty icons)
- products   -> data/products.parquet            (category-page inversion; brand PLPs lack categories)
- attributes -> data/product_attributes.parquet  (Coverage/Finish: retailer-asserted + title-inferred)
Long crawls checkpoint to data/ulta_*_checkpoint.json (resumable; delete to re-crawl).
"""

import json
import os
import re
import sys

import pyarrow.parquet as pq

from common import (
    extract_apollo_state,
    get,
    now,
    slug_from_url,
    write_attributes,
    write_brands,
    write_products,
)

DATA = os.path.join(os.path.dirname(__file__), "data")
INDEX_URL = "https://www.ulta.com/brand/all"
BASE = "https://www.ulta.com/shop/makeup/"
PRODUCTS_CHECKPOINT = os.path.join(DATA, "ulta_products_checkpoint.json")
ATTRS_CHECKPOINT = os.path.join(DATA, "ulta_attributes_checkpoint.json")

# Ulta Conscious Beauty pillar icon -> our boolean column.
ICON_MAP = {
    "Clean": "clean",
    "CrueltyFree": "cruelty_free",
    "Vegan": "vegan",
    "SustainablePackaging": "sustainable",
    "PositiveImpact": "give_back",
}

# Full makeup = all face + eyes + lips subcategories (nails excluded), from Ulta's taxonomy.
CATEGORY_PATHS = [
    "face/foundation",
    "face/concealer",
    "face/bb-cc-creams",
    "face/color-correcting",
    "face/blush",
    "face/bronzer",
    "face/highlighter",
    "face/contouring",
    "face/face-primer",
    "face/setting-spray-powder",
    "eyes/eyeshadow",
    "eyes/eyeshadow-palettes",
    "eyes/eyeliner",
    "eyes/mascara",
    "eyes/eyebrows",
    "eyes/eyelashes",
    "eyes/eye-primer-base",
    "eyes/lash-primer-serums",
    "lips/lipstick",
    "lips/lip-gloss",
    "lips/lip-liner",
    "lips/lip-oil",
    "lips/lip-balms",
    "lips/lip-plumpers",
    "lips/lip-stain",
    "lips/lip-tints-balms",
    "lips/lip-treatments",
]


# --- shared apollo_state helpers -------------------------------------------
def find_plr(state):
    """First ProductListingResults module in the page state."""
    out = []

    def w(o):
        if isinstance(o, dict):
            if o.get("type") == "ProductListingResults":
                out.append(o)
            for v in o.values():
                w(v)
        elif isinstance(o, list):
            for v in o:
                w(v)

    w(state)
    return out[0] if out else None


# --- brands -> brands.parquet ----------------------------------------------
def parse_brands(html):
    from common import find_modules_by_type

    modules = find_modules_by_type(extract_apollo_state(html), "ShopAllBrands")
    if not modules:
        raise ValueError("ShopAllBrands module not found")
    ts = now()
    rows = []
    for group in modules[0].get("navItems", []):
        for item in group.get("items", []):
            action = item.get("action") or {}
            name = (action.get("label") or "").strip()
            url = action.get("url")
            if not name or not url:
                continue
            icons = set(item.get("icons") or [])
            row = {
                "name": name,
                "slug": slug_from_url(url),
                "source": "ulta",
                "url": url,
                "cert_coverage": "all",
                "scraped_at": ts,
            }
            for icon, col in ICON_MAP.items():
                row[col] = icon in icons
            rows.append(row)
    return rows


def run_brands():
    rows = parse_brands(get(INDEX_URL).text)
    path = write_brands(rows, "ulta")
    cert_cols = list(ICON_MAP.values())
    any_cert = sum(any(r[c] for c in cert_cols) for r in rows)
    all_five = sum(all(r[c] for c in cert_cols) for r in rows)
    print(f"[brands] {len(rows)} brands ({any_cert} with >=1 cert, {all_five} all-five) -> {path}")


# --- products -> products.parquet (category-page inversion) ----------------
def category_leaf(state):
    """Lowercased breadcrumb leaf = the retailer's own category name."""

    def find(o):
        if isinstance(o, dict):
            if o.get("type") == "Breadcrumbs":
                return o
            for v in o.values():
                if (r := find(v)) is not None:
                    return r
        elif isinstance(o, list):
            for v in o:
                if (r := find(v)) is not None:
                    return r

    bc = find(state)
    if bc and bc.get("breadcrumbs"):
        return bc["breadcrumbs"][-1]["item"]["label"].strip().lower()
    return None


def crawl_category(path):
    """Return (category_label, [{brand, name, url}]) across all pages of a category."""
    page, label, products = 1, None, []
    while True:
        state = extract_apollo_state(get(f"{BASE}{path}?page={page}").text)
        plr = find_plr(state)
        if not plr:
            break
        if label is None:
            label = category_leaf(state) or path.split("/")[-1].replace("-", " ")
        for it in plr.get("items", []):
            brand = (it.get("brandName") or "").strip()
            name = (it.get("productName") or "").strip()
            purl = (it.get("action") or {}).get("url")
            if brand and name and purl:
                products.append({"brand": brand, "name": name, "url": purl.split("?")[0]})
        total = plr.get("resultCount") or 0
        size = plr.get("pageSize") or len(plr.get("items", []))
        if not size or page * size >= total:
            break
        page += 1
    return label, products


def run_products():
    ck = json.load(open(PRODUCTS_CHECKPOINT)) if os.path.exists(PRODUCTS_CHECKPOINT) else {}
    for path in CATEGORY_PATHS:
        if path in ck:
            continue
        label, products = crawl_category(path)
        ck[path] = {"label": label, "products": products}
        os.makedirs(DATA, exist_ok=True)
        json.dump(ck, open(PRODUCTS_CHECKPOINT, "w"))
        print(f"  {path:32} -> {label!r:24} {len(products)} products")

    agg = {}  # (brand, url) -> {"name":, "categories": set}
    for data in ck.values():
        label = (data["label"] or "").strip()
        for p in data["products"]:
            brand, name = p["brand"].strip(), p["name"].strip()
            entry = agg.setdefault((brand, p["url"]), {"name": name, "categories": set()})
            entry["categories"].add(label)
    ts = now()
    rows = [
        {
            "brand": brand,
            "source": "ulta",
            "name": e["name"],
            "url": url,
            "categories": sorted(e["categories"]),
            "scraped_at": ts,
        }
        for (brand, url), e in agg.items()
    ]
    path = write_products(rows, "ulta")
    combos = sum(1 for r in rows if len(r["categories"]) > 1)
    print(
        f"[products] {len(rows)} products ({combos} in >1 category, "
        f"{len({r['brand'] for r in rows})} brands) -> {path}"
    )


# --- attributes -> product_attributes.parquet ------------------------------
WANT_GROUPS = {"COVERAGE", "FINISH"}


def find_facet_filters(state):
    """[(attribute, value, applyFilterUrl)] for COVERAGE/FINISH facets on a category page."""
    out = []

    def w(o):
        if isinstance(o, dict):
            if o.get("groupType") in WANT_GROUPS and o.get("applyFilterUrl") and o.get("title"):
                out.append(
                    (o["groupType"].lower(), o["title"].strip().lower(), o["applyFilterUrl"])
                )
            for v in o.values():
                w(v)
        elif isinstance(o, list):
            for v in o:
                w(v)

    w(state)
    return sorted(set(out))


def crawl_filtered(url):
    """Yield (brand, product_url) for a coverage/finish-filtered listing, across pages."""
    page = 1
    while True:
        sep = "&" if "?" in url else "?"
        plr = find_plr(extract_apollo_state(get(f"{url}{sep}page={page}").text))
        if not plr:
            break
        for it in plr.get("items", []):
            brand = (it.get("brandName") or "").strip()
            purl = (it.get("action") or {}).get("url")
            if brand and purl:
                yield brand, purl.split("?")[0]
        total = plr.get("resultCount") or 0
        size = plr.get("pageSize") or len(plr.get("items", []))
        if not size or page * size >= total:
            break
        page += 1


def retailer_asserted_rows():
    ck = json.load(open(ATTRS_CHECKPOINT)) if os.path.exists(ATTRS_CHECKPOINT) else {}
    for path in CATEGORY_PATHS:
        if path in ck:
            continue
        facets = find_facet_filters(extract_apollo_state(get(f"{BASE}{path}").text))
        cat_rows = []
        for attribute, value, url in facets:
            for brand, purl in crawl_filtered(url):
                cat_rows.append(
                    {"brand": brand, "product_url": purl, "attribute": attribute, "value": value}
                )
        ck[path] = cat_rows
        os.makedirs(DATA, exist_ok=True)
        json.dump(ck, open(ATTRS_CHECKPOINT, "w"))
        print(f"  {path:30} rows={len(cat_rows)}")
    return [r for rows in ck.values() for r in rows]


# title-inference lexicon: (compiled regex, attribute, value)
_LEX = [
    (
        r"skin\s*tint|tinted\s*moisturi[sz]er|\btint\b|sheer|light\s*coverage|veil|"
        r"second\s*skin|barely[\s-]*there|no[\s-]*makeup|your\s*skin\s*but\s*better|"
        r"serum\s*(foundation|concealer|tint)|water\s*tint|blur",
        "coverage",
        "light",
    ),
    (r"full[\s-]*coverage|high\s*coverage|total\s*coverage|maximum\s*coverage", "coverage", "full"),
    (r"\bmatte\b|mattif", "finish", "matte"),
    (
        r"\bdewy\b|radian|\bglow|luminous|lumini[sz]|gleam|\bsheen\b|lustre|luster",
        "finish",
        "radiant",
    ),
    (r"natural\s*finish|\bsatin\b|soft[\s-]*focus|skin[\s-]*like", "finish", "natural"),
]
LEX = [(re.compile(p, re.I), a, v) for p, a, v in _LEX]


def title_inferred_rows():
    tbl = pq.read_table(os.path.join(DATA, "products.parquet")).to_pylist()
    rows = []
    for r in tbl:
        if r["source"] != "ulta":
            continue
        for rx, attribute, value in LEX:
            if rx.search(r["name"] or ""):
                rows.append(
                    {
                        "brand": r["brand"],
                        "product_url": r["url"],
                        "attribute": attribute,
                        "value": value,
                    }
                )
    return rows


def run_attributes():
    ts = now()

    def stamp(rows, confidence):
        seen, out = set(), []
        for r in rows:
            key = (r["product_url"], r["attribute"], r["value"], confidence)
            if key in seen:
                continue
            seen.add(key)
            out.append(
                {
                    "brand": r["brand"],
                    "source": "ulta",
                    "product_url": r["product_url"],
                    "attribute": r["attribute"],
                    "value": r["value"],
                    "confidence": confidence,
                    "scraped_at": ts,
                }
            )
        return out

    ra = stamp(retailer_asserted_rows(), "retailer_asserted")
    ti = stamp(title_inferred_rows(), "inferred_from_title")
    path = write_attributes(ra + ti, "ulta")
    print(f"[attributes] {len(ra)} retailer_asserted + {len(ti)} inferred_from_title -> {path}")


def main():
    step = sys.argv[1] if len(sys.argv) > 1 else "all"
    if step in ("brands", "all"):
        run_brands()
    if step in ("products", "all"):
        run_products()
    if step in ("attributes", "all"):
        run_attributes()


if __name__ == "__main__":
    main()
