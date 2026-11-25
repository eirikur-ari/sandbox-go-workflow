#!/usr/bin/env bash
# Checks that the source code is gofmt-formatted, without changing anything.
set -euo pipefail

# Prints the files that are not gofmt-formatted
function unformattedFiles() {
  gofmt -l .
}

# Fails when any file is not gofmt-formatted
function verifyFormatting() {
  local unformatted

  echo "Checking source formatting"
  unformatted=$(unformattedFiles)
  if [[ -n "$unformatted" ]]; then
    echo "The following files are not gofmt-formatted:"
    echo "$unformatted"
    exit 1
  fi
}

# Checks the formatting of the source code
function main() {
  verifyFormatting
}

main
