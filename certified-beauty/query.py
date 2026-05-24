"""Query scaffolding over the certified-beauty parquets + the spec queries and analyses.

Run: ./.venv/bin/python query.py   (prints the spec queries + analyses)

Views:
  brands / products / attributes  -- raw scraped data (retailer-asserted)
  research                        -- vendor-site cert research (data/brand_certs.parquet)
  ethical                         -- per-brand 5-cert status = retailer flags UNION research
  capability                      -- per-brand makeup capability (Ulta + Bluemercury products only)
"""

import duckdb

con = duckdb.connect()
con.sql("CREATE VIEW brands     AS SELECT * FROM 'data/brands.parquet'")
con.sql("CREATE VIEW products   AS SELECT * FROM 'data/products.parquet'")
con.sql("CREATE VIEW attributes AS SELECT * FROM 'data/product_attributes.parquet'")
con.sql("CREATE VIEW research   AS SELECT * FROM 'data/brand_certs.parquet'")

# normalize a name/brand for cross-table joins (lowercase, alphanumeric only)
_N = "regexp_replace(lower({}), '[^a-z0-9]', '', 'g')"

# Enriched per-brand cert status. A cert is satisfied if a retailer flags it, OR research
# confirms it true, OR (vegan only) research found it "partial" (mostly-vegan, per the
# partial-tolerant policy). "unknown" or hard-false research does NOT satisfy a cert.
con.sql(f"""CREATE VIEW ethical AS
WITH retail AS (
  SELECT {_N.format("name")} bk, any_value(name) bname,
    max(clean::int)=1 clean, max(cruelty_free::int)=1 cf, max(vegan::int)=1 vegan,
    max(sustainable::int)=1 sust, max(give_back::int)=1 gb
  FROM brands GROUP BY 1),
res AS (
  SELECT {_N.format("brand")} bk,
    bool_or(cert='clean' AND value) cl_t,
    bool_or(cert='cruelty_free' AND value) cf_t,
    bool_or(cert='vegan' AND value) v_t,
    bool_or(cert='vegan' AND value=false AND note LIKE '%partial%') v_p,
    bool_or(cert='sustainable' AND value) su_t,
    bool_or(cert='give_back' AND value) gb_t
  FROM research GROUP BY 1)
SELECT r.bk, r.bname,
  (r.clean OR coalesce(s.cl_t,false)) clean,
  (r.cf OR coalesce(s.cf_t,false)) cruelty_free,
  (r.vegan OR coalesce(s.v_t,false) OR coalesce(s.v_p,false)) vegan,
  (r.sust OR coalesce(s.su_t,false)) sustainable,
  (r.gb OR coalesce(s.gb_t,false)) give_back
FROM retail r LEFT JOIN res s USING(bk)""")

# makeup capability per brand (products exist for Ulta + Bluemercury only). "sheer base" =
# a complexion product that is light/sheer coverage OR a tinted-moisturizer/skin-tint.
_COMPLEXION = (
    "['foundation','tinted moisturizer','tinted moisturizers','bb & cc creams',"
    "'bb and cc cream','concealer','under eye concealer','color correcting']"
)
con.sql(f"""CREATE VIEW capability AS
WITH cov AS (
  SELECT DISTINCT {_N.format("brand")} bk, product_url FROM attributes
  WHERE attribute='coverage' AND value IN ('light','sheer','sheer-light'))
SELECT {_N.format("p.brand")} bk,
  bool_or(list_has_any(p.categories, {_COMPLEXION})
          AND (c.product_url IS NOT NULL
               OR list_has_any(p.categories, ['tinted moisturizer','tinted moisturizers'])
               OR lower(p.name) LIKE '%skin tint%')) sheer_base,
  bool_or(list_has_any(p.categories, ['highlighter','highlighters and luminizers'])) highlighter,
  bool_or(list_has_any(p.categories, ['eyeshadow','eyeshadow palettes'])) eyeshadow,
  bool_or(list_contains(p.categories, 'eyeliner')) eyeliner
FROM products p LEFT JOIN cov c ON {_N.format("p.brand")}=c.bk AND p.url=c.product_url
GROUP BY 1""")

FULLY_CERTIFIED = "clean AND cruelty_free AND vegan AND sustainable AND give_back"


# 1. Fully-certified baseline on retailer flags alone (before vendor research)
def retailer_baseline():
    n = con.sql(f"SELECT count(DISTINCT name) FROM brands WHERE {FULLY_CERTIFIED}").fetchone()[0]
    print(f"[1] {n} fully-certified brands on retailer flags alone (before vendor research)")


# 2. Category coverage for fully-certified brands
def category_coverage():
    print("\n[2] category coverage for fully-certified brands (top 25):")
    print(
        con.sql(f"""
        WITH five AS (SELECT DISTINCT {_N.format("name")} bk FROM brands WHERE {FULLY_CERTIFIED}),
             cats AS (SELECT {_N.format("p.brand")} bk, unnest(p.categories) AS cat
                      FROM products p JOIN five f ON {_N.format("p.brand")}=f.bk)
        SELECT cat, count(DISTINCT bk) brands, count(*) products
        FROM cats GROUP BY cat ORDER BY brands DESC, products DESC LIMIT 25""")
    )


# 3. Headline — fully-certified brands carrying BOTH concealer and bronzer
def headline():
    print("\n[3] fully-certified brands carrying BOTH concealer and bronzer:")
    print(
        con.sql(f"""
        WITH certified AS (
          SELECT {_N.format("name")} bk, any_value(name) bname
          FROM brands WHERE {FULLY_CERTIFIED} GROUP BY 1),
        prod AS (SELECT {_N.format("brand")} bk, categories FROM products)
        SELECT c.bname FROM certified c
        WHERE EXISTS (SELECT 1 FROM prod p
                      WHERE p.bk=c.bk AND list_contains(p.categories,'concealer'))
          AND EXISTS (SELECT 1 FROM prod p
                      WHERE p.bk=c.bk AND list_contains(p.categories,'bronzer'))
        ORDER BY c.bname""")
    )


# 4. Tag sanity — category-tag frequency
def tag_sanity():
    print("\n[4] category tag frequency (top 40):")
    print(
        con.sql("""SELECT cat, count(*) n FROM (SELECT unnest(categories) cat FROM products)
        GROUP BY cat ORDER BY n DESC LIMIT 40""")
    )


# 5. Enriched fully-certified set (retailer UNION vendor research)
def ethical_summary():
    n = con.sql(f"SELECT count(*) FROM ethical WHERE {FULLY_CERTIFIED}").fetchone()[0]
    print(f"\n[5] fully-certified after vendor research (retailer ∪ research): {n} brands")


# 6. "Natural routine" — sheer skin-evener + highlighter + eyeshadow + eyeliner
def natural_routine():
    print("\n[6] ethical brands carrying sheer base + highlighter + eyeshadow + eyeliner")
    print("    (Ulta + Bluemercury products only; Sephora-only brands can't be evaluated):")
    print(
        con.sql(f"""
        SELECT e.bname AS brand FROM ethical e JOIN capability cap USING(bk)
        WHERE {FULLY_CERTIFIED}
          AND cap.sheer_base AND cap.highlighter AND cap.eyeshadow AND cap.eyeliner
        ORDER BY e.bname""")
    )


if __name__ == "__main__":
    retailer_baseline()
    category_coverage()
    headline()
    tag_sanity()
    ethical_summary()
    natural_routine()
