#!/usr/bin/env bash
# Compiles the binary for every release platform into BIN_DIR/<goos>_<goarch>/, optionally stamped with a release version.
# The binary reports RELEASE_VERSION as its version when that is set in the environment.
# WORKSPACE_FOLDER, BIN_DIR and BINARY_NAME default as set in lib/config.sh and can be set in the environment.
set -euo pipefail

# shellcheck source-path=SCRIPTDIR source=../lib/build.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/build.sh"

# Builds the binary for every target from the workspace
function main() {
  cd "$WORKSPACE_FOLDER"
  buildAll
}

main
