#!/usr/bin/env bash
# Runs go vet on all packages, including the integration and acceptance tests.
set -euo pipefail

# Vets every package, including the ones behind the integration and acceptance build tags
function main() {
  go vet -tags "integration acceptance" ./...
}

main
