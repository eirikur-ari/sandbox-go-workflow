#!/usr/bin/env bash
# Writes the licenses of the Go runtime and of the third-party modules compiled into the binary to PACKAGE_DIR/THIRD_PARTY_LICENSES.
# It writes nothing and succeeds when the binary has no third-party modules.
# WORKSPACE_FOLDER and PACKAGE_DIR default as set in lib/config.sh and can be set in the environment.
set -euo pipefail

# shellcheck source-path=SCRIPTDIR source=lib/config.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/config.sh"

# Moves to the workspace and creates the output directory
function setup() {
  cd "$WORKSPACE_FOLDER"
  mkdir -p "$PACKAGE_DIR"
}

# Saves the license files of the third-party modules compiled into the binary to the given directory, which is not created when there are none
function saveLicenses() {
  local licenses_dir="$1"

  go run github.com/google/go-licenses/v2@v2.0.1 save ./cmd --ignore github.com/eirikur-ari/sandbox-go-workflow --force --save_path="$licenses_dir"
}

# Succeeds when the given directory exists and holds at least one file
function hasLicenses() {
  local licenses_dir="$1"

  [[ -d "$licenses_dir" && -n "$(find "$licenses_dir" -type f -print -quit)" ]]
}

# Fails when the given directory holds files that are not licenses
function verifyLicenses() {
  local licenses_dir="$1" non_license_files

  non_license_files=$(cd "$licenses_dir" && find . -type f ! \( -name 'LICENSE*' -o -name 'NOTICE*' -o -name 'COPYING*' \))
  if [[ -n "$non_license_files" ]]; then
    echo "go-licenses saved files that are not licenses:"
    echo "$non_license_files"
    exit 1
  fi
}

# Prints a banner with the given title
function printHeader() {
  local title="$1"

  printf '================================================================\n%s\n================================================================\n\n' "$title"
}

# Writes the Go runtime license and the licenses in the given directory to PACKAGE_DIR/THIRD_PARTY_LICENSES
function writeLicenses() {
  local licenses_dir="$1" license_path

  {
    printHeader "Go standard library and runtime"
    cat "$(go env GOROOT)/LICENSE"
    printf '\n'

    # Sorting in the C locale orders by byte value, so the licenses come in the same order on every machine
    while IFS= read -r license_path; do
      printHeader "${license_path#./}"
      cat "$licenses_dir/$license_path"
      printf '\n'
    done < <(cd "$licenses_dir" && find . -type f | LC_ALL=C sort)
  } > "$PACKAGE_DIR/THIRD_PARTY_LICENSES"
}

# Verifies and writes the licenses in the given directory, or reports that there are none and writes nothing
function writeLicensesIfAny() {
  local licenses_dir="$1"

  if ! hasLicenses "$licenses_dir"; then
    echo "no third-party licenses found, nothing to write"
    return
  fi

  verifyLicenses "$licenses_dir"
  writeLicenses "$licenses_dir"
}

# Collects the licenses of the Go runtime and the compiled-in modules into one file
function main() {
  local licenses_dir

  setup

  licenses_dir="$(dirname "$PACKAGE_DIR")/licenses"

  saveLicenses "$licenses_dir"
  writeLicensesIfAny "$licenses_dir"
}

main
