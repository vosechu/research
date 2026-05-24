# 02 — Shared Conventions

## HTTP

- **User-Agent** (all requests): `Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36`
- **Rate limit:** ~2 requests/second — enforce a minimum 0.5s gap between successive HTTP requests to the
  same retailer. (Browser-driven Sephora navigations are naturally slower; still be polite.)
- **Timeouts:** ~30s per request is sufficient.
- **Character encoding (critical):** Ulta returns `Content-Type: text/html` with **no charset**, but the
  bytes are UTF-8. Many HTTP clients (e.g. Python `requests`) default to ISO-8859-1 when no charset is
  declared, which silently mangles accented brand names (`Avène` → `AvÃ¨ne`, `L'Oréal` → `L'OrÃ©al`).
  **Always decode response bodies as UTF-8 when the server omits a charset** (detect/sniff, or force UTF-8).
  Sephora declares `charset=UTF-8`; Bluemercury JSON is UTF-8 by spec.
- Retailers serve different anti-bot postures — see per-source docs (Sephora needs a real browser).

## Embedded-JSON extraction (Ulta & Sephora)

Both sites server-render a large JSON blob inside a `<script>` tag. Extraction = locate the assignment,
then **brace-match** a balanced `{...}` object (a regex won't do — the JSON contains nested braces and
quoted strings). Brace-matcher rules: track string state, honor backslash escapes, count `{`/`}` depth
outside strings, stop when depth returns to 0.

- **Ulta:** `<script id='apollo_state'>` … find `__APOLLO_STATE__ =` … brace-match the object after `=`.
- **Sephora:** `<script id="linkStore" type="text/json">` … brace-match the first `{` after the tag.

## Normalization

- **Category values & attribute values:** lowercase. Trim surrounding whitespace. Store verbatim otherwise
  (do NOT singularize, de-pluralize, or re-map — keep the retailer's own wording; messiness is intentional
  and surfaced by the tag-sanity query).
- **`categories` array:** deduped and sorted ascending.
- **Brand-name matching** (only where one source must be matched to another list, e.g. Sephora cert sets
  to the brands-list): normalize by lowercasing and removing every non-alphanumeric character
  (`HAUS LABS BY LADY GAGA` → `hauslabsbyladygaga`). Used for matching only; stored `name` stays verbatim.

## Slugs

- **Ulta / Sephora:** last path segment of the brand `url` (strip trailing slash, take final `/`-segment, drop query).
- **Bluemercury:** vendor name lowercased with spaces → hyphens (the brand `url` itself replaces spaces with
  hyphens and `&`→`and`).

## `cert_coverage` (string: `all` | `some`)

Captures how much of a brand's assortment is certified, since non-Ulta certs are derived from product membership.

- **Ulta:** always `all` — Conscious Beauty badges are brand-level program certifications.
- **Derived sources (Sephora, Bluemercury):** `all` if a **majority** (>50%) of the brand's in-scope
  products carry the representative certification, else `some`. "Representative cert" per source:
  Sephora = clean ratio (clean products / total makeup products); Bluemercury = sustainability ratio.
  A boolean cert column is `true` whenever the brand has **≥1** qualifying product, independent of coverage.
- **Default:** `cert_coverage` is never null. A brand with **no** qualifying products (no certs, or the
  representative denominator is missing) gets `some`. So the column is always exactly `all` or `some`.

## Categories — definition

The retailer's own category label, lowercased, never invented:
- **Ulta:** the breadcrumb leaf of each category listing page (e.g. `Home > Makeup > Face > Concealer` → `concealer`).
- **Bluemercury:** the `collection::<x>` product tags, minus promo/structural noise (see 05).
- Combo products legitimately fall under multiple categories → all of them go in `categories[]`.

## Timestamps

`scraped_at` = the UTC instant of the run, microsecond precision, **the same value for every row written
in a single run**. Exclude from cross-run diffs.

## Checkpointing (operational, not part of the output)

Long crawls write resume state to `data/*_checkpoint.json` after each unit (category/page) so a crash
doesn't lose progress. Checkpoints are regenerable scratch and are **not** committed. A reproduction may
use any equivalent resume mechanism or none.
