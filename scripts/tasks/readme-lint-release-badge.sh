#!/usr/bin/env bash
# Fails when the release badge of the readme shows none of the accepted release versions.
# It reads RELEASE_VERSION from the environment when it is set.
set -euo pipefail

# shellcheck source-path=SCRIPTDIR source=../lib/readme-lint.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/readme-lint.sh"

# Fails when the release badge of the readme shows none of the accepted release versions
function main() {
  releaseBadge
}

main
