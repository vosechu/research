"""Shared helpers: HTTP, embedded-JSON extraction, and parquet writing.

Used by every extractor. Keep retailer-specific parsing in the extractors; only put
genuinely shared primitives here.
"""

import json
import os
import re
import time
from datetime import datetime, timezone

import pyarrow as pa
import pyarrow.parquet as pq
import requests

DATA_DIR = os.path.join(os.path.dirname(__file__), "data")

UA = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
    "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"
)

# Explicit schemas so every source writes identical types. See docs/SPEC.md.
BRANDS_SCHEMA = pa.schema(
    [
        ("name", pa.string()),
        ("slug", pa.string()),
        ("source", pa.string()),
        ("url", pa.string()),
        ("clean", pa.bool_()),
        ("cruelty_free", pa.bool_()),
        ("vegan", pa.bool_()),
        ("sustainable", pa.bool_()),
        ("give_back", pa.bool_()),
        ("cert_coverage", pa.string()),
        ("scraped_at", pa.timestamp("us", tz="UTC")),
    ]
)

PRODUCTS_SCHEMA = pa.schema(
    [
        ("brand", pa.string()),
        ("source", pa.string()),
        ("name", pa.string()),
        ("url", pa.string()),
        ("categories", pa.list_(pa.string())),
        ("scraped_at", pa.timestamp("us", tz="UTC")),
    ]
)

# Tidy/long attribute table. One row per (product, attribute, value, confidence).
# confidence ∈ retailer_asserted | brand_website_asserted | inferred_from_title |
#   inferred_from_description
PRODUCT_ATTRIBUTES_SCHEMA = pa.schema(
    [
        ("brand", pa.string()),
        ("source", pa.string()),
        ("product_url", pa.string()),
        ("attribute", pa.string()),
        ("value", pa.string()),
        ("confidence", pa.string()),
        ("scraped_at", pa.timestamp("us", tz="UTC")),
    ]
)


# --- HTTP -------------------------------------------------------------------
_session = requests.Session()
_session.headers.update({"User-Agent": UA})
_last_request = [0.0]
MIN_INTERVAL = 0.5  # ~2 req/sec


def get(url, **kw):
    """Rate-limited GET (~2 req/sec), shared session, raises on HTTP error."""
    wait = MIN_INTERVAL - (time.monotonic() - _last_request[0])
    if wait > 0:
        time.sleep(wait)
    resp = _session.get(url, timeout=30, **kw)
    _last_request[0] = time.monotonic()
    resp.raise_for_status()
    # requests defaults .text to ISO-8859-1 when the server omits a charset (e.g. Ulta sends
    # bare "text/html"), which mangles UTF-8 accents. Detect the real encoding in that case.
    if "charset" not in resp.headers.get("Content-Type", "").lower():
        resp.encoding = resp.apparent_encoding or "utf-8"
    return resp


def now():
    return datetime.now(timezone.utc)


def slug_from_url(url):
    return url.rstrip("/").split("/")[-1] if url else None


# --- embedded-JSON extraction ----------------------------------------------
def match_balanced_json(text, search_from=0):
    """Parse the first balanced {...} object at/after `search_from`.

    String-aware brace matcher (a regex can't do this — the JSON nests braces and
    quotes). Tracks string state + backslash escapes, counts depth outside strings.
    """
    i = text.index("{", search_from)
    depth = 0
    instr = False
    esc = False
    for j in range(i, len(text)):
        c = text[j]
        if instr:
            if esc:
                esc = False
            elif c == "\\":
                esc = True
            elif c == '"':
                instr = False
        elif c == '"':
            instr = True
        elif c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                return json.loads(text[i : j + 1])
    raise ValueError("unterminated JSON object")


def extract_apollo_state(html):
    """window.__APOLLO_STATE__ object from Ulta's inline <script id='apollo_state'>."""
    m = re.search(r"<script id='apollo_state'>(.*?)</script>", html, re.S)
    if not m:
        raise ValueError("apollo_state script block not found")
    body = m.group(1)
    return match_balanced_json(body, body.index("=", body.index("__APOLLO_STATE__")))


def extract_linkstore(html):
    """page/ssrProps object from Sephora's <script id="linkStore" type="text/json">."""
    m = re.search(r'<script id="linkStore"[^>]*>', html)
    if not m:
        raise ValueError("linkStore script block not found")
    return match_balanced_json(html, m.end())


def find_modules_by_type(obj, type_name):
    """Recursively collect every dict whose 'type' == type_name."""
    found = []

    def walk(o):
        if isinstance(o, dict):
            if o.get("type") == type_name:
                found.append(o)
            for v in o.values():
                walk(v)
        elif isinstance(o, list):
            for v in o:
                walk(v)

    walk(obj)
    return found


# --- parquet writing --------------------------------------------------------
def _write_replacing_source(rows, schema, filename, source):
    """Write `rows` for `source`, replacing existing rows for that source (idempotent)."""
    os.makedirs(DATA_DIR, exist_ok=True)
    path = os.path.join(DATA_DIR, filename)
    new_tbl = pa.Table.from_pylist(rows, schema=schema)
    if os.path.exists(path):
        existing = pq.read_table(path, schema=schema)
        mask = [s != source for s in existing.column("source").to_pylist()]
        new_tbl = pa.concat_tables([existing.filter(pa.array(mask)), new_tbl])
    pq.write_table(new_tbl, path)
    return path


def write_brands(rows, source):
    return _write_replacing_source(rows, BRANDS_SCHEMA, "brands.parquet", source)


def write_products(rows, source):
    return _write_replacing_source(rows, PRODUCTS_SCHEMA, "products.parquet", source)


def write_attributes(rows, source):
    return _write_replacing_source(
        rows, PRODUCT_ATTRIBUTES_SCHEMA, "product_attributes.parquet", source
    )
