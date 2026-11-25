#!/usr/bin/env bash
# Fails when the Unreleased section of the changelog has entries, or when the changelog has no Unreleased section.
set -euo pipefail

# Succeeds when the Unreleased section of the changelog has entries, and exits when the changelog has no Unreleased section
function unreleasedHasEntries() {
  local entries

  entries=$(bash scripts/task.sh changelog-unreleased) || exit 1
  [[ -n "$entries" ]]
}

# Fails when the Unreleased section of the changelog has entries
function verifyChangelog() {
  if unreleasedHasEntries; then
    echo "the Unreleased section of the changelog has entries"
    exit 1
  fi
}

# Checks the Unreleased section of the changelog
function main() {
  verifyChangelog
}

main
