#!/usr/bin/env bash
# Prints the release notes file that release-notes-file wrote, failing if it does not exist.
# BUILD_DIR defaults as set in lib/config.sh and can be set in the environment.
set -euo pipefail

# shellcheck source-path=SCRIPTDIR source=../lib/config.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/config.sh"

# Prints the release notes file
function printReleaseNotes() {
  cat "$BUILD_DIR/release-notes.md"
}

# Prints the release notes file from the workspace
function main() {
  cd "$WORKSPACE_FOLDER"
  printReleaseNotes
}

main
