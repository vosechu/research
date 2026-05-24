"""Ulta per-product attributes -> data/product_attributes.parquet.

Two passes, both tagged with a `confidence` level:
  1. retailer_asserted  -- crawl each makeup category's Coverage/Finish filtered
     listings (?coverage=light, ?finish=natural, ...) and record membership.
  2. inferred_from_title -- a keyword lexicon over product names.

Raw values only; no scoring/combination here.
"""

import json
import os
import re

import pyarrow.parquet as pq

from common import extract_apollo_state, get, now, write_attributes
from extract_ulta_products import BASE, CATEGORY_PATHS, find_plr

DATA = os.path.join(os.path.dirname(__file__), "data")
CHECKPOINT = os.path.join(DATA, "ulta_attributes_checkpoint.json")

# groupType values we care about for the "natural look" question.
WANT_GROUPS = {"COVERAGE", "FINISH"}


def find_facet_filters(state):
    """Return [(attribute, value, applyFilterUrl)] for COVERAGE/FINISH facets on a page."""
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
    # dedupe
    return sorted(set(out))


def crawl_filtered(url):
    """Yield product (brand, url) for a filtered listing, across pages."""
    page = 1
    while True:
        sep = "&" if "?" in url else "?"
        html = get(f"{url}{sep}page={page}").text
        plr = find_plr(extract_apollo_state(html))
        if not plr:
            break
        for it in plr.get("items", []):
            brand = it.get("brandName")
            purl = (it.get("action") or {}).get("url")
            if brand and purl:
                yield brand, purl.split("?")[0]
        total = plr.get("resultCount") or 0
        size = plr.get("pageSize") or len(plr.get("items", []))
        if not size or page * size >= total:
            break
        page += 1


def retailer_asserted_rows():
    ck = json.load(open(CHECKPOINT)) if os.path.exists(CHECKPOINT) else {}
    for path in CATEGORY_PATHS:
        if path in ck:
            continue
        # read which facets this category exposes (unfiltered page)
        state = extract_apollo_state(get(f"{BASE}{path}").text)
        facets = find_facet_filters(state)
        cat_rows = []
        for attribute, value, url in facets:
            for brand, purl in crawl_filtered(url):
                cat_rows.append(
                    {"brand": brand, "product_url": purl, "attribute": attribute, "value": value}
                )
        ck[path] = cat_rows
        json.dump(ck, open(CHECKPOINT, "w"))
        print(
            f"  {path:30} facets={len({(r['attribute'], r['value']) for r in cat_rows})} "
            f"rows={len(cat_rows)}"
        )
    # flatten
    return [r for rows in ck.values() for r in rows]


# --- title inference lexicon: (compiled regex, attribute, value) ---
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
    path = os.path.join(DATA, "products.parquet")
    tbl = pq.read_table(path).to_pylist()
    rows = []
    for r in tbl:
        if r["source"] != "ulta":
            continue
        name = r["name"] or ""
        for rx, attribute, value in LEX:
            if rx.search(name):
                rows.append(
                    {
                        "brand": r["brand"],
                        "product_url": r["url"],
                        "attribute": attribute,
                        "value": value,
                    }
                )
    return rows


def main():
    ts = now()
    ra = retailer_asserted_rows()
    ti = title_inferred_rows()

    def stamp(rows, confidence):
        seen = set()
        out = []
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

    all_rows = stamp(ra, "retailer_asserted") + stamp(ti, "inferred_from_title")
    out = write_attributes(all_rows, "ulta")
    print(f"\nretailer_asserted rows: {len(stamp(ra, 'retailer_asserted'))}")
    print(f"inferred_from_title rows: {len(stamp(ti, 'inferred_from_title'))}")
    print(f"wrote {len(all_rows)} attribute rows -> {out}")


if __name__ == "__main__":
    main()
