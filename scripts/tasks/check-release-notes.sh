#!/usr/bin/env bash
# Fails when the changelog has no release notes for RELEASE_VERSION.
# Requires RELEASE_VERSION in the environment.
set -euo pipefail

# shellcheck source-path=SCRIPTDIR source=../lib/env.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/env.sh"

# Fails when the changelog has no release notes for the release version
function verifyReleaseNotes() {
  requireEnv RELEASE_VERSION
  bash scripts/task.sh release-notes-content > /dev/null
}

# Checks the release notes of the release version
function main() {
  verifyReleaseNotes
}

main
