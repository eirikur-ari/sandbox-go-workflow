#!/usr/bin/env bash
# Writes the SHA-256 checksums of the release archives to checksums.txt in DIST_DIR.
# DIST_DIR defaults as set in lib/config.sh and can be set in the environment.
set -euo pipefail

# shellcheck source-path=SCRIPTDIR source=../lib/config.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/config.sh"

# Writes the checksums of the archives in DIST_DIR next to them
function writeChecksums() {
  (cd "$DIST_DIR" && shasum -a 256 -- *.tar.gz > checksums.txt)
}

# Writes the checksums from the workspace
function main() {
  cd "$WORKSPACE_FOLDER"
  writeChecksums
}

main
