# 07 — Vendor-Site Cert Research

Some certs aren't exposed by retailers (Sephora cruelty-free/sustainable/give-back; Bluemercury
cruelty-free/vegan/clean/give-back; give-back generally). These are filled by **researching each
brand's own site + third-party certifier directories**, kept in a separate, evidence-cited table so
provenance is never mixed with scraped retailer data.

## Output: `data/brand_certs.parquet`
Source of truth is `data/brand_certs_findings.json` (hand/agent-curated); `research_certs.py` loads it.
One row per (brand, cert):

| column | type | notes |
|---|---|---|
| `brand` | string | brand name (join to `brands.name` via normalized match, see 02) |
| `cert` | string | `clean` \| `cruelty_free` \| `vegan` \| `sustainable` \| `give_back` |
| `value` | bool (nullable) | true / false / **null = unknown** (couldn't determine) |
| `confidence` | string | `third_party_certified` > `brand_website_asserted` > `inferred` > `unknown` |
| `evidence_url` | string | the specific page relied on; **required** for any true/false (else value=null) |
| `note` | string | short qualifier, e.g. `partial`, `Leaping Bunny`, `1% for the Planet`, `sold in China` |
| `researched_at` | timestamp[us,UTC] | point-in-time |

## Rubric (objective anchors; do not guess — null if no citable source)
- **cruelty_free** — Leaping Bunny (leapingbunny.org) or PETA (crueltyfree.peta.org) listing, or explicit
  official no-animal-testing statement. Note mainland-China retail caveat.
- **vegan** — 100% vegan claim or vegan certification. Only-some-products vegan → `false` with note `partial`.
- **give_back** — 1% for the Planet, B Corp, or a documented charitable/donation program.
- **sustainable** — B Corp, 1% for the Planet, Climate Neutral, or documented sustainable packaging/sourcing
  (recyclable/refillable/PCR, sustainability report). Fuzzier; rely on these anchors.
- **clean** — no universal standard; left to retailer programs, not researched.

## How the research set is chosen
Prioritize brands **closest to fully certified** — those at 4/5 (missing exactly one cert), so confirming the
one gap flips them to all-5. Next, brands at 3/5, etc. Only research brands that already have ≥1 retailer flag.
Parallelize across subagents (~8 brands each), one identical rubric, JSON output → appended to the findings file.

## Consumption: the `ethical` view (in query.py)
A cert is **satisfied** if a retailer flags it **OR** research `value=true` **OR** (vegan only) research
found `partial` (mostly-vegan). `unknown` and hard-`false` do not satisfy. "Ethical" / fully-certified =
all five satisfied. This is a query-time policy over the two separate tables — the raw data is never overwritten.

Reproduction note: research is point-in-time and not deterministically reproducible (live web). A reproduction
should treat `brand_certs_findings.json` as input data, not something to regenerate from scratch.
