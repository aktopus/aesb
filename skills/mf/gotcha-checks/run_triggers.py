#!/usr/bin/env python3
"""Merge-flow step 5.5: run every gotcha-trigger in the gotcha library against a diff.

Usage (from the worktree root):
    git diff origin/main..HEAD | python3 run_triggers.py [--library PATH]

Each ```yaml gotcha-trigger:``` block in the library has `id`, `diff_pattern`, `check`. A trigger fires
when any diff line matches `diff_pattern` under `grep -E`; its `check` then runs from the current
directory with the full diff on stdin, and its stdout is the finding.

Two rules this script exists to enforce, because re-implementing the step by hand got both wrong
(2026-09-17):
- The fields are YAML `|` block scalars, which keep a trailing newline. Passed raw to `grep -E`, a
  newline splits the pattern in two and the empty second half matches EVERY line, so every rule fires
  on every diff. Both fields are stripped.
- The patterns are POSIX ERE (`[[:space:]]`). Python's `re` misreads those classes, so matching is
  done with `grep -E`, never `re`.

A pattern that still matches an empty line is reported as BROKEN and skipped: it would fire on any
diff, which is the failure above in a different form.

Output: one block per fired rule, then `Gotcha checker: K of N rules triggered`. Exit 0 always;
the checker never blocks a merge.
"""
import argparse
import re
import subprocess
import sys

DEFAULT_LIBRARY = "/Users/akpanoluo/code/vault/context/airflow-dag-gotchas.md"
BLOCK = re.compile(r"```ya?ml\s*\n(gotcha-trigger:.*?)```", re.S)


def grep_matches(pattern, text):
    r = subprocess.run(["grep", "-E", "-c", "--", pattern], input=text, capture_output=True, text=True)
    if r.returncode == 2:
        raise ValueError(r.stderr.strip() or "grep error")
    return int(r.stdout.strip() or 0)


def parse_block(raw):
    """The fixed trigger shape: `key: "scalar"` or `key: |` followed by an indented block. No PyYAML, so the
    runner works under any python3 on PATH."""
    fields, key, buf, indent = {}, None, [], None
    for line in raw.splitlines()[1:]:  # skip the `gotcha-trigger:` line
        m = re.match(r"^  ([a-z_]+):\s*(.*)$", line)
        if m and (key is None or not line.startswith(" " * (indent or 4))):
            if key is not None:
                fields[key] = "\n".join(buf)
            key, value, buf, indent = m.group(1), m.group(2).strip(), [], None
            if value != "|":
                fields[key] = value.strip('"\'')
                key = None
            continue
        if key is not None:
            if indent is None and line.strip():
                indent = len(line) - len(line.lstrip())
            buf.append(line[indent:] if indent and len(line) >= indent else line.strip())
    if key is not None:
        fields[key] = "\n".join(buf)
    return fields


def load_triggers(library):
    triggers = []
    for raw in BLOCK.findall(open(library).read()):
        try:
            t = parse_block(raw)
            triggers.append({"id": str(t["id"]).strip(),
                             "diff_pattern": str(t["diff_pattern"]).strip(),
                             "check": str(t["check"]).strip()})
        except Exception as e:  # malformed block: report, skip, keep going
            triggers.append({"id": None, "error": f"malformed gotcha-trigger block: {e}"})
    return triggers


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--library", default=DEFAULT_LIBRARY)
    args = ap.parse_args()
    diff = sys.stdin.read()
    # An empty diff (wrong cwd, branch already merged, `origin/main` not fetched) would print
    # "0 of N rules triggered" — the same line as a clean diff. Fail loudly instead.
    if not diff.strip():
        print("CHECKER PROBLEM: no diff on stdin, so nothing was checked "
              "(wrong directory, or HEAD == origin/main?)")
        sys.exit(2)

    triggers = load_triggers(args.library)
    fired, problems = [], []
    for t in triggers:
        if t.get("error"):
            problems.append(t["error"])
            continue
        try:
            if grep_matches(t["diff_pattern"], "\n"):
                problems.append(f"{t['id']}: BROKEN diff_pattern matches an empty line, so it would fire on any diff; skipped")
                continue
            if not grep_matches(t["diff_pattern"], diff):
                continue
        except ValueError as e:
            problems.append(f"{t['id']}: diff_pattern rejected by grep -E: {e}")
            continue
        r = subprocess.run(t["check"], shell=True, input=diff, capture_output=True, text=True)
        out = r.stdout.strip()
        if r.returncode != 0:
            out = (out + f"\n[check exited {r.returncode}] {r.stderr.strip()}").strip()
        if out:
            fired.append((t["id"], out))

    n = sum(1 for t in triggers if not t.get("error"))
    for rule_id, out in fired:
        print(f"[{rule_id}]\n{out}\n")
    for p in problems:
        print(f"CHECKER PROBLEM: {p}")
    print(f"Gotcha checker: {len(fired)} of {n} rules triggered")


if __name__ == "__main__":
    main()
