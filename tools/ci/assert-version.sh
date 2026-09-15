#!/usr/bin/env bash
# Asserts that Waygate's version is stated consistently everywhere.
#
# Ported from ValheimOne's tools/ci/assert-version.sh. The point of this gate:
# three sibling products have published a release whose tag disagreed with the
# version stamped in the build, so the shipped binary reported the wrong
# version on its own release page.
#
# Source of truth is <Version> in Directory.Build.props. This script fails if
# any csproj version property disagrees with it, and -- when a release tag is
# supplied -- if the tag or the CHANGELOG heading disagrees too.
#
# Until the server source carve-out lands, Directory.Build.props is absent and
# the CHANGELOG's newest released heading is used as the source of truth
# instead. That fallback is announced, never silent.
#
# Usage:
#   tools/ci/assert-version.sh              # internal consistency only
#   tools/ci/assert-version.sh --tag v1.2.3 # full release gate
#
# Prints `VERSION ASSERT PASS <version>` on success.

set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
props="${repo_root}/Directory.Build.props"
changelog="${repo_root}/CHANGELOG.md"

tag=""
while (( $# > 0 )); do
    case $1 in
        --tag)
            [[ $# -ge 2 ]] || { echo "assert-version: --tag needs a value" >&2; exit 2; }
            tag=$2
            shift 2
            ;;
        -h|--help)
            sed -n '2,22p' "${BASH_SOURCE[0]}"
            exit 0
            ;;
        *)
            echo "assert-version: unknown argument: $1" >&2
            exit 2
            ;;
    esac
done

failures=0
fail() {
    printf 'VERSION ASSERT FAIL: %s\n' "$*" >&2
    failures=$(( failures + 1 ))
}

# The private build repo symlinks CHANGELOG.md to the internal engineering log
# and gitignores it, so in that repo the file is either a symlink (locally) or
# absent entirely (on a CI checkout). Neither carries version headings and
# neither is ever published, so the changelog half of the gate is not
# applicable there -- but it IS mandatory wherever the changelog is the source
# of truth, which is the check below.
changelog_usable=0
if [[ -f ${changelog} && ! -L ${changelog} ]]; then
    changelog_usable=1
fi

read_property() {
    local file=$1 property=$2
    sed -nE "s:.*<${property}>([^<]+)</${property}>.*:\\1:p" "${file}"
}

# ------------ source of truth

if [[ -f ${props} ]]; then
    source_of_truth="Directory.Build.props"
    values=$(read_property "${props}" Version)
    count=$(printf '%s' "${values}" | grep -c . || true)
    if [[ ${count} -ne 1 ]]; then
        echo "assert-version: expected exactly one <Version> in ${props}, found ${count}" >&2
        exit 1
    fi
    version=${values}
elif [[ ${changelog_usable} -eq 0 ]]; then
    echo "assert-version: no Directory.Build.props, and CHANGELOG.md is absent or is the internal log — nothing to assert against" >&2
    exit 1
else
    source_of_truth="CHANGELOG.md (Directory.Build.props not present yet)"
    version=$(sed -nE 's/^## \[([0-9]+\.[0-9]+\.[0-9]+)\].*/\1/p' "${changelog}" | head -1)
    if [[ -z ${version} ]]; then
        if [[ -n ${tag} ]]; then
            echo "assert-version: no released '## [x.y.z]' heading in CHANGELOG.md and no Directory.Build.props — cannot gate tag ${tag}" >&2
            exit 1
        fi
        printf 'VERSION ASSERT SKIP: no released version yet (source: %s)\n' "${source_of_truth}"
        exit 0
    fi
fi

if [[ ! ${version} =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "assert-version: version '${version}' is not MAJOR.MINOR.PATCH (source: ${source_of_truth})" >&2
    exit 1
fi

# ------------ every csproj must agree

while IFS= read -r -d '' csproj; do
    for property in Version AssemblyVersion FileVersion; do
        values=$(read_property "${csproj}" "${property}")
        [[ -n ${values} ]] || continue
        count=$(printf '%s' "${values}" | grep -c . || true)
        if [[ ${count} -ne 1 ]]; then
            fail "expected at most one <${property}> in ${csproj#"${repo_root}/"}, found ${count}"
            continue
        fi
        # 4-part assembly identities are accepted for the non-package properties.
        if [[ ${property} == Version ]]; then
            [[ ${values} == "${version}" ]] ||
                fail "<Version> in ${csproj#"${repo_root}/"} is ${values}, expected ${version}"
        else
            [[ ${values} == "${version}" || ${values} == "${version}.0" ]] ||
                fail "<${property}> in ${csproj#"${repo_root}/"} is ${values}, expected ${version} or ${version}.0"
        fi
    done
done < <(find "${repo_root}/src" -name '*.csproj' -print0 2>/dev/null || true)

# ------------ release gate

if [[ -n ${tag} ]]; then
    if [[ ${tag} != v* ]]; then
        fail "tag '${tag}' does not start with 'v'"
    elif [[ ${tag#v} != "${version}" ]]; then
        fail "tag '${tag}' does not match version ${version} (expected v${version})"
    fi

    if [[ ${changelog_usable} -eq 0 ]]; then
        echo "assert-version: no publishable CHANGELOG.md here — skipping the heading check (the public one lives in WaygateServer)" >&2
    elif ! grep -qE "^## \[${version//./\\.}\] - " "${changelog}"; then
        fail "CHANGELOG.md has no '## [${version}] - <date>' heading"
    fi
fi

if (( failures )); then
    printf 'VERSION ASSERT FAILED with %s problem(s).\n' "${failures}" >&2
    exit 1
fi

if [[ -n ${tag} ]]; then
    printf 'VERSION ASSERT PASS %s (tag %s, source %s)\n' "${version}" "${tag}" "${source_of_truth}"
else
    printf 'VERSION ASSERT PASS %s (source %s)\n' "${version}" "${source_of_truth}"
fi
