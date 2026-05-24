"""Extract Ulta brands + Conscious Beauty cert icons -> data/brands.parquet."""
import os
import sys

from common import (
    extract_apollo_state,
    find_modules_by_type,
    get,
    now,
    slug_from_url,
    write_brands,
)

INDEX_URL = "https://www.ulta.com/brand/all"
HTML_CACHE = os.path.join(os.path.dirname(__file__), "ulta_brands.html")

# Ulta Conscious Beauty pillar icon -> our boolean column.
ICON_MAP = {
    "Clean": "clean",
    "CrueltyFree": "cruelty_free",
    "Vegan": "vegan",
    "SustainablePackaging": "sustainable",
    "PositiveImpact": "give_back",
}


def load_html(refresh=False):
    if refresh or not os.path.exists(HTML_CACHE):
        html = get(INDEX_URL).text
        with open(HTML_CACHE, "w", encoding="utf-8") as f:
            f.write(html)
        return html
    with open(HTML_CACHE, encoding="utf-8") as f:
        return f.read()


def parse_brands(html):
    state = extract_apollo_state(html)
    modules = find_modules_by_type(state, "ShopAllBrands")
    if not modules:
        raise ValueError("ShopAllBrands module not found")
    sab = modules[0]
    ts = now()
    rows = []
    for group in sab.get("navItems", []):
        for item in group.get("items", []):
            action = item.get("action") or {}
            name = action.get("label")
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


def main():
    refresh = "--refresh" in sys.argv
    html = load_html(refresh=refresh)
    rows = parse_brands(html)
    path = write_brands(rows, "ulta")

    cert_cols = list(ICON_MAP.values())
    any_cert = sum(any(r[c] for c in cert_cols) for r in rows)
    all_five = sum(all(r[c] for c in cert_cols) for r in rows)
    print(f"parsed {len(rows)} Ulta brands")
    print(f"  {any_cert} with >=1 cert, {all_five} with all five")
    print(f"  wrote -> {path}")


if __name__ == "__main__":
    main()
