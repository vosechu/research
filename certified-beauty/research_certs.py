"""Load vendor-research findings (data/brand_certs_findings.json) -> data/brand_certs.parquet.

These are point-in-time, evidence-cited research results (NOT scraped retailer data); kept
separate from brands.parquet to preserve provenance. value: true/false/null(=unknown).
See docs/SPEC.md and PLAN.md. Re-run after editing the findings JSON.
"""

import glob
import json
import os

import pyarrow as pa
import pyarrow.parquet as pq

from common import now

HERE = os.path.dirname(__file__)
SCHEMA = pa.schema(
    [
        ("brand", pa.string()),
        ("cert", pa.string()),
        ("value", pa.bool_()),  # null = unknown
        ("confidence", pa.string()),
        ("evidence_url", pa.string()),
        ("note", pa.string()),
        ("researched_at", pa.timestamp("us", tz="UTC")),
    ]
)
_VAL = {"true": True, "false": False, "unknown": None}


def main():
    # merge every data/brand_certs_findings*.json (base file first wins on conflicts)
    files = sorted(glob.glob(os.path.join(HERE, "data", "brand_certs_findings*.json")))
    seen, findings = set(), []
    for fp in files:
        for x in json.load(open(fp)):
            k = (x["brand"], x["cert"])
            if k not in seen:
                seen.add(k)
                findings.append(x)
    ts = now()
    rows = [
        {
            "brand": f["brand"],
            "cert": f["cert"],
            "value": _VAL[f["value"]],
            "confidence": f["confidence"],
            "evidence_url": f["evidence_url"] or None,
            "note": f["note"],
            "researched_at": ts,
        }
        for f in findings
    ]
    path = os.path.join(HERE, "data", "brand_certs.parquet")
    pq.write_table(pa.Table.from_pylist(rows, schema=SCHEMA), path)
    from collections import Counter

    by = Counter(
        (r["cert"], {True: "true", False: "false", None: "unknown"}[r["value"]]) for r in rows
    )
    print(f"wrote {len(rows)} research rows -> {path}")
    for (cert, val), n in sorted(by.items()):
        print(f"  {cert:13} {val:8} {n}")


if __name__ == "__main__":
    main()
