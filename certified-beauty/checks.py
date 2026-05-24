"""Data-correctness checks over the parquet outputs. Run: ./.venv/bin/python checks.py

Prints PASS / WARN / FAIL per check and exits non-zero if any FAIL. WARN = worth a human
look (e.g. intentional category messiness), not necessarily a bug.
"""

import sys

import duckdb

con = duckdb.connect()
B = "'data/brands.parquet'"
P = "'data/products.parquet'"
A = "'data/product_attributes.parquet'"

SOURCES = {"ulta", "sephora", "bluemercury"}
CONFIDENCES = {
    "retailer_asserted",
    "brand_website_asserted",
    "inferred_from_title",
    "inferred_from_description",
}
ATTRIBUTES = {"coverage", "finish", "natural_beauty", "ingredient_preference"}
# loose expected vocab for the natural-look axes (WARN on anything else)
COVERAGE_VALUES = {"light", "sheer", "sheer-light", "buildable", "medium", "full"}
FINISH_VALUES = {
    "natural",
    "radiant",
    "dewy",
    "matte",
    "satin",
    "shimmer",
    "shine",
    "high shine",
    "metallic",
    "iridescent",
    "glitter",
    "creme",
    "sheer",
}

results = []  # (level, name, detail)


def rec(level, name, detail=""):
    results.append((level, name, detail))


def q1(sql):
    return con.sql(sql).fetchone()[0]


def rows(sql):
    return con.sql(sql).fetchall()


# 1. enums / source domains
for f, name in [(B, "brands"), (P, "products"), (A, "attributes")]:
    bad = q1(f"SELECT count(*) FROM {f} WHERE source NOT IN ('ulta','sephora','bluemercury')")
    rec("FAIL" if bad else "PASS", f"{name}.source domain", f"{bad} bad" if bad else "")

bad = q1(f"SELECT count(*) FROM {B} WHERE cert_coverage NOT IN ('all','some')")
rec("FAIL" if bad else "PASS", "brands.cert_coverage domain", f"{bad} bad")
bad = q1(f"SELECT count(*) FROM {A} WHERE confidence NOT IN {tuple(CONFIDENCES)}")
rec("FAIL" if bad else "PASS", "attributes.confidence domain", f"{bad} bad")
bad = q1(f"SELECT count(*) FROM {A} WHERE attribute NOT IN {tuple(ATTRIBUTES)}")
rec("FAIL" if bad else "PASS", "attributes.attribute domain", f"{bad} bad")

# 2. mojibake / encoding (scan brand+name+category+value)
b_m = q1(f"SELECT count(*) FROM {B} WHERE name LIKE '%Ã%' OR name LIKE '%�%'")
p_m = q1(f"SELECT count(*) FROM {P} WHERE brand LIKE '%Ã%' OR name LIKE '%Ã%' OR name LIKE '%�%'")
a_m = q1(f"SELECT count(*) FROM {A} WHERE brand LIKE '%Ã%' OR value LIKE '%Ã%'")
c_m = q1(f"SELECT count(*) FROM (SELECT unnest(categories) c FROM {P}) WHERE c LIKE '%Ã%'")
tot_m = b_m + p_m + a_m + c_m
rec(
    "FAIL" if tot_m else "PASS",
    "no mojibake",
    f"brands={b_m} products={p_m} attrs={a_m} categories={c_m}",
)

# 3. duplicates
d = q1(f"SELECT count(*) FROM (SELECT name,source,count(*) c FROM {B} GROUP BY 1,2 HAVING c>1)")
rec("FAIL" if d else "PASS", "brands unique (name,source)", f"{d} dup keys")
d = q1(f"SELECT count(*) FROM (SELECT source,url,count(*) c FROM {P} GROUP BY 1,2 HAVING c>1)")
rec("FAIL" if d else "PASS", "products unique (source,url)", f"{d} dup keys")
d = q1(
    f"SELECT count(*) FROM (SELECT source,product_url,attribute,value,confidence,count(*) c "
    f"FROM {A} GROUP BY 1,2,3,4,5 HAVING c>1)"
)
rec("FAIL" if d else "PASS", "attributes unique key", f"{d} dup keys")

# 4. nulls / empties
n = q1(f"SELECT count(*) FROM {B} WHERE name IS NULL OR url IS NULL")
rec("FAIL" if n else "PASS", "brands no null name/url", f"{n} null")
n = q1(f"SELECT count(*) FROM {P} WHERE brand IS NULL OR name IS NULL OR url IS NULL")
rec("FAIL" if n else "PASS", "products no null brand/name/url", f"{n} null")
empty = q1(f"SELECT count(*) FROM {P} WHERE len(categories)=0")
rec("WARN" if empty else "PASS", "products have categories", f"{empty} with empty categories[]")

# 5. referential integrity (within source)
orphan = q1(f"""SELECT count(*) FROM (SELECT DISTINCT brand,source FROM {P}) p
  WHERE NOT EXISTS (SELECT 1 FROM {B} b WHERE b.name=p.brand AND b.source=p.source)""")
rec(
    "WARN" if orphan else "PASS",
    "products.brand ∈ brands(name,source)",
    f"{orphan} product-brands with no brands row (drops them from cert joins)",
)
orphan_a = q1(f"""SELECT count(*) FROM (SELECT DISTINCT product_url,source FROM {A}) a
  WHERE NOT EXISTS (SELECT 1 FROM {P} p WHERE p.url=a.product_url AND p.source=a.source)""")
rec(
    "WARN" if orphan_a else "PASS",
    "attributes.product_url ∈ products(url)",
    f"{orphan_a} attribute urls with no product row",
)

# 6. cert_coverage logic: Ulta always 'all'
bad = q1(f"SELECT count(*) FROM {B} WHERE source='ulta' AND cert_coverage<>'all'")
rec("FAIL" if bad else "PASS", "ulta cert_coverage all = 'all'", f"{bad} bad")

# 7. attribute value vocab (WARN on unexpected)
covbad = [
    r[0]
    for r in rows(f"SELECT DISTINCT value FROM {A} WHERE attribute='coverage'")
    if r[0] not in COVERAGE_VALUES
]
finbad = [
    r[0]
    for r in rows(f"SELECT DISTINCT value FROM {A} WHERE attribute='finish'")
    if r[0] not in FINISH_VALUES
]
rec("WARN" if covbad else "PASS", "coverage value vocab", f"unexpected: {covbad}" if covbad else "")
rec("WARN" if finbad else "PASS", "finish value vocab", f"unexpected: {finbad}" if finbad else "")

# --- report ---
order = {"FAIL": 0, "WARN": 1, "PASS": 2}
for level, name, detail in sorted(results, key=lambda r: order[r[0]]):
    mark = {"PASS": "✓", "WARN": "!", "FAIL": "✗"}[level]
    print(f"  [{mark}] {level:4} {name}" + (f"  — {detail}" if detail else ""))

n_fail = sum(1 for r in results if r[0] == "FAIL")
n_warn = sum(1 for r in results if r[0] == "WARN")
print(
    f"\n{len(results)} checks: {n_fail} FAIL, {n_warn} WARN, {len(results) - n_fail - n_warn} PASS"
)
sys.exit(1 if n_fail else 0)
