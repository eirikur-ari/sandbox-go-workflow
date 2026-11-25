#!/usr/bin/env bash
# Packages the binary of every target with the license files, readme and changelog into one archive per target.
# For every platform in TARGETS, gathers its binary from BIN_DIR/<goos>_<goarch>/, the license files, readme, its images and changelog
# in PACKAGE_DIR and archives that into DIST_DIR. The archives are named for RELEASE_VERSION, or dev when that is not set.
# WORKSPACE_FOLDER, BIN_DIR, BINARY_NAME, PACKAGE_DIR and DIST_DIR default as set in lib/config.sh and can be set in the environment.
set -euo pipefail

# shellcheck source-path=SCRIPTDIR source=../lib/package.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/package.sh"

# Packages the binary and its accompanying files into an archive of the given version for every target
function packageAll() {
  local version="$1" target

  for target in "${TARGETS[@]}"; do
    packageTarget "$version" "$target"
  done
}

# Packages the release for every target
function main() {
  setup
  packageAll "${RELEASE_VERSION:-dev}"
}

main
