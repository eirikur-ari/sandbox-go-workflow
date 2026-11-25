#!/usr/bin/env bash
# Unpacks the binary from the release archive of the platform it runs on into BIN_DIR/<goos>_<goarch>/, for the acceptance tests.
# It replaces the binary that is there, and unpacks nothing else from the archive.
# WORKSPACE_FOLDER, BIN_DIR, BINARY_NAME and DIST_DIR default as set in lib/config.sh and can be set in the environment.
set -euo pipefail

# shellcheck source-path=SCRIPTDIR source=../lib/acceptance.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/acceptance.sh"

# Extracts the binary from the archive of this platform, from the workspace
function main() {
  cd "$WORKSPACE_FOLDER"
  extract
}

main
