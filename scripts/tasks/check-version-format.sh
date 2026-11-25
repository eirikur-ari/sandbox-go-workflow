#!/usr/bin/env bash
# Fails unless RELEASE_VERSION is MAJOR.MINOR.PATCH.
# Requires RELEASE_VERSION in the environment.
set -euo pipefail

# shellcheck source-path=SCRIPTDIR source=../lib/env.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/env.sh"

# Fails unless the release version is MAJOR.MINOR.PATCH
function verifyVersionFormat() {
  requireEnv RELEASE_VERSION
  if [[ ! "$RELEASE_VERSION" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; then
    echo "version '$RELEASE_VERSION' is not MAJOR.MINOR.PATCH"
    exit 1
  fi
}

# Checks the format of the release version
function main() {
  verifyVersionFormat
}

main
