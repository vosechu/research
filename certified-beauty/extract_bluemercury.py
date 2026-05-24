"""Bluemercury (Shopify) makeup -> brands / products / product_attributes parquet.

Everything is retailer-asserted inline in products.json tags:
  collection::<cat>                  -> categories
  filter::coverage_<v>, filter::finish_<v> -> coverage/finish attributes
  attr::natural beauty_<v>, filter::ingredient preference_<v> -> raw cert/ingredient signals

No discrete cruelty-free/vegan/give-back tags exist, so those booleans stay False (per spec,
"leave false and discuss"). `sustainable` is derived from sustainability tags via the
majority/minority rule. All raw signal tags are also stored as attributes so nothing is lost.
"""
import requests

from common import now, write_attributes, write_brands, write_products

UA = ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")
COLLECTION = "https://bluemercury.com/collections/makeup/products.json"
PRODUCT_BASE = "https://bluemercury.com/products/"

# category tags to drop (promos / structural, not product categories)
DROP_PREFIX = ("campaign_", "gifts_", "gift")
DROP_EXACT = {"makeup", "inclusive brands", "active lifestyle", "home lifestyle",
              "tools and accessories", "brushes and tools", "face brushes", "eye brushes",
              "skin care", "skincare", "home lifestyle", "best sellers", "new", "sale"}

# tags (in the natural-beauty / ingredient-preference namespaces) that imply `sustainable`
SUSTAINABLE_TAGS = {"sustainable packaging", "eco friendly", "sustainable", "refillable"}


def crawl():
    s = requests.Session()
    s.headers["User-Agent"] = UA
    out = []
    page = 1
    while True:
        r = s.get(f"{COLLECTION}?limit=250&page={page}", timeout=30)
        r.raise_for_status()
        ps = r.json().get("products", [])
        if not ps:
            break
        out += ps
        page += 1
    return out


def categories_of(tags):
    cats = []
    for t in tags:
        if t.startswith("collection::"):
            v = t.split("::", 1)[1].strip().lower()
            if v in DROP_EXACT or any(v.startswith(p) for p in DROP_PREFIX):
                continue
            cats.append(v)
    return sorted(set(cats))


def main():
    products = crawl()
    print(f"crawled {len(products)} Bluemercury makeup products, "
          f"{len({p['vendor'] for p in products})} brands")
    ts = now()

    prod_rows, attr_rows = [], []
    # per-brand tallies for cert derivation
    brand_total = {}
    brand_sustain = {}
    brand_meta = {}  # vendor -> example url for brand row (unused, kept simple)

    for p in products:
        vendor = p.get("vendor")
        tags = p.get("tags", [])
        url = PRODUCT_BASE + p["handle"]
        prod_rows.append({
            "brand": vendor, "source": "bluemercury", "name": p.get("title"),
            "url": url, "categories": categories_of(tags), "scraped_at": ts,
        })
        brand_total[vendor] = brand_total.get(vendor, 0) + 1
        has_sustain = False
        for t in tags:
            if t.startswith("filter::coverage_"):
                attr_rows.append((vendor, url, "coverage", t.split("_", 1)[1].strip().lower()))
            elif t.startswith("filter::finish_"):
                attr_rows.append((vendor, url, "finish", t.split("_", 1)[1].strip().lower()))
            elif t.startswith("attr::natural beauty_"):
                v = t.split("_", 1)[1].strip().lower()
                attr_rows.append((vendor, url, "natural_beauty", v))
                if v in SUSTAINABLE_TAGS:
                    has_sustain = True
            elif t.startswith("filter::ingredient preference_"):
                v = t.split("_", 1)[1].strip().lower()
                attr_rows.append((vendor, url, "ingredient_preference", v))
        if has_sustain:
            brand_sustain[vendor] = brand_sustain.get(vendor, 0) + 1

    # dedupe attribute rows, stamp confidence
    seen = set()
    attr_out = []
    for vendor, url, attribute, value in attr_rows:
        key = (url, attribute, value)
        if key in seen:
            continue
        seen.add(key)
        attr_out.append({"brand": vendor, "source": "bluemercury", "product_url": url,
                         "attribute": attribute, "value": value,
                         "confidence": "retailer_asserted", "scraped_at": ts})

    # brand rows: sustainable derived (majority/minority); others False (no Bluemercury tag)
    brand_rows = []
    for vendor, total in brand_total.items():
        sus_n = brand_sustain.get(vendor, 0)
        sustainable = sus_n > 0
        coverage = "all" if sus_n / total > 0.5 else "some"
        brand_rows.append({
            "name": vendor, "slug": (vendor or "").lower().replace(" ", "-"),
            "source": "bluemercury", "url": "https://bluemercury.com/collections/" +
            (vendor or "").lower().replace(" ", "-").replace("&", "and"),
            "clean": False, "cruelty_free": False, "vegan": False,
            "sustainable": sustainable, "give_back": False,
            "cert_coverage": coverage if sustainable else "some", "scraped_at": ts,
        })

    bp = write_brands(brand_rows, "bluemercury")
    pp = write_products(prod_rows, "bluemercury")
    ap = write_attributes(attr_out, "bluemercury")
    nsust = sum(1 for r in brand_rows if r["sustainable"])
    print(f"brands: {len(brand_rows)} ({nsust} with a sustainability tag) -> {bp}")
    print(f"products: {len(prod_rows)} -> {pp}")
    print(f"attributes: {len(attr_out)} rows -> {ap}")
    from collections import Counter
    ac = Counter(r["attribute"] for r in attr_out)
    print("attribute breakdown:", dict(ac))


if __name__ == "__main__":
    main()
