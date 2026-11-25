#!/usr/bin/env bash
# Runs the unit and integration tests with the race detector.
set -euo pipefail

# Runs the tests of every package
function runTests() {
  echo "Running tests..."
  go test -v -tags integration -race -count=1 ./...
}

# Runs the tests
function main() {
  runTests
}

main
