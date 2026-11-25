#!/usr/bin/env bash
# Generates an HTML report from an existing coverage profile.
# It reads coverage.out and writes coverage.html in BUILD_DIR, which defaults as set in lib/config.sh and can be set in the environment.
set -euo pipefail

# shellcheck source-path=SCRIPTDIR source=../lib/config.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/config.sh"

# Writes the HTML report of the coverage profile
function writeReport() {
  go tool cover -html="$BUILD_DIR/coverage.out" -o "$BUILD_DIR/coverage.html"
}

# Writes the HTML coverage report from the workspace
function main() {
  cd "$WORKSPACE_FOLDER"
  writeReport
}

main
