"""Export the most-ethical (fully-certified) brands x major face-makeup categories to CSV.

Cell semantics (per the request):
  - category cell  = "TRUE" if the brand has >=1 product of that type (Ulta+Bluemercury products).
  - ""             = searched (brand has product data) but no product in that category.
  - "NULL"         = couldn't search (brand has no product data at all — e.g. Sephora-only).
  - retailers col  = every store that carries the brand (incl. Sephora) — use this for where to buy.
  - cert cols      = basis of each cert: 'retailer' | 'research' | 'research-partial'.
  - verification_tier / verification_flags = a second, independent web check of the all-5 claim
    (data/brand_certs_verification.json): all5_verified > minor_partials > needs_docs > refuted,
    or not_verified if absent. verification_flags lists the flagged certs (e.g. "vegan:partial").
"""

import csv
import json
import os
import re

import query as Q  # registers brands/products/ethical views; reuse its connection

con = Q.con

# independent verification verdicts (brand -> {verdict, flags}); optional file
_vpath = "data/brand_certs_verification.json"
VERIF = json.load(open(_vpath)) if os.path.exists(_vpath) else {}

_NORM = "regexp_replace(lower({}), '[^a-z0-9]', '', 'g')"


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

ethical = con.sql(
    f"SELECT bk, bname FROM ethical WHERE {Q.FULLY_CERTIFIED} ORDER BY lower(bname)"
).fetchall()

retailers = dict(
    con.sql(
        f"SELECT {_NORM.format('name')} bk, string_agg(DISTINCT source, ';' ORDER BY source) "
        "FROM brands GROUP BY 1"
    ).fetchall()
)
# OR-merge each brand's cert flags across its retailer rows, grouping by the normalized name so
# two casings/punctuations of the same brand don't split into separate groups and clobber.
retail_flag = {
    (bk, cert): val
    for bk, cert, val in con.sql(
        f"SELECT bk, cert, val FROM (SELECT {_NORM.format('name')} bk, "
        "max(clean::int)=1 clean, max(cruelty_free::int)=1 cruelty_free, "
        "max(vegan::int)=1 vegan, max(sustainable::int)=1 sustainable, "
        "max(give_back::int)=1 give_back FROM brands GROUP BY 1) "
        "UNPIVOT (val FOR cert IN (clean, cruelty_free, vegan, sustainable, give_back))"
    ).fetchall()
}
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


def verification_tier(verdict, flags):
    """Grade the independent check so a broad line isn't penalized for minor exceptions.
    all5_verified (verdict confirmed all five) > minor_partials (only 'partial', e.g.
    vegan-except-honey/beeswax/carmine) > needs_docs (a cert plausible but undocumented) >
    refuted (a cert contradicted). verdict is authoritative; flags only sub-grades the rest."""
    if verdict == "all5_confirmed":
        return "all5_verified"
    statuses = [f.split(":", 1)[1].strip() for f in flags.split(";") if ":" in f]
    if "refuted" in statuses:
        return "refuted"
    if "unclear" in statuses:
        return "needs_docs"
    if statuses and all(s == "partial" for s in statuses):
        return "minor_partials"
    return "needs_docs"


verif_n = {nb(k): v for k, v in VERIF.items()}
cols = ["brand", "retailers", *CERTS, "verification_tier", "verification_flags", *FACE]
rows = []
for bk, bname in ethical:
    row = {"brand": bname, "retailers": retailers.get(bk, "")}
    for c in CERTS:
        row[c] = cert_basis(bk, c)
    v = verif_n.get(nb(bname), {})
    row["verification_flags"] = v.get("flags", "")
    row["verification_tier"] = (
        verification_tier(v.get("verdict", ""), v.get("flags", "")) if v else "not_verified"
    )
    hp = bool(set(retailers.get(bk, "").split(";")) & SEARCHABLE)
    for cat, variants in FACE.items():
        vlist = "[" + ",".join("'" + v.replace("'", "''") + "'" for v in variants) + "]"
        srcs = [
            r[0]
            for r in con.sql(
                f"SELECT DISTINCT source FROM products "
                f"WHERE {_NORM.format('brand')}='{bk}' AND list_has_any(categories, {vlist}) "
                "ORDER BY source"
            ).fetchall()
        ]
        row[cat] = "TRUE" if srcs else ("" if hp else "NULL")
    rows.append(row)

TIER_ORDER = {
    "all5_verified": 0,
    "minor_partials": 1,
    "needs_docs": 2,
    "refuted": 3,
    "not_verified": 4,
}
PREP_ONLY = {"face_primer", "setting_powder"}
CORE_MAKEUP = [c for c in FACE if c not in PREP_ONLY]

# diagnostics over ALL ethical brands, before the next filter drops the Sephora-only ones
# (a brand's foundation cell is "NULL" iff it has no Ulta/Bluemercury product data at all).
searchable_count = sum(1 for r in rows if r["foundation"] != "NULL")
sephora_only_count = len(rows) - searchable_count

# keep only brands with >=1 real color-makeup product. Drop hair/skin/fragrance-only AND
# skincare/SPF brands whose only "makeup" is a primer or setting spray (prep, not color).
# Then sort by verification tier (best first), then brand name.
rows = [r for r in rows if any(r[c] == "TRUE" for c in CORE_MAKEUP)]
rows.sort(key=lambda r: (TIER_ORDER.get(r["verification_tier"], 9), r["brand"].lower()))

with open("data/ethical_brands_face_makeup.csv", "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=cols)
    w.writeheader()
    w.writerows(rows)
print(f"wrote data/ethical_brands_face_makeup.csv: {len(rows)} brands x {len(FACE)} categories")
print(
    f"  from {searchable_count + sephora_only_count} ethical brands: "
    f"{searchable_count} searchable (Ulta/BM), {sephora_only_count} Sephora-only (dropped)"
)
