#!/usr/bin/env python3
"""Search and read past Claude Code session transcripts (~/.claude/projects/*/*.jsonl)."""
import argparse
import glob
import json
import os
import re
import sys
from datetime import datetime, timedelta, timezone

ROOT = os.path.expanduser("~/.claude/projects")
MESSAGE_TYPES = {"user", "assistant"}


def parse_time(value):
    if value.isdigit():
        epoch = int(value)
        if epoch > 10**12:
            epoch //= 1000
        return datetime.fromtimestamp(epoch, timezone.utc)
    parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    return parsed if parsed.tzinfo else parsed.replace(tzinfo=timezone.utc)


def session_files(project):
    pattern = f"{ROOT}/{project or '*'}"
    for path in glob.glob(f"{pattern}/*.jsonl") + glob.glob(f"{pattern}/*/subagents/*.jsonl"):
        parts = path.split(os.sep)
        if "subagents" in parts:
            session_id = parts[-3]
        else:
            session_id = os.path.basename(path)[:-6]
        yield path, session_id, parts[len(ROOT.split(os.sep))]


def flatten(content):
    """Yield (kind, text) for each piece of a message's content."""
    if isinstance(content, str):
        yield "text", content
        return
    for block in content or []:
        kind = block.get("type")
        if kind == "text":
            yield "text", block.get("text", "")
        elif kind == "tool_use":
            yield "tool_use", f"{block.get('name')}: {json.dumps(block.get('input'), ensure_ascii=False)}"
        elif kind == "tool_result":
            inner = block.get("content")
            if isinstance(inner, list):
                inner = " ".join(b.get("text", "") for b in inner if isinstance(b, dict))
            yield "tool_result", str(inner)


def records(path):
    with open(path, errors="replace") as handle:
        for line in handle:
            try:
                yield json.loads(line)
            except ValueError:
                continue


def resume_dir(project, cwds):
    """claude -r looks under the project dir, which is the cwd with non-alphanumerics as '-'."""
    for cwd in cwds:
        if re.sub(r"[^A-Za-z0-9]", "-", cwd) == project:
            return cwd
    return f"(no recorded cwd matches {project})"


def find(args):
    terms = [t.lower() for t in args.terms]
    at = parse_time(args.at) if args.at else None
    since = parse_time(args.since) if args.since else None
    found = {}
    scanned = 0
    for path, session_id, project in session_files(args.project):
        scanned += 1
        entry = found.setdefault(session_id, {
            "project": project, "path": path, "title": "", "cwd": None, "cwds": set(), "first": None, "last": None,
            "hits": dict.fromkeys(terms, 0), "snippet": None, "in_subagent": False,
        })
        for rec in records(path):
            if rec.get("cwd") and "subagents" not in path:
                entry["cwds"].add(rec["cwd"])
            if rec.get("type") == "custom-title":
                entry["title"] = rec.get("customTitle", "")
            if rec.get("type") not in MESSAGE_TYPES:
                continue
            stamp = rec.get("timestamp")
            if stamp:
                entry["first"] = min(filter(None, [entry["first"], stamp]))
                entry["last"] = max(filter(None, [entry["last"], stamp]))
            for kind, text in flatten(rec.get("message", {}).get("content")):
                lowered = text.lower()
                for term in terms:
                    count = lowered.count(term)
                    if not count:
                        continue
                    entry["hits"][term] += count
                    if entry["snippet"] is None:
                        pos = lowered.index(term)
                        entry["snippet"] = (stamp, kind, text[max(0, pos - 80):pos + 120].replace("\n", " "))
                    if "subagents" in path:
                        entry["in_subagent"] = True
    rows = []
    for session_id, entry in found.items():
        matched = sum(1 for n in entry["hits"].values() if n)
        if not matched or not entry["first"]:
            continue
        first, last = parse_time(entry["first"]), parse_time(entry["last"])
        if at and not (first - timedelta(hours=1) <= at <= last + timedelta(hours=1)):
            continue
        if since and last < since:
            continue
        rows.append((matched, sum(entry["hits"].values()), session_id, entry))
    rows.sort(key=lambda r: (-r[0], -r[1]))
    print(f"scanned {scanned} transcript files; {len(rows)} sessions match (showing {min(len(rows), args.limit)})")
    for matched, total, session_id, entry in rows[:args.limit]:
        print(f"\n{session_id}  [{entry['project']}]  {entry['first'][:16]} .. {entry['last'][:16]}"
              f"  {entry['title'] or '(untitled)'}")
        print(f"  terms matched {matched}/{len(terms)}, {total} hits {entry['hits']}"
              f"{'  (hit inside a subagent transcript)' if entry['in_subagent'] else ''}")
        print(f"  resume from {resume_dir(entry['project'], entry['cwds'])}")
        stamp, kind, snippet = entry["snippet"]
        print(f"  first hit {stamp[:19]} {kind}: ...{snippet}...")


def show(args):
    paths = [p for p, sid, _ in session_files(None) if sid == args.session_id and
             (args.subagents or "subagents" not in p)]
    if not paths:
        sys.exit(f"no transcript for session {args.session_id}")
    turns = []
    for path in sorted(paths):
        source = "subagent" if "subagents" in path else "main"
        for rec in records(path):
            if rec.get("type") not in MESSAGE_TYPES:
                continue
            role = rec["type"].upper()
            for kind, text in flatten(rec.get("message", {}).get("content")):
                if text.lstrip().startswith("<system-reminder>"):
                    continue
                label = {"tool_use": "TOOL", "tool_result": "RESULT"}.get(kind, role)
                turns.append((rec.get("timestamp", ""), source, label, text))
    turns.sort(key=lambda t: t[0])
    keep = set(range(len(turns)))
    if args.grep:
        needle = args.grep.lower()
        hits = [i for i, t in enumerate(turns) if needle in t[3].lower()]
        keep = {j for i in hits for j in range(i - args.context, i + args.context + 1)}
        print(f"{len(hits)} turns contain {args.grep!r}; showing +/-{args.context} around each")
    last_shown = None
    for i, (stamp, source, label, text) in enumerate(turns):
        if i not in keep:
            continue
        if last_shown is not None and i != last_shown + 1:
            print("   ...")
        last_shown = i
        body = text if len(text) <= args.max_chars else text[:args.max_chars] + f" [+{len(text) - args.max_chars} chars]"
        print(f"[{stamp[:19]}{' sub' if source == 'subagent' else ''}] {label}: {body}\n")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(required=True)
    p_find = sub.add_parser("find", help="rank sessions by how many search terms they contain")
    p_find.add_argument("terms", nargs="+", help="case-insensitive substrings; sessions matching more of them rank higher")
    p_find.add_argument("--project", help="project dir name under ~/.claude/projects (default: all)")
    p_find.add_argument("--at", help="keep sessions active at this ISO time or epoch (s or ms), +/-1h")
    p_find.add_argument("--since", help="keep sessions that ended on/after this ISO date")
    p_find.add_argument("--limit", type=int, default=8)
    p_find.set_defaults(fn=find)
    p_show = sub.add_parser("show", help="print a session's turns, optionally around a term")
    p_show.add_argument("session_id")
    p_show.add_argument("--grep", help="only turns near this substring")
    p_show.add_argument("--context", type=int, default=3, help="turns either side of each match")
    p_show.add_argument("--max-chars", type=int, default=700)
    p_show.add_argument("--subagents", action="store_true", help="merge subagent transcripts in")
    p_show.set_defaults(fn=show)
    args = parser.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
