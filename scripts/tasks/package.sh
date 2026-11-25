#!/usr/bin/env bash
# Packages the binary of the host platform that build wrote with the license files, readme and changelog into one archive.
# It gathers the binary from BIN_DIR/<goos>_<goarch>/, the license files, readme and changelog in PACKAGE_DIR and archives that into DIST_DIR.
# The archive is named for RELEASE_VERSION, or dev when that is not set, and for the platform it runs on, like the archives of the package-all task.
# WORKSPACE_FOLDER, BIN_DIR, BINARY_NAME, PACKAGE_DIR and DIST_DIR default as set in lib/config.sh and can be set in the environment.
set -euo pipefail

# shellcheck source-path=SCRIPTDIR source=../lib/package.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/package.sh"

# Packages the binary of the platform the script runs on into an archive of the given version
function packageHost() {
  local version="$1" target

  target=$(hostTarget) || return
  packageTarget "$version" "$target"
}

# Packages the release for the host platform
function main() {
  setup
  packageHost "${RELEASE_VERSION:-dev}"
}

main
