#!/usr/bin/env python3
"""Per-worker turn and cost ledger for one Claude Code session.

Usage:
    swarm-ledger.py                 # newest session under the cwd's project dir
    swarm-ledger.py <session-id>    # a specific session
    swarm-ledger.py <session-id> --md   # markdown table for pasting into a ledger

Reads <project>/<sid>.jsonl (the orchestrator) and <project>/<sid>/subagents/agent-*.jsonl
(the workers; the sidecar .meta.json carries the worker's name and model). Prices at list
API rates per model family, the same yardstick the 2026-09-09 subagent cost audit used:
ratios are the finding, dollars are a consistent proxy, not a bill. Cache writes are
priced at the 5-minute rate, so sessions on the 1-hour TTL are understated by up to 2x on
that column. Subscription usage is weighted differently again; this is the API yardstick.
"""
import glob
import json
import os
import sys

# $/MTok: input, output, cache_write (5-min, 1.25x input), cache_read. List rates from the
# claude-api reference table cached 2026-06-24 (Fable 5.1 10/50 with cache read 0.25; Opus 5
# 5/25; Sonnet 5 2/10; Haiku 4.5 1/5). The 2026-09-09 audit priced at the previous
# generation's rates (Opus 15/75, Sonnet 3/15), so its dollars run high; its ratios stand.
PRICE = {
    "fable": (10.0, 50.0, 12.5, 0.25),
    "opus": (5.0, 25.0, 6.25, 0.50),
    "sonnet": (2.0, 10.0, 2.5, 0.20),
    "haiku": (1.0, 5.0, 1.25, 0.10),
}


def family(model):
    m = (model or "").lower()
    for k in ("fable", "mythos", "opus", "haiku", "sonnet"):
        if k in m:
            return "fable" if k == "mythos" else k
    return "sonnet"


ROOT = os.path.expanduser("~/.claude/projects")


def project_dir():
    slug = "-" + os.getcwd().strip("/").replace("/", "-")
    return f"{ROOT}/{slug}"


def locate(sid):
    """Find the project dir holding <sid>.jsonl, whatever the cwd is."""
    hits = glob.glob(f"{ROOT}/*/{sid}.jsonl")
    if not hits:
        sys.exit(f"no transcript named {sid}.jsonl under {ROOT}")
    return os.path.dirname(hits[0])


def usage_rows(path):
    turns, tok = 0, [0, 0, 0, 0]
    model = None
    with open(path, errors="replace") as f:
        for line in f:
            if '"usage"' not in line:
                continue
            try:
                d = json.loads(line)
            except ValueError:
                continue
            msg = d.get("message") or {}
            u = msg.get("usage") if isinstance(msg, dict) else None
            if not u:
                continue
            turns += 1
            model = msg.get("model") or model
            tok[0] += u.get("input_tokens", 0) or 0
            tok[1] += u.get("output_tokens", 0) or 0
            tok[2] += u.get("cache_creation_input_tokens", 0) or 0
            tok[3] += u.get("cache_read_input_tokens", 0) or 0
    return turns, tok, model


def cost(tok, model):
    i, o, w, r = PRICE[family(model)]
    return (tok[0] * i + tok[1] * o + tok[2] * w + tok[3] * r) / 1e6


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    md = "--md" in sys.argv
    if args:
        sid = args[0]
        proj = locate(sid)
    else:
        proj = project_dir()
        files = sorted(glob.glob(f"{proj}/*.jsonl"), key=os.path.getmtime)
        if not files:
            sys.exit(f"no sessions under {proj}; pass a session id")
        sid = os.path.basename(files[-1])[:-6]
    rows = []
    orch = f"{proj}/{sid}.jsonl"
    if os.path.exists(orch):
        t, tok, model = usage_rows(orch)
        rows.append(("orchestrator", family(model), t, tok, cost(tok, model)))
    for path in sorted(glob.glob(f"{proj}/{sid}/subagents/agent-*.jsonl")):
        meta = {}
        try:
            with open(path[:-6] + ".meta.json") as f:
                meta = json.load(f)
        except (OSError, ValueError):
            pass
        t, tok, model = usage_rows(path)
        name = meta.get("name") or os.path.basename(path)[6:-6]
        rows.append((name, family(meta.get("model") or model), t, tok, cost(tok, model)))
    total = sum(r[4] for r in rows)
    hdr = ("worker", "model", "turns", "cache_read_M", "output_k", "est_$")
    fmt = "| {} | {} | {} | {} | {} | {} |" if md else "{:<32} {:<7} {:>6} {:>13} {:>9} {:>8}"
    print(fmt.format(*hdr))
    if md:
        print("| --- | --- | ---: | ---: | ---: | ---: |")
    for name, fam, t, tok, c in rows:
        print(fmt.format(name, fam, t, f"{tok[3]/1e6:.1f}", f"{tok[1]/1e3:.1f}", f"{c:.2f}"))
    print(fmt.format("TOTAL", "", sum(r[2] for r in rows), "", "", f"{total:.2f}"))
    print(f"\nsession {sid}")


if __name__ == "__main__":
    main()
