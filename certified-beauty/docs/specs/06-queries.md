# 06 — Queries

`query.py` registers three DuckDB views over the Parquet and runs four analysis queries plus a bonus.
Reproduce equivalently in any DuckDB-capable runtime (or translate the SQL).

```sql
CREATE VIEW brands     AS SELECT * FROM 'data/brands.parquet';
CREATE VIEW products   AS SELECT * FROM 'data/products.parquet';
CREATE VIEW attributes AS SELECT * FROM 'data/product_attributes.parquet';
```

"Fully certified" everywhere means all five booleans true: `clean AND cruelty_free AND vegan AND sustainable AND give_back`.

## 1. Fully-certified brands → `all_five.md`
Distinct brand names that are fully certified at **any** source, with the set of retailers (sources) that
carry each. Write a Markdown file grouped by retailer-combination. At snapshot these are the 24 Ulta brands.

```sql
WITH five AS (
  SELECT DISTINCT name FROM brands
  WHERE clean AND cruelty_free AND vegan AND sustainable AND give_back
)
SELECT f.name, list_sort(list(DISTINCT b.source)) AS retailers
FROM five f JOIN brands b ON b.name = f.name
GROUP BY f.name ORDER BY f.name;
```

## 2. Category coverage for fully-certified brands
Which categories the fully-certified brands cover (unnest the product categories).

```sql
WITH five AS (SELECT DISTINCT name FROM brands
              WHERE clean AND cruelty_free AND vegan AND sustainable AND give_back),
     cats AS (SELECT p.brand, unnest(p.categories) AS cat
              FROM products p JOIN five f ON p.brand = f.name)
SELECT cat, count(DISTINCT brand) AS brands, count(*) AS products
FROM cats GROUP BY cat ORDER BY brands DESC, products DESC;
```

## 3. Headline — fully-certified brands carrying BOTH concealer and bronzer

```sql
WITH certified AS (SELECT DISTINCT name FROM brands
                   WHERE clean AND cruelty_free AND vegan AND sustainable AND give_back)
SELECT c.name FROM certified c
WHERE EXISTS (SELECT 1 FROM products p WHERE p.brand=c.name AND list_contains(p.categories,'concealer'))
  AND EXISTS (SELECT 1 FROM products p WHERE p.brand=c.name AND list_contains(p.categories,'bronzer'))
ORDER BY c.name;
```
Snapshot result: `bareMinerals`. (Note: `list_contains(categories, x)` is DuckDB's form of the spec's
original `'x' = ANY(categories)`.)

## 4. Tag sanity — category-tag frequency
Reveals how messy the (deliberately un-normalized) category space is.

```sql
SELECT cat, count(*) AS n
FROM (SELECT unnest(categories) AS cat FROM products)
GROUP BY cat ORDER BY n DESC LIMIT 50;
```
Expect cross-retailer near-duplicates (e.g. `setting spray & powder` vs `setting spray and powders`,
`eyebrow` vs `eyebrows`) — intentional; do not pre-normalize them away.

## Bonus — retailer-asserted "natural" products
Products that are light/sheer coverage AND natural/radiant/dewy finish (per retailer-asserted attributes).

```sql
WITH cov AS (SELECT DISTINCT source, product_url FROM attributes
             WHERE confidence='retailer_asserted' AND attribute='coverage'
               AND value IN ('light','sheer','sheer-light')),
     fin AS (SELECT DISTINCT source, product_url FROM attributes
             WHERE confidence='retailer_asserted' AND attribute='finish'
               AND value IN ('natural','radiant','dewy'))
SELECT source, count(*) AS natural_products
FROM cov JOIN fin USING(source, product_url) GROUP BY source ORDER BY 2 DESC;
```
"Natural" = sheer/light coverage + natural/radiant finish (not color palette).
