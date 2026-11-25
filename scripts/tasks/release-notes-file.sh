#!/usr/bin/env bash
# Writes the release notes of RELEASE_VERSION from the changelog to release-notes.md in BUILD_DIR, failing if there are none.
# Requires RELEASE_VERSION in the environment. BUILD_DIR defaults as set in lib/config.sh and can be set in the environment.
set -euo pipefail

# shellcheck source-path=SCRIPTDIR source=../lib/config.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/config.sh"

# Writes the release notes to the file, and removes the file when there are none
function writeReleaseNotes() {
  mkdir -p "$BUILD_DIR"
  bash scripts/task.sh release-notes-content > "$BUILD_DIR/release-notes.md" || { rm -f -- "$BUILD_DIR/release-notes.md"; exit 1; }
}

# Writes the release notes file from the workspace
function main() {
  cd "$WORKSPACE_FOLDER"
  writeReleaseNotes
}

main
