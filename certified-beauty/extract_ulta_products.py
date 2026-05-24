"""Crawl Ulta makeup category pages -> data/products.parquet (category-page inversion).

Ulta brand PLPs carry no per-product categories, so we instead crawl each makeup
category listing, tag every product with that category's breadcrumb leaf, and
aggregate categories per product. Combo products land in multiple categories.
"""

import json
import os

from common import extract_apollo_state, get, now, write_products

BASE = "https://www.ulta.com/shop/makeup/"

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

CHECKPOINT = os.path.join(os.path.dirname(__file__), "data", "ulta_products_checkpoint.json")


def find_plr(state):
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


def category_leaf(state):
    """Lowercased breadcrumb leaf = the retailer's own category name."""

    def find(o):
        if isinstance(o, dict):
            if o.get("type") == "Breadcrumbs":
                return o
            for v in o.values():
                r = find(v)
                if r:
                    return r
        elif isinstance(o, list):
            for v in o:
                r = find(v)
                if r:
                    return r

    bc = find(state)
    if bc and bc.get("breadcrumbs"):
        return bc["breadcrumbs"][-1]["item"]["label"].strip().lower()
    return None


def crawl_category(path):
    """Return (category_label, [ {brand, name, url} ]) across all pages."""
    page = 1
    label = None
    products = []
    while True:
        url = f"{BASE}{path}?page={page}"
        html = get(url).text
        state = extract_apollo_state(html)
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


def load_checkpoint():
    if os.path.exists(CHECKPOINT):
        with open(CHECKPOINT) as f:
            return json.load(f)
    return {}


def save_checkpoint(ck):
    os.makedirs(os.path.dirname(CHECKPOINT), exist_ok=True)
    with open(CHECKPOINT, "w") as f:
        json.dump(ck, f)


def main():
    ck = load_checkpoint()  # {path: {"label":..., "products":[...]}}
    for path in CATEGORY_PATHS:
        if path in ck:
            print(f"  skip (cached): {path} ({len(ck[path]['products'])} products)")
            continue
        label, products = crawl_category(path)
        ck[path] = {"label": label, "products": products}
        save_checkpoint(ck)
        print(f"  {path:32} -> {label!r:24} {len(products)} products")

    # Aggregate: one row per (brand, url), categories = sorted set of labels.
    agg = {}  # (brand, url) -> {"name":, "categories": set}
    for data in ck.values():
        label = (data["label"] or "").strip()
        for p in data["products"]:
            brand, name = p["brand"].strip(), p["name"].strip()
            key = (brand, p["url"])
            entry = agg.setdefault(key, {"name": name, "categories": set()})
            entry["categories"].add(label)

    ts = now()
    rows = [
        {
            "brand": brand,
            "source": "ulta",
            "name": entry["name"],
            "url": url,
            "categories": sorted(entry["categories"]),
            "scraped_at": ts,
        }
        for (brand, url), entry in agg.items()
    ]
    path = write_products(rows, "ulta")
    combos = sum(1 for r in rows if len(r["categories"]) > 1)
    print(f"\naggregated {len(rows)} distinct Ulta products ({combos} in >1 category)")
    print(f"distinct brands w/ products: {len({r['brand'] for r in rows})}")
    print(f"wrote -> {path}")


if __name__ == "__main__":
    main()
