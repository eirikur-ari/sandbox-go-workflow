#!/usr/bin/env bash
# Prints the entries of the Unreleased section of CHANGELOG.md, nothing when it has none, and fails when the changelog has no Unreleased section.
set -euo pipefail

# Prints the lines of the Unreleased section that are not blank lines, subsection headings or comments, and exits with status 3 when there is no Unreleased section
function unreleasedEntries() {
  awk '
    # True for a line that starts with: ## [
    function isVersionHeader(line)    { return line ~ /^## \[/ }

    # True for the line that starts the Unreleased section: ## [Unreleased]
    function isUnreleasedHeader(line) { return line ~ /^## \[Unreleased\]/ }

    # True for a link reference line from the footer of the changelog, for example:
    #   [0.3.0]: https://repourl/compare/v0.2.0...v0.3.0
    function isLinkReference(line)    { return line ~ /^\[[^]]+\]: / }

    # True for a line that holds no entry: blank, a subsection heading such as ### Added, or a comment
    function isNoEntry(line)          { return line !~ /[^[:space:]]/ || line ~ /^### / || line ~ /^<!--.*-->[[:space:]]*$/ }

    # A version header ends the section being read, and starts reading when it is the Unreleased header
    isVersionHeader($0) {
      if (inSection) exit
      inSection = isUnreleasedHeader($0)
      seen = seen || inSection
      next
    }

    # The link references of the footer come after the last section, so reading ends there
    inSection && isLinkReference($0) { exit }

    inSection && !isNoEntry($0) { print }

    END { if (!seen) exit 3 }
  ' CHANGELOG.md
}

# Prints the entries of the Unreleased section of the changelog
function main() {
  if ! unreleasedEntries; then
    echo "CHANGELOG.md has no Unreleased section" >&2
    exit 1
  fi
}

main
