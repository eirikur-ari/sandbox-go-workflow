#!/usr/bin/env bash
# Runs the unit and integration tests with the race detector, then prints a function coverage report.
# It writes the coverage profile to coverage.out in BUILD_DIR, which defaults as set in lib/config.sh and can be set in the environment.
set -euo pipefail

# shellcheck source-path=SCRIPTDIR source=../lib/config.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/config.sh"

# Runs the tests with a coverage profile, then prints the coverage of every function
function runCoverage() {
  mkdir -p "$BUILD_DIR"
  go test -v -tags integration -race -count=1 -coverprofile="$BUILD_DIR/coverage.out" -covermode=atomic ./...
  go tool cover -func="$BUILD_DIR/coverage.out"
}

# Runs the tests with coverage from the workspace
function main() {
  cd "$WORKSPACE_FOLDER"
  runCoverage
}

main
