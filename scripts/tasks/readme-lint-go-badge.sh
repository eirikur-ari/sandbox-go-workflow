#!/usr/bin/env bash
# Fails when the Go version badge of the readme does not match the go version in go.mod.
set -euo pipefail

# shellcheck source-path=SCRIPTDIR source=../lib/readme-lint.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/readme-lint.sh"

# Fails when the Go version badge of the readme does not match the go version in go.mod
function main() {
  goBadge
}

main
