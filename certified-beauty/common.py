"""Shared helpers: HTTP, Apollo-state extraction, and parquet writing."""
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

# Explicit schema so every source writes identical types into brands.parquet.
BRANDS_SCHEMA = pa.schema([
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
])

PRODUCTS_SCHEMA = pa.schema([
    ("brand", pa.string()),
    ("source", pa.string()),
    ("name", pa.string()),
    ("url", pa.string()),
    ("categories", pa.list_(pa.string())),
    ("scraped_at", pa.timestamp("us", tz="UTC")),
])

# Tidy/long attribute table. One row per (product, attribute, value, confidence).
# confidence ∈ retailer_asserted | brand_website_asserted | inferred_from_title | inferred_from_description
PRODUCT_ATTRIBUTES_SCHEMA = pa.schema([
    ("brand", pa.string()),
    ("source", pa.string()),
    ("product_url", pa.string()),
    ("attribute", pa.string()),
    ("value", pa.string()),
    ("confidence", pa.string()),
    ("scraped_at", pa.timestamp("us", tz="UTC")),
])

_session = requests.Session()
_session.headers.update({"User-Agent": UA})
_last_request = [0.0]
MIN_INTERVAL = 0.5  # ~2 req/sec


def get(url, **kw):
    """Rate-limited GET (~2 req/sec)."""
    wait = MIN_INTERVAL - (time.monotonic() - _last_request[0])
    if wait > 0:
        time.sleep(wait)
    resp = _session.get(url, timeout=30, **kw)
    _last_request[0] = time.monotonic()
    resp.raise_for_status()
    return resp


def now():
    return datetime.now(timezone.utc)


def slug_from_url(url):
    return url.rstrip("/").split("/")[-1] if url else None


def extract_apollo_state(html):
    """Pull window.__APOLLO_STATE__ object out of Ulta's inline script via brace matching."""
    m = re.search(r"<script id='apollo_state'>(.*?)</script>", html, re.S)
    if not m:
        raise ValueError("apollo_state script block not found")
    body = m.group(1)
    start = body.index("__APOLLO_STATE__")
    eq = body.index("=", start)
    i = body.index("{", eq)
    depth = 0
    instr = False
    esc = False
    for j in range(i, len(body)):
        c = body[j]
        if instr:
            if esc:
                esc = False
            elif c == "\\":
                esc = True
            elif c == '"':
                instr = False
        else:
            if c == '"':
                instr = True
            elif c == "{":
                depth += 1
            elif c == "}":
                depth -= 1
                if depth == 0:
                    return json.loads(body[i:j + 1])
    raise ValueError("unterminated __APOLLO_STATE__ object")


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


def write_brands(rows, source):
    """Write brand rows for `source`, replacing any existing rows for that source."""
    os.makedirs(DATA_DIR, exist_ok=True)
    path = os.path.join(DATA_DIR, "brands.parquet")
    new_tbl = pa.Table.from_pylist(rows, schema=BRANDS_SCHEMA)
    if os.path.exists(path):
        existing = pq.read_table(path, schema=BRANDS_SCHEMA)
        mask = [s != source for s in existing.column("source").to_pylist()]
        existing = existing.filter(pa.array(mask))
        new_tbl = pa.concat_tables([existing, new_tbl])
    pq.write_table(new_tbl, path)
    return path


def write_products(rows, source):
    """Write product rows for `source`, replacing any existing rows for that source."""
    os.makedirs(DATA_DIR, exist_ok=True)
    path = os.path.join(DATA_DIR, "products.parquet")
    new_tbl = pa.Table.from_pylist(rows, schema=PRODUCTS_SCHEMA)
    if os.path.exists(path):
        existing = pq.read_table(path, schema=PRODUCTS_SCHEMA)
        mask = [s != source for s in existing.column("source").to_pylist()]
        existing = existing.filter(pa.array(mask))
        new_tbl = pa.concat_tables([existing, new_tbl])
    pq.write_table(new_tbl, path)
    return path


def write_attributes(rows, source):
    """Write attribute rows for `source`, replacing any existing rows for that source."""
    os.makedirs(DATA_DIR, exist_ok=True)
    path = os.path.join(DATA_DIR, "product_attributes.parquet")
    new_tbl = pa.Table.from_pylist(rows, schema=PRODUCT_ATTRIBUTES_SCHEMA)
    if os.path.exists(path):
        existing = pq.read_table(path, schema=PRODUCT_ATTRIBUTES_SCHEMA)
        mask = [s != source for s in existing.column("source").to_pylist()]
        existing = existing.filter(pa.array(mask))
        new_tbl = pa.concat_tables([existing, new_tbl])
    pq.write_table(new_tbl, path)
    return path
