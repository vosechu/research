"""Data-correctness checks over the parquet outputs. Run: ./.venv/bin/python checks.py

Prints PASS / WARN / FAIL per check and exits non-zero if any FAIL. WARN = worth a human
look (e.g. intentional category messiness), not necessarily a bug.
"""

import sys

import duckdb

BRANDS = "'data/brands.parquet'"
PRODUCTS = "'data/products.parquet'"
ATTRIBUTES = "'data/product_attributes.parquet'"

SOURCES = {"ulta", "sephora", "bluemercury"}
CONFIDENCES = {
    "retailer_asserted",
    "brand_website_asserted",
    "inferred_from_title",
    "inferred_from_description",
}
ATTRIBUTE_NAMES = {"coverage", "finish", "natural_beauty", "ingredient_preference"}
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


def main():
    con = duckdb.connect()
    results = []  # (level, name, detail)

    def record(level, name, detail=""):
        results.append((level, name, detail))

    def scalar(sql):
        return con.sql(sql).fetchone()[0]

    def distinct_values(sql):
        return [row[0] for row in con.sql(sql).fetchall()]

    # 1. enums / source domains
    for table, name in [(BRANDS, "brands"), (PRODUCTS, "products"), (ATTRIBUTES, "attributes")]:
        bad = scalar(f"SELECT count(*) FROM {table} WHERE source NOT IN {tuple(SOURCES)}")
        record("FAIL" if bad else "PASS", f"{name}.source domain", f"{bad} bad" if bad else "")

    bad = scalar(f"SELECT count(*) FROM {BRANDS} WHERE cert_coverage NOT IN ('all','some')")
    record("FAIL" if bad else "PASS", "brands.cert_coverage domain", f"{bad} bad")
    bad = scalar(f"SELECT count(*) FROM {ATTRIBUTES} WHERE confidence NOT IN {tuple(CONFIDENCES)}")
    record("FAIL" if bad else "PASS", "attributes.confidence domain", f"{bad} bad")
    bad = scalar(
        f"SELECT count(*) FROM {ATTRIBUTES} WHERE attribute NOT IN {tuple(ATTRIBUTE_NAMES)}"
    )
    record("FAIL" if bad else "PASS", "attributes.attribute domain", f"{bad} bad")

    # 2. mojibake / encoding (scan brand+name+category+value)
    brands_mojibake = scalar(
        f"SELECT count(*) FROM {BRANDS} WHERE name LIKE '%Ã%' OR name LIKE '%�%'"
    )
    products_mojibake = scalar(
        f"SELECT count(*) FROM {PRODUCTS} "
        f"WHERE brand LIKE '%Ã%' OR name LIKE '%Ã%' OR name LIKE '%�%'"
    )
    attributes_mojibake = scalar(
        f"SELECT count(*) FROM {ATTRIBUTES} WHERE brand LIKE '%Ã%' OR value LIKE '%Ã%'"
    )
    categories_mojibake = scalar(
        f"SELECT count(*) FROM (SELECT unnest(categories) c FROM {PRODUCTS}) WHERE c LIKE '%Ã%'"
    )
    total_mojibake = brands_mojibake + products_mojibake + attributes_mojibake + categories_mojibake
    record(
        "FAIL" if total_mojibake else "PASS",
        "no mojibake",
        f"brands={brands_mojibake} products={products_mojibake} "
        f"attrs={attributes_mojibake} categories={categories_mojibake}",
    )

    # 2b. leading/trailing whitespace in names (collides on normalized joins -> wrong cert merges)
    whitespace_fields = (
        scalar(f"SELECT count(*) FROM {BRANDS} WHERE name <> trim(name)")
        + scalar(
            f"SELECT count(*) FROM {PRODUCTS} WHERE brand <> trim(brand) OR name <> trim(name)"
        )
        + scalar(
            f"SELECT count(*) FROM {ATTRIBUTES} WHERE brand <> trim(brand) OR value <> trim(value)"
        )
    )
    record(
        "FAIL" if whitespace_fields else "PASS",
        "no leading/trailing whitespace in names",
        f"{whitespace_fields} fields",
    )

    # 3. duplicates
    dup_keys = scalar(
        f"SELECT count(*) FROM "
        f"(SELECT name,source,count(*) c FROM {BRANDS} GROUP BY 1,2 HAVING c>1)"
    )
    record("FAIL" if dup_keys else "PASS", "brands unique (name,source)", f"{dup_keys} dup keys")
    dup_keys = scalar(
        f"SELECT count(*) FROM "
        f"(SELECT source,url,count(*) c FROM {PRODUCTS} GROUP BY 1,2 HAVING c>1)"
    )
    record("FAIL" if dup_keys else "PASS", "products unique (source,url)", f"{dup_keys} dup keys")
    dup_keys = scalar(
        f"SELECT count(*) FROM (SELECT source,product_url,attribute,value,confidence,count(*) c "
        f"FROM {ATTRIBUTES} GROUP BY 1,2,3,4,5 HAVING c>1)"
    )
    record("FAIL" if dup_keys else "PASS", "attributes unique key", f"{dup_keys} dup keys")

    # 4. nulls / empties
    null_count = scalar(f"SELECT count(*) FROM {BRANDS} WHERE name IS NULL OR url IS NULL")
    record("FAIL" if null_count else "PASS", "brands no null name/url", f"{null_count} null")
    null_count = scalar(
        f"SELECT count(*) FROM {PRODUCTS} WHERE brand IS NULL OR name IS NULL OR url IS NULL"
    )
    record(
        "FAIL" if null_count else "PASS", "products no null brand/name/url", f"{null_count} null"
    )
    empty_categories = scalar(f"SELECT count(*) FROM {PRODUCTS} WHERE len(categories)=0")
    record(
        "WARN" if empty_categories else "PASS",
        "products have categories",
        f"{empty_categories} with empty categories[]",
    )

    # 5. referential integrity (within source)
    orphan_products = scalar(
        f"""
        SELECT count(*) FROM (SELECT DISTINCT brand,source FROM {PRODUCTS}) p
        WHERE NOT EXISTS (
          SELECT 1 FROM {BRANDS} b WHERE b.name=p.brand AND b.source=p.source)"""
    )
    record(
        "WARN" if orphan_products else "PASS",
        "products.brand ∈ brands(name,source)",
        f"{orphan_products} product-brands with no brands row (drops them from cert joins)",
    )
    orphan_attributes = scalar(
        f"""
        SELECT count(*) FROM (SELECT DISTINCT product_url,source FROM {ATTRIBUTES}) a
        WHERE NOT EXISTS (
          SELECT 1 FROM {PRODUCTS} p WHERE p.url=a.product_url AND p.source=a.source)"""
    )
    record(
        "WARN" if orphan_attributes else "PASS",
        "attributes.product_url ∈ products(url)",
        f"{orphan_attributes} attribute urls with no product row",
    )

    # 6. cert_coverage logic: Ulta always 'all'
    bad = scalar(f"SELECT count(*) FROM {BRANDS} WHERE source='ulta' AND cert_coverage<>'all'")
    record("FAIL" if bad else "PASS", "ulta cert_coverage all = 'all'", f"{bad} bad")

    # 7. attribute value vocab (WARN on unexpected)
    coverage_unexpected = [
        value
        for value in distinct_values(
            f"SELECT DISTINCT value FROM {ATTRIBUTES} WHERE attribute='coverage'"
        )
        if value not in COVERAGE_VALUES
    ]
    finish_unexpected = [
        value
        for value in distinct_values(
            f"SELECT DISTINCT value FROM {ATTRIBUTES} WHERE attribute='finish'"
        )
        if value not in FINISH_VALUES
    ]
    record(
        "WARN" if coverage_unexpected else "PASS",
        "coverage value vocab",
        f"unexpected: {coverage_unexpected}" if coverage_unexpected else "",
    )
    record(
        "WARN" if finish_unexpected else "PASS",
        "finish value vocab",
        f"unexpected: {finish_unexpected}" if finish_unexpected else "",
    )

    # --- report ---
    order = {"FAIL": 0, "WARN": 1, "PASS": 2}
    for level, name, detail in sorted(results, key=lambda item: order[item[0]]):
        mark = {"PASS": "✓", "WARN": "!", "FAIL": "✗"}[level]
        print(f"  [{mark}] {level:4} {name}" + (f"  — {detail}" if detail else ""))

    n_fail = sum(1 for result in results if result[0] == "FAIL")
    n_warn = sum(1 for result in results if result[0] == "WARN")
    print(
        f"\n{len(results)} checks: {n_fail} FAIL, {n_warn} WARN, "
        f"{len(results) - n_fail - n_warn} PASS"
    )
    sys.exit(1 if n_fail else 0)


if __name__ == "__main__":
    main()
