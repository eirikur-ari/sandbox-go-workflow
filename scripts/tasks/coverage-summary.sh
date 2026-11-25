#!/usr/bin/env bash
# Prints the total coverage percentage of an existing coverage profile.
# It reads coverage.out in BUILD_DIR, which defaults as set in lib/config.sh and can be set in the environment.
set -euo pipefail

# shellcheck source-path=SCRIPTDIR source=../lib/config.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/config.sh"

# Prints the total of the coverage report of the profile
function printTotal() {
  go tool cover -func="$BUILD_DIR/coverage.out" | awk '/^total:/ {print $3}'
}

# Prints the total coverage from the workspace
function main() {
  cd "$WORKSPACE_FOLDER"
  printTotal
}

main
