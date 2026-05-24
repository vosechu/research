"""Export the most-ethical (fully-certified) brands x major face-makeup categories to CSV.

Cell semantics (per the request):
  - category cell  = semicolon list of retailers that carry that product type for the brand
                     (from Ulta+Bluemercury products); a non-empty cell == TRUE + where to buy it.
  - ""             = searched, brand has product data, but no product in that category.
  - "NULL"         = couldn't search (brand has no product data at all — e.g. Sephora-only).
  - retailers col  = every store that carries the brand (incl. Sephora, from brands.parquet).
  - cert cols      = basis of each cert: 'retailer' | 'research' | 'research-partial'.
"""
import csv
import re

import query as Q  # registers brands/products/ethical views; reuse its connection

con = Q.con


def nb(s):
    return re.sub("[^a-z0-9]", "", (s or "").lower())


FACE = {
    "foundation": ["foundation"],
    "tinted_moisturizer": ["tinted moisturizer", "tinted moisturizers"],
    "bb_cc_cream": ["bb & cc creams", "bb and cc cream"],
    "concealer": ["concealer", "under eye concealer"],
    "color_corrector": ["color correcting"],
    "face_primer": ["face primer", "primer"],
    "blush": ["blush"],
    "bronzer": ["bronzer"],
    "highlighter": ["highlighter", "highlighters and luminizers"],
    "setting_powder": ["setting spray & powder", "setting spray and powders"],
    "contouring": ["contouring"],
}
CERTS = ["clean", "cruelty_free", "vegan", "sustainable", "give_back"]

ethical = con.sql(f"SELECT bk, bname FROM ethical WHERE {Q.FULLY_CERTIFIED} ORDER BY lower(bname)").fetchall()

retailers = dict(con.sql(
    "SELECT regexp_replace(lower(name),'[^a-z0-9]','','g') bk, "
    "string_agg(DISTINCT source, ';' ORDER BY source) FROM brands GROUP BY 1").fetchall())
retail_flag = {(nb(n), c): v for n, c, v in con.sql(
    "SELECT name, cert, val FROM (SELECT name, "
    "max(clean::int)=1 clean, max(cruelty_free::int)=1 cruelty_free, max(vegan::int)=1 vegan, "
    "max(sustainable::int)=1 sustainable, max(give_back::int)=1 give_back FROM brands GROUP BY name) "
    "UNPIVOT (val FOR cert IN (clean, cruelty_free, vegan, sustainable, give_back))").fetchall()}
research = {}
for b, c, val, note in con.sql("SELECT brand, cert, value, note FROM research").fetchall():
    research[(nb(b), c)] = (val, note or "")
# "searchable" = carried at a retailer whose product catalog we have (Ulta/Bluemercury).
# A searchable brand with no product in a category => "" (searched, none); an unsearchable
# (Sephora-only) brand => "NULL" (couldn't search). NOT "is it in the products table".
SEARCHABLE = {"ulta", "bluemercury"}


def cert_basis(bk, cert):
    if retail_flag.get((bk, cert)):
        return "retailer"
    val, note = research.get((bk, cert), (None, ""))
    if val is True:
        return "research"
    if val is False and "partial" in note.lower():
        return "research-partial"
    return ""


cols = ["brand", "retailers", *CERTS, *FACE]
rows = []
for bk, bname in ethical:
    row = {"brand": bname, "retailers": retailers.get(bk, "")}
    for c in CERTS:
        row[c] = cert_basis(bk, c)
    hp = bool(set(retailers.get(bk, "").split(";")) & SEARCHABLE)
    for cat, variants in FACE.items():
        vlist = "[" + ",".join("'" + v.replace("'", "''") + "'" for v in variants) + "]"
        srcs = [r[0] for r in con.sql(
            f"SELECT DISTINCT source FROM products WHERE regexp_replace(lower(brand),'[^a-z0-9]','','g')='{bk}' "
            f"AND list_has_any(categories, {vlist}) ORDER BY source").fetchall()]
        row[cat] = ";".join(srcs) if srcs else ("" if hp else "NULL")
    rows.append(row)

with open("data/ethical_brands_face_makeup.csv", "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=cols)
    w.writeheader()
    w.writerows(rows)
print(f"wrote data/ethical_brands_face_makeup.csv: {len(rows)} brands x {len(FACE)} face categories")
print(f"  with product data (Ulta/BM): {sum(1 for r in rows if r['foundation'] != 'NULL')}")
print(f"  Sephora-only (all categories NULL): {sum(1 for r in rows if r['foundation'] == 'NULL')}")
