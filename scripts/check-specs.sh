#!/usr/bin/env bash
# Every scenario in a spec names the test that proves it:
#   - **TEST** `src/labels.rs::some_test_fn`
# This checks that each named file exists and defines that test,
# in the living specs (openspec/specs/) and in open changes
# (openspec/changes/, not the archive). See .claude/skills/spec/.
#
# A test counts as defined when its name is followed by "(", which fits
# `fn name(`, `def name(`, `func name(`, `void name(` and the like.
# Set SPEC_TEST_PATTERN to an extended regex with %s for the name if
# your tests look different, e.g. 'it\("%s"' for Jest.
#
#   scripts/check-specs.sh               check this repo
#   scripts/check-specs.sh --self-test   check the checker
set -euo pipefail

pattern=${SPEC_TEST_PATTERN:-'(^|[^[:alnum:]_])%s[[:space:]]*\('}

check() {
    local root=$1 bad=0 spec ref file fn
    while IFS= read -r spec; do
        while IFS= read -r ref; do
            file=${ref%%::*}
            fn=${ref##*::}
            if [[ ! -f "$root/$file" ]]; then
                echo "${spec#"$root"/}: $ref: no such file"
                bad=1
            elif ! grep -Eq "${pattern//%s/$fn}" "$root/$file"; then
                echo "${spec#"$root"/}: $ref: no test '$fn' in that file"
                bad=1
            fi
        done < <(sed -nE 's/^- \*\*TEST\*\* `([^`]+)`.*/\1/p' "$spec")
    done < <(find "$root/openspec/specs" "$root/openspec/changes" \
                 -path "$root/openspec/changes/archive" -prune -o \
                 -name spec.md -print 2>/dev/null | sort)
    return $bad
}

self_test() {
    local t
    t=$(mktemp -d)
    trap 'rm -rf "$t"' RETURN
    mkdir -p "$t/src" "$t/openspec/specs/a" "$t/openspec/changes/c/specs/a" \
             "$t/openspec/changes/archive/old/specs/a"
    printf '#[test]\nfn real_test() {}\n' > "$t/src/lib.rs"
    printf 'def py_test():\n    pass\n' > "$t/src/test_a.py"
    printf -- '- **TEST** `src/lib.rs::real_test`\n- **TEST** `src/test_a.py::py_test`\n' > "$t/openspec/specs/a/spec.md"
    # The archive is history: a test renamed since must not fail the check.
    printf -- '- **TEST** `src/lib.rs::renamed_long_ago`\n' > "$t/openspec/changes/archive/old/specs/a/spec.md"
    check "$t" >/dev/null || { echo "self-test: a valid spec failed"; return 1; }

    printf -- '- **TEST** `src/lib.rs::real_test_2`\n' > "$t/openspec/changes/c/specs/a/spec.md"
    check "$t" >/dev/null && { echo "self-test: a missing fn in an open change passed"; return 1; }

    # A longer name that only ends in the named one is not that test.
    printf -- '- **TEST** `src/lib.rs::_test`\n' > "$t/openspec/changes/c/specs/a/spec.md"
    check "$t" >/dev/null && { echo "self-test: a name suffix passed"; return 1; }

    printf -- '- **TEST** `src/gone.rs::real_test`\n' > "$t/openspec/changes/c/specs/a/spec.md"
    check "$t" >/dev/null && { echo "self-test: a missing file passed"; return 1; }

    echo "self-test passed"
}

if [[ ${1:-} == --self-test ]]; then
    self_test
else
    check "$(cd "$(dirname "$0")/.." && pwd)" && echo "specs: every named test exists"
fi
