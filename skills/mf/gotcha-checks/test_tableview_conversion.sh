#!/usr/bin/env bash
# Fixture-based test for tableview-conversion.sh.
# Runs the script against each *.diff under fixtures/ and diffs stdout
# against the matching *.expected file. Exits non-zero on any mismatch.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$DIR/tableview-conversion.sh"
FIXTURES="$DIR/fixtures"
FAILED=0

for diff_file in "$FIXTURES"/*.diff; do
    name="$(basename "$diff_file" .diff)"
    expected="$FIXTURES/$name.expected"
    actual="$(cd "$FIXTURES" && bash "$SCRIPT" < "$diff_file" 2>&1 || true)"
    expected_content="$(cat "$expected")"
    if [[ "$actual" != "$expected_content" ]]; then
        echo "FAIL: $name"
        echo "  expected: $expected_content"
        echo "  actual:   $actual"
        FAILED=1
    else
        echo "PASS: $name"
    fi
done

exit "$FAILED"
