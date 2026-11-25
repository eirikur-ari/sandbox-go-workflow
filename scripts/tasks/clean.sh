#!/usr/bin/env bash
# Removes the build artifacts, which are BIN_DIR and BUILD_DIR.
# WORKSPACE_FOLDER, BIN_DIR and BUILD_DIR default as set in lib/config.sh and can be set in the environment.
set -euo pipefail

# shellcheck source-path=SCRIPTDIR source=../lib/config.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/config.sh"

# Removes the directories of the build artifacts
function removeArtifacts() {
  echo "Running clean..."
  rm -rf -- "${BIN_DIR:?}" "${BUILD_DIR:?}"
}

# Removes the build artifacts from the workspace
function main() {
  cd "$WORKSPACE_FOLDER"
  removeArtifacts
}

main
