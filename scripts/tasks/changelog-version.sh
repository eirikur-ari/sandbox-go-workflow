#!/usr/bin/env bash
# Prints the version of the latest release in CHANGELOG.md, failing when it has none.
set -euo pipefail

# Prints the version of the first release in the changelog
function latestChangelogVersion() {
  sed -n '/^## \[[0-9]/{s/^## \[\([^]]*\)\].*/\1/p;q;}' CHANGELOG.md
}

# Prints the version of the latest release in the changelog
function main() {
  local version

  version=$(latestChangelogVersion)
  if [[ -z "$version" ]]; then
    echo "no release found in the changelog" >&2
    exit 1
  fi
  echo "$version"
}

main
