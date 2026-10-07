#!/usr/bin/env bash
# Tests for run_triggers.py against a throwaway library, so they don't drift with the real one.
#   1. a neutral diff fires nothing            (catches the trailing-newline bug: it fired every rule)
#   2. a matching diff fires exactly that rule (positive control: the runner can still go red)
#   3. a pattern that matches an empty line is reported BROKEN, not fired
#   4. POSIX classes work ([[:space:]])        (catches matching with Python re instead of grep -E)
#   5. an empty diff exits 2 with a CHECKER PROBLEM, never "0 of N" (which reads as a clean pass)
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
FAILED=0

cat > "$TMP/lib.md" <<'EOF'
```yaml
gotcha-trigger:
  id: "posix-create-table"
  diff_pattern: |
    ^\+.*[Cc][Rr][Ee][Aa][Tt][Ee][[:space:]]+[Tt][Aa][Bb][Ll][Ee][[:space:]]+
  check: |
    echo "posix-create-table: fired"
```

```yaml
gotcha-trigger:
  id: "matches-everything"
  diff_pattern: |
    (^\+.*foo)?
  check: |
    echo "matches-everything: fired"
```
EOF

run() { python3 "$DIR/run_triggers.py" --library "$TMP/lib.md"; }
expect() {  # name, haystack, needle, present(1)/absent(0)
    if grep -qF -- "$3" <<<"$2"; then got=1; else got=0; fi
    if [[ "$got" == "$4" ]]; then echo "PASS: $1"; else echo "FAIL: $1"; echo "$2" | sed 's/^/    /'; FAILED=1; fi
}

neutral="$(printf '+++ b/x.py\n+x = 1\n context line\n' | run)"
expect "neutral diff fires nothing" "$neutral" "Gotcha checker: 0 of 2 rules triggered" 1
expect "empty-matching pattern reported broken" "$neutral" "matches-everything: BROKEN" 1

hit="$(printf '+++ b/x.sql\n+CREATE    TABLE t (a int);\n' | run)"
expect "matching diff fires the rule (POSIX class)" "$hit" "posix-create-table: fired" 1
expect "matching diff reports 1 of 2" "$hit" "Gotcha checker: 1 of 2 rules triggered" 1
expect "broken rule never fires" "$hit" "matches-everything: fired" 0

code=0; empty="$(printf '' | run)" || code=$?
expect "empty diff is a checker problem, not a pass" "$empty" "no diff on stdin" 1
expect "empty diff never reports a count" "$empty" "rules triggered" 0
if [[ "$code" == 2 ]]; then echo "PASS: empty diff exits 2"; else echo "FAIL: empty diff exited $code, want 2"; FAILED=1; fi

exit "$FAILED"
