"""Sephora brands + certs via CDP-attached real Chrome.

Sephora filters are client-side/unscrapable, BUT dedicated cert *category* pages exist whose
SSR linkStore brand refinement IS the cert-filtered brand set. Reliable for makeup:
  clean  -> /shop/clean-makeup     vegan -> /shop/vegan-makeup
Cruelty-free + planet-aware (sustainable) have NO category page (only client-side filters),
and give_back has no Sephora concept -> all three stay False and are flagged for vendor research.
cert_coverage = majority/minority of (clean products / total makeup products) per brand.
"""

import re

from playwright.sync_api import sync_playwright

from common import extract_linkstore, get, now, slug_from_url, write_brands

CDP = "http://localhost:9222"

CERT_PAGES = {
    "clean": "https://www.sephora.com/shop/clean-makeup",
    "vegan": "https://www.sephora.com/shop/vegan-makeup",
}
TOTAL_PAGE = "https://www.sephora.com/shop/makeup-cosmetics"  # denominator: total makeup per brand


def brand_refinement(page, url):
    page.goto(url, wait_until="domcontentloaded", timeout=45000)
    page.wait_for_timeout(3500)
    nc = extract_linkstore(page.content())["page"]["nthCategory"]
    out = {}
    for r in nc.get("refinements", []):
        vals = r.get("values") or []
        if vals and "filters[Brand]=" in str(vals[0].get("refinementValue", "")):
            for v in vals:
                name = re.sub(r".*filters\[Brand\]=", "", v.get("refinementValue", ""))
                if name:
                    out[name] = v.get("count")
            break
    return out


def load_brands_list():
    """341 canonical Sephora brands (name+url) from /brands-list (plain fetch, no Akamai)."""
    html = get("https://www.sephora.com/brands-list").text
    data = extract_linkstore(html)
    bl = [v for k, v in data["ssrProps"].items() if "BrandsList" in k and "groupedBrands" in v][0]
    return [
        {"name": b["shortName"].strip(), "url": "https://www.sephora.com" + b["targetUrl"]}
        for g in bl["groupedBrands"].values()
        for b in g["brands"]
    ]


def norm(s):
    return re.sub(r"[^a-z0-9]", "", (s or "").lower())


def main():
    with sync_playwright() as p:
        b = p.chromium.connect_over_cdp(CDP)
        page = b.contexts[0].new_page()
        total = brand_refinement(page, TOTAL_PAGE)
        cert = {col: brand_refinement(page, url) for col, url in CERT_PAGES.items()}
        page.close()
    for col, s in cert.items():
        print(f"  {col}: {len(s)} brands")
    print(f"  total-makeup denominator: {len(total)} brands")

    ntotal = {norm(k): v for k, v in total.items()}
    ncert = {col: {norm(k): v for k, v in s.items()} for col, s in cert.items()}

    brands = load_brands_list()
    ts = now()
    rows = []
    both = []
    for br in brands:
        k = norm(br["name"])
        clean = k in ncert["clean"]
        vegan = k in ncert["vegan"]
        tot = ntotal.get(k)
        cn = ncert["clean"].get(k)
        coverage = "all" if (clean and tot and cn and cn / tot > 0.5) else "some"
        rows.append(
            {
                "name": br["name"],
                "slug": slug_from_url(br["url"]),
                "source": "sephora",
                "url": br["url"],
                "clean": clean,
                "cruelty_free": False,
                "vegan": vegan,
                "sustainable": False,
                "give_back": False,
                "cert_coverage": coverage,
                "scraped_at": ts,
            }
        )
        if clean and vegan:
            both.append((br["name"], cn, ncert["vegan"].get(k), tot))

    path = write_brands(rows, "sephora")
    print(f"\nwrote {len(rows)} Sephora brands -> {path}")
    print(
        f"clean: {sum(r['clean'] for r in rows)}  vegan: {sum(r['vegan'] for r in rows)}  "
        f"clean&vegan: {len(both)}"
    )
    print("\n=== Sephora clean & vegan brands (cf/sustainable/give_back need vendor research) ===")
    for name, cn, vn, tot in sorted(both):
        print(f"  {name:28} clean={cn} vegan={vn} total_makeup={tot}")
    # name-drift report
    matched = {norm(b["name"]) for b in brands}
    for col in cert:
        un = [k for k in cert[col] if norm(k) not in matched]
        if un:
            print(f"  [warn] {col}: {len(un)} cert-page brands unmatched to brands-list: {un[:6]}")


if __name__ == "__main__":
    main()
