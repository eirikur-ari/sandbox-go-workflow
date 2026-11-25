#!/usr/bin/env bash
# Runs the acceptance tests against the built binary, failing if it does not exist.
# WORKSPACE_FOLDER, BIN_DIR and BINARY_NAME default as set in lib/config.sh and can be set in the environment.
# The binary is the one of the host platform in BIN_DIR/<goos>_<goarch>/, which build wrote or acceptance-extract unpacked.
# APP_BINARY is the binary the tests run against instead, when it is set.
set -euo pipefail

# shellcheck source-path=SCRIPTDIR source=../lib/acceptance.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/acceptance.sh"

# Runs the acceptance tests from the workspace
function main() {
  cd "$WORKSPACE_FOLDER"
  run
}

main
