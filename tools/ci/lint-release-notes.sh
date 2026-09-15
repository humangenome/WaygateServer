#!/usr/bin/env bash
# Validates a release body against the family release-body standard.
#
# Roughly ninety published release pages across the sibling products ignore the
# standard, which is why this is a build gate and not a checklist: the next one
# cannot be published wrong.
#
# Usage:
#   tools/ci/lint-release-notes.sh <body-file> <version>
#
# Prints `RELEASE NOTES LINT PASS` on success, and every violation on failure.

set -euo pipefail

body_file=${1:-}
version=${2:-}

if [[ -z ${body_file} || -z ${version} ]]; then
    echo "usage: lint-release-notes.sh <body-file> <version>" >&2
    exit 2
fi
[[ -f ${body_file} ]] || { echo "lint-release-notes: missing ${body_file}" >&2; exit 1; }

PRODUCT="Waygate"
SLUG="dimraeth"

failures=0
fail() {
    printf 'RELEASE NOTES LINT FAIL: %s\n' "$*" >&2
    failures=$(( failures + 1 ))
}

body=$(cat "${body_file}")
esc_version=${version//./\\.}

# ------------ body must say something

if [[ -z ${body//[[:space:]]/} ]]; then
    fail "body is empty"
fi
if [[ $(printf '%s' "${body}" | tr -d '[:space:]') == "SeeCHANGELOG.mdfordetails." ]]; then
    fail "body is the 'See CHANGELOG.md for details.' placeholder — a sibling published that as five whole releases"
fi

# ------------ no repeated version header (GitHub renders it above the body)

if grep -qE "^#{1,3}[[:space:]]*\[?v?${esc_version}\]?\b" "${body_file}"; then
    fail "body repeats the version in a heading — GitHub already shows it above the body"
fi
if grep -qiE "^#{1,3}[[:space:]]*${PRODUCT}[[:space:]]+v?${esc_version}\b" "${body_file}"; then
    fail "body repeats '${PRODUCT} ${version}' in a heading"
fi

# ------------ component grouping

while IFS= read -r heading; do
    case ${heading} in
        "## Server"|"## Client") ;;
        *) fail "top-level heading must be '## Server' or '## Client', found: ${heading}" ;;
    esac
done < <(grep -E '^## ' "${body_file}" || true)

# ------------ change-type grouping, in order

order=""
while IFS= read -r heading; do
    case ${heading} in
        "### Added")   order+="1" ;;
        "### Changed") order+="2" ;;
        "### Fixed")   order+="3" ;;
        "### Removed") order+="4" ;;
        *) fail "second-level heading must be one of '### Added', '### Changed', '### Fixed', '### Removed', found: ${heading}" ;;
    esac
done < <(grep -E '^### ' "${body_file}" || true)

# Each component block restarts the sequence, so check ordering per block.
python3 - "${body_file}" <<'PY' || failures=$(( failures + 1 ))
import re, sys
rank = {"Added": 1, "Changed": 2, "Fixed": 3, "Removed": 4}
block, ok = [], True
def check(block):
    global ok
    seen = [rank[b] for b in block if b in rank]
    if seen != sorted(seen):
        print("RELEASE NOTES LINT FAIL: change-type headings out of order "
              "(Added, Changed, Fixed, Removed) in one component block", file=sys.stderr)
        ok = False
for line in open(sys.argv[1], encoding="utf-8"):
    if re.match(r'^## ', line):
        check(block); block = []
    m = re.match(r'^### (\w+)', line)
    if m:
        block.append(m.group(1))
check(block)
sys.exit(0 if ok else 1)
PY

# ------------ bullets

while IFS= read -r line; do
    [[ ${line} == '- **Breaking:**'* ]] && continue
    fail "bullet starts with a bold lead-in (only '**Breaking:**' is allowed): ${line}"
done < <(grep -E '^- \*\*' "${body_file}" || true)

# ------------ stray link-reference definitions

while IFS= read -r line; do
    fail "body carries a markdown link-reference definition, which renders as a bare line: ${line}"
done < <(grep -E '^\[[^]]+\]:[[:space:]]' "${body_file}" || true)

# ------------ hosting footer

expected_re="^Hosting: \[SurvivalServers\.com\]\(https://www\.survivalservers\.com/services/game_servers/${SLUG}/\?[^)]*utm_[^)]*\) runs ${PRODUCT} for you\.$"
footer_line=$(printf '%s\n' "${body}" | awk 'NF {l=$0} END {print l}')
# `|| true` is load-bearing: under `set -e -o pipefail` a grep that matches
# nothing kills the whole script, and a body with no rule is exactly the case
# this check exists to report.
rule_line=$(printf '%s\n' "${body}" | { grep -n '^---$' || true; } | tail -1 | cut -d: -f1)

if [[ ! ${footer_line} =~ ${expected_re} ]]; then
    fail "last line must be the hosting footer: Hosting: [SurvivalServers.com](https://www.survivalservers.com/services/game_servers/${SLUG}/?utm_...) runs ${PRODUCT} for you."
elif [[ -z ${rule_line} ]]; then
    fail "hosting footer must be preceded by a '---' rule"
fi

# ------------ hosting URL must actually resolve

hosting_url=$(printf '%s\n' "${footer_line}" | sed -nE 's/.*\((https:[^)]+)\).*/\1/p')
if [[ -n ${hosting_url} ]]; then
    # A browser User-Agent, because the site sits behind a bot filter that
    # answers a bare curl from a datacenter IP with 403.
    code=$(curl -s -o /dev/null -w '%{http_code}' -L --max-time 25 \
        -A 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36' \
        "${hosting_url}" || echo 000)
    # Fail on 404 and only 404. That is the entire class this rule exists to
    # catch -- the dead /games/<slug>/ path and a mistyped slug both 404, and
    # both reached ~90 published release pages across the siblings.
    #
    # Anything else non-200 means the host answered but would not serve US: a
    # bot challenge, a rate limit, a blip. GitHub's runners get 403 from that
    # filter even with the User-Agent above, so failing on it would block every
    # release from CI over a page that is perfectly fine. This gate was written
    # today and its first act was to fail the release it was written for.
    if [[ ${code} == 404 ]]; then
        fail "hosting URL 404s: ${hosting_url} (the '/games/<slug>/' path and a wrong slug both 404 — check both)"
    elif [[ ${code} != 200 ]]; then
        echo "lint-release-notes: hosting URL returned HTTP ${code} (not 404, so the page exists; likely a bot filter). Not failing." >&2
    fi
fi

# ------------ managed-hosting language does not belong in an OSS release body

while IFS= read -r phrase; do
    if grep -qiF -- "${phrase}" "${body_file}"; then
        fail "body contains managed-hosting language: '${phrase}'"
    fi
done <<'EOF'
ships updates the night they release
full control panel
scheduled restarts
Servers pick this up on their next restart
EOF

# ------------ superlatives

while IFS= read -r word; do
    if grep -qiF -- "${word}" "${body_file}"; then
        fail "body contains a banned superlative: '${word}'"
    fi
done <<'EOF'
game-changing
revolutionary
banger
blazing
the big one
way better
EOF

# ------------ shapes that never belong in a release body
#
# These are described by shape rather than by name on purpose. This script is
# byte-identical in the public repos, and a guard that spells out the private
# token list would publish the very thing it exists to keep private.

while IFS= read -r pattern; do
    [[ -z ${pattern} ]] && continue
    if grep -qiE -- "${pattern}" "${body_file}"; then
        fail "body contains a banned reference matching /${pattern}/"
    fi
done <<'EOF'
survivalservers\.com/games/
[A-Za-z]:\\
[0-9]{1,3}(\.[0-9]{1,3}){3}:[0-9]{2,5}
#[0-9]{6}
Co-Authored-By
Generated with
0x[0-9a-fA-F]{6,}
/home/[a-z]
/Users/[a-z]
EOF

# The named-token half lives in an optional file that exists ONLY in the
# private build repo. When it is absent (i.e. in a public checkout) the shape
# rules above still run, and the private repo is where a release is cut anyway.
tokens_file="${repo_root:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)}/tools/ci/private-tokens.txt"
if [[ -f ${tokens_file} ]]; then
    while IFS= read -r pattern; do
        [[ -z ${pattern} || ${pattern} == \#* ]] && continue
        if grep -qiE -- "${pattern}" "${body_file}"; then
            fail "body contains a private reference (matched a pattern in tools/ci/private-tokens.txt)"
        fi
    done < "${tokens_file}"
else
    echo "lint-release-notes: tools/ci/private-tokens.txt not present — running shape rules only" >&2
fi

if (( failures )); then
    printf 'RELEASE NOTES LINT FAILED with %s problem(s).\n' "${failures}" >&2
    exit 1
fi

printf 'RELEASE NOTES LINT PASS (%s %s)\n' "${PRODUCT}" "${version}"
