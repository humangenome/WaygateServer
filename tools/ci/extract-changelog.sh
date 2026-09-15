#!/usr/bin/env bash
# Extracts one version's section out of CHANGELOG.md and emits it as a release
# body in the family standard shape.
#
# CHANGELOG.md nests a version under `## [x.y.z] - date`, so its components sit
# at `### Server` / `### Client` and its change types at `#### Added`. A release
# body has no version heading of its own, so every heading is promoted one
# level: `### Server` becomes `## Server`, `#### Added` becomes `### Added`.
# The hosting footer is appended here rather than stored in the changelog.
#
# A missing section is a hard failure. A sibling's CI published a placeholder
# body for five releases because its extractor failed soft.
#
# Usage:
#   tools/ci/extract-changelog.sh <version> [output-file]

set -euo pipefail

version=${1:-}
out=${2:-}

[[ -n ${version} ]] || { echo "usage: extract-changelog.sh <version> [output-file]" >&2; exit 2; }

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
changelog="${repo_root}/CHANGELOG.md"
[[ -f ${changelog} ]] || { echo "extract-changelog: missing ${changelog}" >&2; exit 1; }

HOSTING_URL="https://www.survivalservers.com/services/game_servers/dimraeth/?utm_source=github&utm_medium=release_notes&utm_campaign=waygate"

body=$(awk -v ver="${version}" '
    $0 ~ "^## \\[" ver "\\]" { capture = 1; next }
    capture && /^## / { exit }
    capture { print }
' "${changelog}")

# Drop markdown link-reference definitions ("[Unreleased]: https://...").
# They live at the bottom of CHANGELOG.md, get swept up by the section capture,
# and render as a stray bare line in a release body.
body=$(printf '%s\n' "${body}" | sed -E '/^\[[^]]+\]:[[:space:]]/d')

# Strip leading and trailing blank lines.
body=$(printf '%s\n' "${body}" | sed -e '/./,$!d' | tac | sed -e '/./,$!d' | tac)

if [[ -z ${body//[[:space:]]/} ]]; then
    echo "extract-changelog: CHANGELOG.md has no content under '## [${version}]'" >&2
    echo "extract-changelog: add the section before tagging — a release cannot publish an empty body" >&2
    exit 1
fi

# Promote headings one level: #### -> ###, ### -> ##.
body=$(printf '%s\n' "${body}" | sed -E 's/^#### /### /; s/^### (Server|Client)$/## \1/')

rendered=$(printf '%s\n\n---\n\nHosting: [SurvivalServers.com](%s) runs Waygate for you.\n' "${body}" "${HOSTING_URL}")

if [[ -n ${out} ]]; then
    printf '%s' "${rendered}" > "${out}"
    echo "extract-changelog: wrote ${out} (${version})"
else
    printf '%s' "${rendered}"
fi
