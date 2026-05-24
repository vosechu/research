"""Query scaffolding over the certified-beauty parquets + the spec's four sanity/headline queries.

Run: ./.venv/bin/python query.py   (writes all_five.md, prints the rest)
"""
import duckdb

con = duckdb.connect()
con.sql("CREATE VIEW brands     AS SELECT * FROM 'data/brands.parquet'")
con.sql("CREATE VIEW products   AS SELECT * FROM 'data/products.parquet'")
con.sql("CREATE VIEW attributes AS SELECT * FROM 'data/product_attributes.parquet'")


# 1. Fully-certified brands (all five booleans true at ANY source), grouped by retailer -> all_five.md
def all_five_md():
    rows = con.sql("""
        WITH five AS (
          SELECT DISTINCT name FROM brands
          WHERE clean AND cruelty_free AND vegan AND sustainable AND give_back
        )
        SELECT f.name,
               list_sort(list(DISTINCT b.source)) AS retailers
        FROM five f
        JOIN brands b ON b.name = f.name
        GROUP BY f.name ORDER BY f.name
    """).fetchall()
    lines = ["# Fully-certified brands (all five certifications)", "",
             f"_{len(rows)} brands where clean + cruelty_free + vegan + sustainable + give_back "
             "are all true at some retailer. Grouped by which retailers in this dataset carry them._", ""]
    by_combo = {}
    for name, retailers in rows:
        by_combo.setdefault(tuple(retailers), []).append(name)
    for combo in sorted(by_combo, key=lambda c: (-len(c), c)):
        lines.append(f"## carried at: {', '.join(combo)}")
        for n in sorted(by_combo[combo]):
            lines.append(f"- {n}")
        lines.append("")
    open("all_five.md", "w").write("\n".join(lines))
    print(f"[1] wrote all_five.md ({len(rows)} fully-certified brands)")


# 2. Category coverage for the fully-certified brands
def category_coverage():
    print("\n[2] category coverage for fully-certified brands (top 25):")
    print(con.sql("""
        WITH five AS (
          SELECT DISTINCT name FROM brands
          WHERE clean AND cruelty_free AND vegan AND sustainable AND give_back
        ), cats AS (
          SELECT p.brand, unnest(p.categories) AS cat
          FROM products p JOIN five f ON p.brand = f.name
        )
        SELECT cat, count(DISTINCT brand) AS brands, count(*) AS products
        FROM cats GROUP BY cat ORDER BY brands DESC, products DESC LIMIT 25
    """))


# 3. Headline — fully-certified brands carrying both a concealer and a bronzer
def headline():
    print("\n[3] fully-certified brands carrying BOTH concealer and bronzer:")
    print(con.sql("""
        WITH certified AS (
          SELECT DISTINCT name FROM brands
          WHERE clean AND cruelty_free AND vegan AND sustainable AND give_back
        )
        SELECT c.name FROM certified c
        WHERE EXISTS (SELECT 1 FROM products p WHERE p.brand=c.name AND list_contains(p.categories,'concealer'))
          AND EXISTS (SELECT 1 FROM products p WHERE p.brand=c.name AND list_contains(p.categories,'bronzer'))
        ORDER BY c.name
    """))


# 4. Tag sanity — how messy is the normalized category space
def tag_sanity():
    print("\n[4] category tag frequency (top 40):")
    print(con.sql("""
        SELECT cat, count(*) AS n FROM (
          SELECT unnest(categories) AS cat FROM products
        ) GROUP BY cat ORDER BY n DESC LIMIT 40
    """))


# bonus: "natural" retailer-asserted — light/sheer coverage + natural/radiant finish
def natural_bonus():
    print("\n[bonus] retailer-asserted 'natural' products (light/sheer coverage & natural/radiant finish):")
    print(con.sql("""
        WITH cov AS (SELECT DISTINCT source, product_url FROM attributes
                     WHERE confidence='retailer_asserted' AND attribute='coverage'
                       AND value IN ('light','sheer','sheer-light')),
             fin AS (SELECT DISTINCT source, product_url FROM attributes
                     WHERE confidence='retailer_asserted' AND attribute='finish'
                       AND value IN ('natural','radiant','dewy'))
        SELECT a.source, count(*) AS natural_products
        FROM cov a JOIN fin USING(source, product_url)
        GROUP BY a.source ORDER BY 2 DESC
    """))


if __name__ == "__main__":
    all_five_md()
    category_coverage()
    headline()
    tag_sanity()
    natural_bonus()
